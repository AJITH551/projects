
`timescale 1ns / 1ps

module IBUF (
    input wire I,
    output wire O
);
    assign O = I;
endmodule


module BUFG (
    input wire I,
    output wire O
);
    assign O = I;
endmodule


module MMCME2_ADV #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter real CLKIN1_PERIOD = 20.0,
    parameter integer DIVCLK_DIVIDE = 1,
    parameter real CLKFBOUT_MULT_F = 10.0,
    parameter real CLKOUT0_DIVIDE_F = 20.0,
    parameter integer CLKOUT1_DIVIDE = 4,
    parameter real CLKOUT2_DIVIDE_F = 20.833333
)(
    input wire CLKIN1,
    input wire CLKIN2,
    input wire CLKINSEL,
    input wire CLKFBIN,
    output wire CLKFBOUT,
    output wire CLKOUT0,
    output wire CLKOUT1,
    output wire CLKOUT2,
    output wire CLKOUT3,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire CLKOUT6,
    input wire [6:0] DADDR,
    input wire DCLK,
    input wire DEN,
    input wire [15:0] DI,
    input wire DWE,
    input wire PWRDWN,
    input wire RST,
    input wire PSCLK,
    input wire PSEN,
    input wire PSINCDEC,
    output wire PSDONE,
    output reg LOCKED
);

    reg clk0 = 0;
    reg clk1 = 0;
    reg clk2 = 0;
    reg fb = 0;

    assign CLKFBOUT = fb;
    assign CLKOUT0 = clk0;
    assign CLKOUT1 = clk1;
    assign CLKOUT2 = clk2;

    assign CLKOUT3 = 1'b0;
    assign CLKOUT4 = 1'b0;
    assign CLKOUT5 = 1'b0;
    assign CLKOUT6 = 1'b0;
    assign PSDONE = 1'b0;

    // Simulation clocks for 50 MHz input
    always #20 clk0 = ~clk0;
    always #4  clk1 = ~clk1;
    always #20.833333 clk2 = ~clk2;

    always #20 fb = ~fb;

    initial LOCKED = 0;

    always @(posedge CLKIN1 or posedge RST) begin
        if (RST)
            LOCKED <= 0;
        else
            LOCKED <= 1;
    end

endmodule


module ODDR #(
    parameter DDR_CLK_EDGE = "SAME_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
)(
    output reg Q,
    input wire C,
    input wire CE,
    input wire D1,
    input wire D2,
    input wire R,
    input wire S
);

    initial Q = INIT;

    always @(posedge C) begin
        if (R)
            Q <= 1'b0;
        else if (S)
            Q <= 1'b1;
        else if (CE)
            Q <= D1;
    end

    always @(negedge C) begin
        if (R)
            Q <= 1'b0;
        else if (S)
            Q <= 1'b1;
        else if (CE)
            Q <= D2;
    end

endmodule


module OBUFDS (
    input wire I,
    output wire O,
    output wire OB
);
    assign O = I;
    assign OB = ~I;
endmodule
