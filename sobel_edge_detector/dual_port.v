module dual_port_bram #(
        parameter ADDR_WIDTH = 17,
        parameter DATA_WIDTH = 16
    )(
        // Write Port (Camera Domain)
        input  wire                  clka,
        input  wire                  wea,
        input  wire [ADDR_WIDTH-1:0] addra,
        input  wire [DATA_WIDTH-1:0] dina,
        
        // Read Port (HDMI Pixel Clock Domain)
        input  wire                  clkb,
        input  wire [ADDR_WIDTH-1:0] addrb,
        output reg [DATA_WIDTH-1:0] doutb  // [STUDENT BUG]: Changed to wire
    );
    
        // 76,800 words = 320 x 240
        (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:76799];
    
        always @(posedge clka) begin
            if (wea && addra < 76800)
                mem[addra] <= dina;
        end
    
        // [STUDENT BUG]: Asynchronous combinational read breaks BRAM inference!
        // Xilinx Block RAM (RAMB36) requires a synchronous clocked read port.
        always @(posedge clkb) begin
            if ( addrb < 76800)
                doutb <= mem[addrb];
        end
    
    endmodule
