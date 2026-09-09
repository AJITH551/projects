module digit_splitter(input [5:0]min,sec,
output [3:0]min_tens,
output [3:0]min_ones,
output [3:0]sec_tens,
output [3:0]sec_ones);

assign min_tens=min/10;
assign min_ones=min%10;
assign sec_tens=sec/10;
assign sec_ones=sec%10;

endmodule
