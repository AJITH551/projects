module clk_div(input clk,rst,
output reg tick);

reg [31:0]count;
always@(posedge clk or posedge rst)begin
	if(rst)begin 
		count<=32'd0;
		tick<=1'b0;
	end
	else if(count==49)begin
		count<=32'd0;
		tick<=1'b1;
	end
	else begin
		count<=count+1'b1;
		tick<=1'b0;
	end
end
endmodule

