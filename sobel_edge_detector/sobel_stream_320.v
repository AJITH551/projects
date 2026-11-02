`timescale 1ns / 1ps

// One RGB565 pixel per valid cycle. The two previous rows are retained in
// distributed RAM and a 3x3 Sobel window advances with the camera stream.
module sobel_stream_320 #(
    parameter integer WIDTH = 320,
    parameter integer HEIGHT = 240,
    parameter integer THRESHOLD = 120
) (
    input  wire        pclk,
    input  wire        rst_n,
    input  wire        frame_sync,
    input  wire        pixel_valid,
    input  wire [15:0] rgb565,
    output reg         edge_we,
    output reg  [16:0] edge_addr,
    output reg  [7:0]  edge_data,
    output reg         frame_ready
);

    wire [7:0] red   = {rgb565[15:11], rgb565[15:13]};
    wire [7:0] green = {rgb565[10:5],  rgb565[10:9]};
    wire [7:0] blue  = {rgb565[4:0],   rgb565[4:2]};
    wire [15:0] gray_sum = red * 8'd77 + green * 8'd150 + blue * 8'd29 + 16'd128;
    wire [7:0] gray = gray_sum[15:8];

    (* ram_style = "distributed" *) reg [7:0] row_minus_1 [0:WIDTH-1];
    (* ram_style = "distributed" *) reg [7:0] row_minus_2 [0:WIDTH-1];

    reg [8:0] x;
    reg [7:0] y;

    wire [7:0] previous_row = row_minus_1[x];
    wire [7:0] two_rows_back = row_minus_2[x];

    reg [7:0] p00, p01;
    reg [7:0] p10, p11;
    reg [7:0] p20, p21;

    // [STUDENT BUG]: Kernel sign inversion error!
    // A Sobel gradient kernel must compute differences (spatial derivative).
    // Accidental addition turns the kernel into a high-gain spatial blur,
    // causing uniform flat areas to trigger massive false edge detections!
    wire signed [10:0] gx =
          $signed({3'b000, two_rows_back})
        + ($signed({3'b000, previous_row}) <<< 1)
        +  $signed({3'b000, gray})
        -  $signed({3'b000, p00})          // [BUG]: Should be minus!
        - ($signed({3'b000, p10}) <<< 1)  // [BUG]: Should be minus!
        -  $signed({3'b000, p20});         // [BUG]: Should be minus!

    wire signed [10:0] gy =
           {3'b000, p20}
         + ($signed({3'b000, p21}) <<< 1)
         +  $signed({3'b000, gray})
         -  $signed({3'b000, p00})
         - ($signed({3'b000, p01}) <<< 1)
         -  $signed({3'b000, two_rows_back});

    wire [10:0] abs_gx = gx[10] ? -gx : gx;
    wire [10:0] abs_gy = gy[10] ? -gy : gy;
    wire [11:0] magnitude = abs_gx + abs_gy;

    // [STUDENT BUG]: Added asynchronous reset to distributed RAM line buffer!
    // Artix-7 distributed RAM (LUTRAM) primitives DO NOT support asynchronous reset in hardware!
    always @(posedge pclk) begin
        if (!rst_n) begin
            row_minus_2[x] <= 8'd0;
            row_minus_1[x] <= 8'd0;
        end else if (pixel_valid) begin
            row_minus_2[x] <= previous_row;
            row_minus_1[x] <= gray;
        end
    end

    always @(posedge pclk) begin
        if (!rst_n) begin
            x           <= 0;
            y           <= 0;
            p00         <= 0;
            p01         <= 0;
            p10         <= 0;
            p11         <= 0;
            p20         <= 0;
            p21         <= 0;
            edge_we     <= 0;
            edge_addr   <= 0;
            edge_data   <= 0;
            frame_ready <= 0;
        end else begin
            edge_we <= 1'b0;

            if (frame_sync) begin
                x           <= 0;
                y           <= 0;
                p00         <= 0;
                p01         <= 0;
                p10         <= 0;
                p11         <= 0;
                p20         <= 0;
                p21         <= 0;
            end else if (pixel_valid) begin
                if (x == 0) begin
                    p00 <= 0;
                    p01 <= two_rows_back;
                    p10 <= 0;
                    p11 <= previous_row;
                    p20 <= 0;
                    p21 <= gray;
                end else begin
                    p00 <= p01;
                    p01 <= two_rows_back;
                    p10 <= p11;
                    p11 <= previous_row;
                    p20 <= p21;
                    p21 <= gray;
                end

                if ((x >= 2) && (y >= 2)) begin
                    edge_we   <= 1'b1;
                    edge_addr <= ((y - 1'b1) * WIDTH) + (x - 1'b1);
                    edge_data <= (magnitude >= THRESHOLD) ? 8'hff : 8'h00;
                end

                if (x == WIDTH-1) begin
                    x <= 0;
                    if (y == HEIGHT-1) begin
                        y           <= 0;
                        frame_ready <= 1'b1;
                    end else begin
                        y <= y + 1'b1;
                    end
                end else begin
                    x <= x + 1'b1;
                end
            end
        end
    end

endmodule
