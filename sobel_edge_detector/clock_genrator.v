`timescale 1ns / 1ps

module clk_gen (
    input  wire clk_in,
    input  wire reset,

    output wire pixel_clk,
    output wire pixel_clk_x5,
    output wire cam_xclk,
    output wire locked
);

    wire clk_in_buf;
    wire clk_fb;
    wire clk_fb_buf;

    wire clk_25;
    wire clk_125;
    wire clk_24;

    // Input clock buffer
    IBUF u_ibuf (
        .I(clk_in),
        .O(clk_in_buf)
    );

    // MMCM clock generation
    MMCME2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(20.0),

        // VCO = 50 MHz * 10 = 500 MHz
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.0),

        // 500 / 20 = 25 MHz
        .CLKOUT0_DIVIDE_F(20.0),

        // 500 / 4 = 125 MHz
        .CLKOUT1_DIVIDE(4),

        // 500 / 20.8333 = 24 MHz
        .CLKOUT2_DIVIDE_F(20.8333)
    )
    u_mmcm (
        .CLKIN1(clk_in_buf),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),

        .CLKFBIN(clk_fb_buf),
        .CLKFBOUT(clk_fb),

        .CLKOUT0(clk_25),
        .CLKOUT1(clk_125),
        .CLKOUT2(clk_24),

        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),

        .DADDR(7'b0),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI(16'b0),
        .DWE(1'b0),

        .PWRDWN(1'b0),
        .RST(reset),

        .PSCLK(1'b0),
        .PSEN(1'b0),
        .PSINCDEC(1'b0),
        .PSDONE(),

        .LOCKED(locked)
    );

    // Feedback buffer
    BUFG u_bufg_fb (
        .I(clk_fb),
        .O(clk_fb_buf)
    );

    // Output clock buffers
    BUFG u_bufg_pixel (
        .I(clk_25),
        .O(pixel_clk)
    );

    BUFG u_bufg_serial (
        .I(clk_125),
        .O(pixel_clk_x5)
    );

    BUFG u_bufg_camera (
        .I(clk_24),
        .O(cam_xclk)
    );

endmodule
