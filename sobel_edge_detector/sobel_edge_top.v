`timescale 1ns / 1ps

// Standalone OV5640-to-HDMI Sobel edge-detection top level for the
// EDGE Artix-7 XC7A100T board.
module sobel_edge_top (
    input  wire        sys_clk,
    input  wire        rst_btn,

    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_data,
    output wire        cam_xclk,
    output wire        cam_scl,
    inout  wire        cam_sda,
    output wire        cam_rst_n,
    output wire        cam_pwdn,

    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire [2:0]  hdmi_tx_p,
    output wire [2:0]  hdmi_tx_n,

    output wire [2:0]  led
);

    wire locked;

    // =========================================================================
    // STUDENT DESIGN TASK: Clock Generation & Architecture Design
    // =========================================================================
    // The EDGE Artix-7 100T development board supplies a single 50 MHz reference
    // clock on sys_clk (pin N11).
    //
    // YOU MUST:
    // 1. Analyze the system requirements across all subsystems (camera sensor,
    //    video raster timing, frame buffer BRAM, and high-speed HDMI PHY).
    // 2. Determine how many clocks are required and calculate their exact frequencies.
    // 3. Design the `clk_gen` module using MMCME2_ADV to synthesize those clocks.
    // 4. Declare your synthesized clock wires below and connect them to u_clk_gen
    //    and the respective subsystems.
    // =========================================================================

    // [STUDENT TODO]: Declare your synthesized clock nets here and connect to u_clk_gen
    wire clk_display;
    wire clk_serial;
    wire cam_xclk_gen;

    clk_gen u_clk_gen (
        .clk_in   (sys_clk),
        .reset    (1'b0),
	 .pixel_clk    (clk_display),
        .pixel_clk_x5 (clk_serial),
        .cam_xclk     (cam_xclk_gen),
        .locked   (locked)
        // [STUDENT TODO]: Connect the clock outputs from your clk_gen module here
    );

    // Camera sensor master clock output
    assign cam_xclk = cam_xclk_gen;

    // SW19 is an active-high reset. Hold the design in reset until the MMCM
    // is locked and the generated clocks have been stable for 65,536 cycles.
    reg [15:0] reset_counter = 0;
    reg sys_rst_n = 0;
    always @(posedge clk_display or negedge locked) begin
        if (!locked) begin
            reset_counter <= 0;
            sys_rst_n <= 0;
        end else if (rst_btn) begin
            reset_counter <= 0;
            sys_rst_n <= 0;
        end else if (reset_counter != 16'hffff) begin
            reset_counter <= reset_counter + 1'b1;
            sys_rst_n <= 0;
        end else begin
            sys_rst_n <= 1;
        end
    end

    assign cam_rst_n = sys_rst_n;
    assign cam_pwdn  = 1'b0;

    wire cam_init_done;
    ov5640_init u_cam_init (
        .clk   (clk_display),
        .rst_n (sys_rst_n),
        .scl   (cam_scl),
        .sda   (cam_sda),
        .done  (cam_init_done)
    );

    // [STUDENT BUG]: Bypassed reset synchronizer across clock domains!
    // sys_rst_n is in the display clock domain and can release asynchronously to cam_pclk!
    
    
    reg [1:0] cam_reset_sync = 0;
    wire cam_logic_rst_n = cam_reset_sync[1];
    always @(posedge cam_pclk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cam_reset_sync <= 0;
        else
            cam_reset_sync <= {cam_reset_sync[0], 1'b1};
    end
    
    

    wire        camera_pixel_valid;
    wire [16:0] camera_pixel_addr;
    wire [15:0] camera_pixel_rgb565;
    ov5640_capture u_capture (
        .pclk      (cam_pclk),
        .rst_n     (cam_logic_rst_n),
        .cam_vsync (cam_vsync),
        .cam_href  (cam_href),
        .cam_data  (cam_data),
        .bram_we   (camera_pixel_valid),
        .bram_addr (camera_pixel_addr),
        .bram_din  (camera_pixel_rgb565)
    );

    wire        edge_we;
    wire [16:0] edge_wr_addr;
    wire [7:0]  edge_wr_data;
    wire        edge_frame_ready_cam;
    sobel_stream_320 #(.THRESHOLD(120)) u_sobel (
        .pclk        (cam_pclk),        // [STUDENT BUG]: CDC Violation! Input data is in cam_pclk domain!
        .rst_n       (cam_logic_rst_n),
        .frame_sync  (cam_vsync),
        .pixel_valid (camera_pixel_valid),
        .rgb565      (camera_pixel_rgb565),
        .edge_we     (edge_we),
        .edge_addr   (edge_wr_addr),
        .edge_data   (edge_wr_data),
        .frame_ready (edge_frame_ready_cam)
    );

    wire [16:0] display_addr;
    wire [7:0] edge_rd_data;
    dual_port_bram #(.DATA_WIDTH(8)) u_edge_ram (
        .clka  (cam_pclk),
        .wea   (edge_we),
        .addra (edge_wr_addr),
        .dina  (edge_wr_data),
        .clkb  (clk_display),
        .addrb (display_addr),
        .doutb (edge_rd_data)
    );

    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] display_x;
    wire [9:0] display_y;
    vga_timing u_video_timing (
        .pixel_clk    (clk_display),
        .rst_n        (sys_rst_n),
        .bram_addr    (display_addr),
        .hsync        (hsync),
        .vsync        (vsync),
        .video_active (video_active),
        .pixel_x      (display_x),
        .pixel_y      (display_y)
    );

    // Synchronize the sticky completed-frame flag into the display domain.
    reg [1:0] frame_ready_sync = 0;
    always @(posedge clk_display) begin
        if (!sys_rst_n)
            frame_ready_sync <= 0;
        else
            frame_ready_sync <= {frame_ready_sync[0], edge_frame_ready_cam};
    end
    wire show_edges = frame_ready_sync[1];

    // HDMI test bars remain visible until a complete Sobel frame exists.
    // This makes camera failures distinguishable from HDMI failures.
    wire [7:0] bar_r = (display_x < 80 || (display_x >= 320 && display_x < 480)) ? 8'hff : 8'h00;
    wire [7:0] bar_g = (display_x < 240 || (display_x >= 320 && display_x < 400)) ? 8'hff : 8'h00;
    wire [7:0] bar_b = (display_x < 80 || (display_x >= 160 && display_x < 320)) ? 8'hff : 8'h00;

    wire [7:0] video_r = show_edges ? edge_rd_data : bar_r;
    wire [7:0] video_g = show_edges ? edge_rd_data : bar_g;
    wire [7:0] video_b = show_edges ? edge_rd_data : bar_b;

    // Encode and serialize RGB video onto the four TMDS differential pairs.
    hdmi_tx u_hdmi (
        .pixel_clk    (clk_display),
        .pixel_clk_x5 (clk_serial),
        .rst_n        (sys_rst_n),
        .red          (video_r),
        .green        (video_g),
        .blue         (video_b),
        .hsync        (hsync),
        .vsync        (vsync),
        .active       (video_active),
        .tmds_clk_p   (hdmi_clk_p),
        .tmds_clk_n   (hdmi_clk_n),
        .tmds_data_p  (hdmi_tx_p),
        .tmds_data_n  (hdmi_tx_n)
    );

    assign led[0] = cam_init_done;
    assign led[1] = show_edges;
    assign led[2] = locked;

endmodule
