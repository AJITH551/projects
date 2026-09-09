module top_module(input clk,rst,
output [6:0] seg,
output [3:0] an);

wire tick;
    wire refresh_tick;

    wire [5:0] min;
    wire [5:0] sec;

    wire [3:0] min_tens;
    wire [3:0] min_ones;
    wire [3:0] sec_tens;
    wire [3:0] sec_ones;

    wire [6:0] seg_min_tens;
    wire [6:0] seg_min_ones;
    wire [6:0] seg_sec_tens;
    wire [6:0] seg_sec_ones;
clk_div u1(.clk(clk),
	.rst(rst),
	.tick(tick),
.refresh_tick(refresh_tick));

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

seven_seg d1(.digit(min_tens),.seg(seg_min_tens));
seven_seg d2(.digit(min_ones),.seg(seg_min_ones));
seven_seg d3(.digit(sec_tens),.seg(seg_sec_tens));
seven_seg d4(.digit(sec_ones),.seg(seg_sec_ones));

seg_mux u4 (
        .clk(clk),
        .rst(rst),
        .refresh_tick(refresh_tick),
        .seg_min_tens(seg_min_tens),
        .seg_min_ones(seg_min_ones),
        .seg_sec_tens(seg_sec_tens),
        .seg_sec_ones(seg_sec_ones),
        .seg(seg),
        .an(an)
    );


endmodule
