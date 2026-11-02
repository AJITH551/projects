module hdmi_tx (
        input  wire       pixel_clk,     // Base pixel clock (determined by video resolution)
        input  wire       pixel_clk_x5,  // Serializer clock (5x DDR ratio)
        input  wire       rst_n,
        input  wire [7:0] red,
        input  wire [7:0] green,
        input  wire [7:0] blue,
        input  wire       hsync,
        input  wire       vsync,
        input  wire       active,
    
        output wire       tmds_clk_p,
        output wire       tmds_clk_n,
        output wire [2:0] tmds_data_p,
        output wire [2:0] tmds_data_n
    );
    
        wire [9:0] tmds_r, tmds_g, tmds_b;
    
        // 8b/10b Encoders
        tmds_encoder enc_b (
            .clk(pixel_clk),
            .data_in(blue),
            .control_in({vsync, hsync}),
            .video_active(active),
            .tmds_out(tmds_b)
        );
    
        tmds_encoder enc_g (
            .clk(pixel_clk),
            .data_in(green),
            .control_in(2'b00),
            .video_active(active),
            .tmds_out(tmds_g)
        );
    
        tmds_encoder enc_r (
            .clk(pixel_clk),
            .data_in(red),
            .control_in(2'b00),
            .video_active(active),
            .tmds_out(tmds_r)
        );
    
        // Shift registers for 10-bit words (5 cycles x 2 bits per cycle = 10 bits)
        reg [9:0] shift_r = 0, shift_g = 0, shift_b = 0;
        reg [2:0] mod5 = 0;
    
        always @(posedge pixel_clk_x5) begin
            if (mod5 == 3'd4) begin
                mod5    <= 3'd0;
                shift_r <= tmds_r;
                shift_g <= tmds_g;
                shift_b <= tmds_b;
            end else begin
                mod5    <= mod5 + 1'b1;
                // [STUDENT BUG]: Inverted shift direction (transmitting MSB first)!
                // DVI 1.0 specification requires LSB-first serialization: {2'b00, shift_r[9:2]}.
                shift_r <= {2'b00,shift_r[9:2]};
                shift_g <= {2'b00,shift_g[9:2]};
                shift_b <= {2'b00,shift_b[9:2]};
            end
        end
    
        // TMDS Data Serializers via Artix-7 ODDR (Double Data Rate)
        wire [2:0] ddr_data;
        
        genvar i;
        generate
            for (i = 0; i < 3; i = i + 1) begin : gen_tmds_oddr
                wire [1:0] pair = (i == 0) ? shift_b[1:0] :
                                  (i == 1) ? shift_g[1:0] : shift_r[1:0];
                ODDR #(
                    .DDR_CLK_EDGE("SAME_EDGE"),
                    .INIT(1'b0),
                    .SRTYPE("SYNC")
                ) oddr_data_inst (
                    .Q(ddr_data[i]),
                    .C(pixel_clk_x5),
                    .CE(1'b1),
                    .D1(pair[0]),
                    .D2(pair[1]),
                    .R(!rst_n),
                    .S(1'b0)
                );
    
                OBUFDS obuf_data (
                    .I(ddr_data[i]),
                    .O(tmds_data_p[i]),
                    .OB(tmds_data_n[i])
                );
            end
        endgenerate
    
        // TMDS Clock: Direct pixel clock forwarded via ODDR to match data phase
        wire tmds_clk_ddr;
        ODDR #(
            .DDR_CLK_EDGE("SAME_EDGE"),
            .INIT(1'b0),
            .SRTYPE("SYNC")
        ) oddr_clk_inst (
            .Q(tmds_clk_ddr),
            .C(pixel_clk),
            .CE(1'b1),
            .D1(1'b1),
            .D2(1'b0),
            .R(!rst_n),
            .S(1'b0)
        );
    
        OBUFDS obuf_clk (
            .I(tmds_clk_ddr),
            .O(tmds_clk_p),
            .OB(tmds_clk_n)
        );
    
    endmodule
