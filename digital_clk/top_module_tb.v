module dig_clk_tb;
reg clk;
reg rst;
wire [6:0] seg1;
wire [6:0] seg2;
wire [6:0] seg3;
wire [6:0] seg4;

top_module uut(.clk(clk),.rst(rst),.seg1(seg1),.seg2(seg2),.seg3(seg3),.seg4(seg4));

always #10 clk=~clk;

initial begin
clk=0;
rst=1;
#100;
rst=0;

#200000;
$finish;
end
initial begin
$monitor("time=%0t rst=%b min=%d sec=%d display=%0d%0d:%0d%0d",$time,rst,uut.u2.min,uut.u2.sec,uut.u3.min_tens,uut.u3.min_ones,uut.u3.sec_tens,uut.u3.sec_ones);
end

endmodule
