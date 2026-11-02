`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2026 08:30:19 PM
// Design Name: 
// Module Name: ov5640_capture
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


 module ov5640_capture (
        input  wire        pclk,
        input  wire        rst_n,
        input  wire        cam_vsync,
        input  wire        cam_href,
        input  wire [7:0]  cam_data,
        
        output reg         bram_we,
        output reg  [16:0] bram_addr,
        output reg  [15:0] bram_din
    );
    
        reg [16:0] next_addr;
        reg byte_phase;
        reg [7:0] high_byte;
    
        always @(posedge pclk or negedge rst_n) begin
            if (!rst_n) begin
                next_addr  <= 17'd0;
                byte_phase <= 1'b0;
                bram_we    <= 1'b0;
                bram_addr  <= 17'd0;
                bram_din   <= 16'd0;
            end else begin
                bram_we <= 1'b0;
    
                // VSYNC holds capture reset; next_addr tags the CURRENT pixel.
                if (cam_vsync) begin
                    next_addr  <= 17'd0;
                    bram_addr  <= 17'd0;
		    byte_phase<=1'b0;
                    // [STUDENT BUG]: byte_phase <= 1'b0; omitted on frame boundary!
                    // If an odd byte occurs from noise, phase is inverted indefinitely.
                end 
                else if (cam_href && next_addr < 17'd76800) begin
                    if (!byte_phase) begin
                        high_byte  <= cam_data;
                        byte_phase <= 1'b1;
                    end else begin
                        // [STUDENT BUG]: Swapped byte packing order (LSB first instead of MSB first)!
                        // Corrupts RGB565 format (Red and Blue channels swapped, Green bits split).
                        bram_din   <= {high_byte,cam_data};
                        bram_we    <= 1'b1;
                        byte_phase <= 1'b0;
                        bram_addr <= next_addr;
                        next_addr <= next_addr + 1'b1;
                    end
                end else begin
                    byte_phase <= 1'b0;
                end
            end
        end
    endmodule
