module clk_div(input clk,rst,
output reg tick,
output reg refresh_tick);

reg [31:0]count;
reg [15:0]count_refresh;
always@(posedge clk or posedge rst)begin
	if(rst)begin 
		count<=32'd0;
		tick<=1'b0;
		count_refresh<=0;
		refresh_tick<=0;
	end
	else begin
		if(count==32'd49)begin
		count<=32'd0;
		tick<=1'b1;
	end
	else begin
		count<=count+1'b1;
		tick<=1'b0;
	end

	 if (count_refresh == 16'd4) begin
                count_refresh <= 0;
                refresh_tick  <= 1'b1;
            end
            else begin
                count_refresh <= count_refresh + 1'b1;
                refresh_tick  <= 1'b0;
            end
end
end
endmodule

