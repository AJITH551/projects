module dig_clk_tb;
reg clk;
reg rst;
wire [6:0]seg;
wire [3:0]an;

top_module uut(.clk(clk),.rst(rst),.seg(seg),.an(an));

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
$monitor("time=%0t rst=%b min=%0d sec=%0d ",$time,rst,uut.u2.min,uut.u2.sec);
$dumpfile("digital_clk.vcd");
$dumpvars;
end

endmodule
