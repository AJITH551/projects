module top_module(input clk,rst,
output [6:0]seg1,
output [6:0]seg2,
output [6:0]seg3,
output [6:0]seg4);

wire tick;
wire [5:0]min;
wire [5:0]sec;

wire [3:0]min_tens;
wire [3:0]min_ones;
wire [3:0]sec_tens;
wire [3:0]sec_ones;

clk_div u1(.clk(clk),
	.rst(rst),
	.tick(tick));

count u2(.clk(clk),
	.rst(rst),
	.tick(tick),
	.min(min),
	.sec(sec));

digit_splitter u3(.min(min),
	.sec(sec),
	.min_tens(min_tens),
	.min_ones(min_ones),
	.sec_tens(sec_tens),
	.sec_ones(sec_ones));

seven_seg d1(.digit(min_tens),.seg(seg1));
seven_seg d2(.digit(min_ones),.seg(seg2));
seven_seg d3(.digit(sec_tens),.seg(seg3));
seven_seg d4(.digit(sec_ones),.seg(seg4));

endmodule
