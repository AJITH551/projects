module seg_mux(input clk,rst,
input refresh_tick,
input [6:0]seg_min_tens,
input [6:0]seg_min_ones,
input [6:0]seg_sec_tens,
input [6:0]seg_sec_ones,
output reg [6:0] seg,
output reg [3:0] an);

reg [1:0] digit_select;

always@(posedge clk or posedge rst)begin
        if(rst)begin
                digit_select<=2'b00;
        end
        else if(refresh_tick)begin
                digit_select<=digit_select +1'b1;
        end
end

always@(*)begin
        case(digit_select)
                2'b00:begin
                        an=4'b1110;
                        seg=seg_min_tens;
		end

		2'b01:begin
			an=4'b1101;
			seg=seg_min_ones;
		end

		2'b10:begin
			an=4'b1011;
			seg=seg_sec_tens;
		end

		2'b11:begin
			an=4'b0111;
			seg=seg_sec_ones;
		end

		default:begin
			an=4'b1111;
			seg=7'b1111111;
		end
	endcase
end
endmodule
