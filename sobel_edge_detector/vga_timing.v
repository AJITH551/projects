module vga_timing (
        input  wire        pixel_clk,
        input  wire        rst_n,
        
        output reg  [16:0] bram_addr,
        output reg         hsync,
        output reg         vsync,
        output reg  [9:0]  pixel_x,
        output reg  [9:0]  pixel_y,
        output reg         video_active
    );
    
        // Standard 640x480 @ 60Hz timing constants
        localparam H_ACTIVE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48, H_TOTAL = 800;
        localparam V_ACTIVE = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33, V_TOTAL = 525;
    
        reg [9:0] h_cnt = 0;
        reg [9:0] v_cnt = 0;
    
        // Counters
        always @(posedge pixel_clk or negedge rst_n) begin
            if (!rst_n) begin
                h_cnt <= 0;
                v_cnt <= 0;
            end else begin
                if (h_cnt == H_TOTAL - 1) begin
                    h_cnt <= 0;
                    if (v_cnt == V_TOTAL - 1)
                        v_cnt <= 0;
                    else
                        v_cnt <= v_cnt + 1;
                end else begin
                    h_cnt <= h_cnt + 1;
                end
            end
        end
    
        // Pixel doubling (320x240 -> 640x480)
        wire [8:0] img_x = h_cnt[9:1]; // h_cnt / 2 (0..319)
        wire [7:0] img_y = v_cnt[9:1]; // v_cnt / 2 (0..239)
        wire active = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    
        // Pipeline delay to match BRAM 1-cycle read latency
        reg active_d, hsync_d, vsync_d;
        reg [9:0] x_d, y_d;
        always @(posedge pixel_clk) begin
            if (active)
                bram_addr <= (img_y * 320) + img_x;
            else
                bram_addr <= 17'd0;
    
            x_d <= h_cnt;
            y_d <= v_cnt;
            pixel_x <= x_d;
            pixel_y <= y_d;
            active_d     <= active;
            hsync_d      <= (h_cnt >= (H_ACTIVE + H_FP)) && (h_cnt < (H_ACTIVE + H_FP + H_SYNC));
            vsync_d      <= (v_cnt >= (V_ACTIVE + V_FP)) && (v_cnt < (V_ACTIVE + V_FP + V_SYNC));
            
            // [STUDENT BUG]: Bypassing active_d pipeline delay register!
            // Breaks alignment with BRAM 1-cycle read latency (doutb arrives 1 cycle after bram_addr).
            video_active <= active_d;
            hsync        <= hsync_d;
            vsync        <= vsync_d;
        end
    endmodule
