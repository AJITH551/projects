`timescale 1ns / 1ps

module ov5640_init (
    input  wire clk,        // System / display clock
    input  wire rst_n,
    output reg  scl,
    inout  wire sda,
    output reg  done
);

    localparam TOTAL_REGS = 264;

    reg [15:0] reg_addr;
    reg [7:0]  reg_val;
    reg [8:0]  rom_idx = 0;

    // [STUDENT BUG]: Driving SDA push-pull instead of open-drain tri-state!
    // I2C/SCCB lines require open-drain (1'b0 or 1'bz). Driving 1'b1 actively causes
    // bus contention and prevents the camera from pulling SDA low to issue ACK!
    reg sda_out;
reg sda_enable;

assign sda = sda_enable ? 1'b0 : 1'bz;

    // 400 kHz tick counter (Quarter-phase of ~100 kHz SCL)
    reg [5:0] clk_cnt = 0;
    wire q_tick = (clk_cnt == 6'd62);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_cnt <= 0;
        else if (q_tick)
            clk_cnt <= 0;
        else
            clk_cnt <= clk_cnt + 1'b1;
    end

    // FSM States
    localparam S_START_WAIT = 4'd0;
    localparam S_START      = 4'd1;
    localparam S_SEND_BITS  = 4'd2;
    localparam S_STOP       = 4'd3;
    localparam S_DELAY      = 4'd4;
    localparam S_DONE       = 4'd5;

    reg [3:0]  state = S_START_WAIT;
    reg [1:0]  q_phase = 0;
    reg [5:0]  bit_idx = 0;
    reg [19:0] timer = 0;

    // Form 36-bit packet: {DevAddr(8), ACK(1), RegH(8), ACK(1), RegL(8), ACK(1), Data(8), ACK(1)}
    wire [35:0] tx_packet = {
        8'h78, 1'b1,
        reg_addr[15:8], 1'b1,
        reg_addr[7:0],  1'b1,
        reg_val[7:0],   1'b1
    };

    // ROM lookup
    always @(*) begin
        case (rom_idx)
            0: {reg_addr, reg_val} = {16'h3103, 8'h11};
            1: {reg_addr, reg_val} = {16'h3008, 8'h82};
            2: {reg_addr, reg_val} = {16'h3008, 8'h42};
            3: {reg_addr, reg_val} = {16'h3103, 8'h03};
            4: {reg_addr, reg_val} = {16'h3017, 8'hFF};
            5: {reg_addr, reg_val} = {16'h3018, 8'hFF};
            6: {reg_addr, reg_val} = {16'h3034, 8'h1A};
            7: {reg_addr, reg_val} = {16'h3037, 8'h13};
            8: {reg_addr, reg_val} = {16'h3108, 8'h01};
            9: {reg_addr, reg_val} = {16'h3630, 8'h36};
            10: {reg_addr, reg_val} = {16'h3631, 8'h0E};
            11: {reg_addr, reg_val} = {16'h3632, 8'hE2};
            12: {reg_addr, reg_val} = {16'h3633, 8'h12};
            13: {reg_addr, reg_val} = {16'h3621, 8'hE0};
            14: {reg_addr, reg_val} = {16'h3704, 8'hA0};
            15: {reg_addr, reg_val} = {16'h3703, 8'h5A};
            16: {reg_addr, reg_val} = {16'h3715, 8'h78};
            17: {reg_addr, reg_val} = {16'h3717, 8'h01};
            18: {reg_addr, reg_val} = {16'h370B, 8'h60};
            19: {reg_addr, reg_val} = {16'h3705, 8'h1A};
            20: {reg_addr, reg_val} = {16'h3905, 8'h02};
            21: {reg_addr, reg_val} = {16'h3906, 8'h10};
            22: {reg_addr, reg_val} = {16'h3901, 8'h0A};
            23: {reg_addr, reg_val} = {16'h3731, 8'h12};
            24: {reg_addr, reg_val} = {16'h3600, 8'h08};
            25: {reg_addr, reg_val} = {16'h3601, 8'h33};
            26: {reg_addr, reg_val} = {16'h302D, 8'h60};
            27: {reg_addr, reg_val} = {16'h3620, 8'h52};
            28: {reg_addr, reg_val} = {16'h371B, 8'h20};
            29: {reg_addr, reg_val} = {16'h471C, 8'h50};
            30: {reg_addr, reg_val} = {16'h3A13, 8'h43};
            31: {reg_addr, reg_val} = {16'h3A18, 8'h00};
            32: {reg_addr, reg_val} = {16'h3A19, 8'hF8};
            33: {reg_addr, reg_val} = {16'h3635, 8'h13};
            34: {reg_addr, reg_val} = {16'h3636, 8'h03};
            35: {reg_addr, reg_val} = {16'h3634, 8'h40};
            36: {reg_addr, reg_val} = {16'h3622, 8'h01};
            37: {reg_addr, reg_val} = {16'h3C01, 8'h34};
            38: {reg_addr, reg_val} = {16'h3C04, 8'h28};
            39: {reg_addr, reg_val} = {16'h3C05, 8'h98};
            40: {reg_addr, reg_val} = {16'h3C06, 8'h00};
            41: {reg_addr, reg_val} = {16'h3C07, 8'h08};
            42: {reg_addr, reg_val} = {16'h3C08, 8'h00};
            43: {reg_addr, reg_val} = {16'h3C09, 8'h1C};
            44: {reg_addr, reg_val} = {16'h3C0A, 8'h9C};
            45: {reg_addr, reg_val} = {16'h3C0B, 8'h40};
            46: {reg_addr, reg_val} = {16'h3810, 8'h00};
            47: {reg_addr, reg_val} = {16'h3811, 8'h10};
            48: {reg_addr, reg_val} = {16'h3812, 8'h00};
            49: {reg_addr, reg_val} = {16'h3708, 8'h64};
            50: {reg_addr, reg_val} = {16'h4001, 8'h02};
            51: {reg_addr, reg_val} = {16'h4005, 8'h1A};
            52: {reg_addr, reg_val} = {16'h3000, 8'h00};
            53: {reg_addr, reg_val} = {16'h3004, 8'hFF};
            54: {reg_addr, reg_val} = {16'h300E, 8'h58};
            55: {reg_addr, reg_val} = {16'h302E, 8'h00};
            56: {reg_addr, reg_val} = {16'h4300, 8'h30};
            57: {reg_addr, reg_val} = {16'h501F, 8'h00};
            58: {reg_addr, reg_val} = {16'h440E, 8'h00};
            59: {reg_addr, reg_val} = {16'h5000, 8'hA7};
            60: {reg_addr, reg_val} = {16'h3A0F, 8'h30};
            61: {reg_addr, reg_val} = {16'h3A10, 8'h28};
            62: {reg_addr, reg_val} = {16'h3A1B, 8'h30};
            63: {reg_addr, reg_val} = {16'h3A1E, 8'h26};
            64: {reg_addr, reg_val} = {16'h3A11, 8'h60};
            65: {reg_addr, reg_val} = {16'h3A1F, 8'h14};
            66: {reg_addr, reg_val} = {16'h5800, 8'h23};
            67: {reg_addr, reg_val} = {16'h5801, 8'h14};
            68: {reg_addr, reg_val} = {16'h5802, 8'h0F};
            69: {reg_addr, reg_val} = {16'h5803, 8'h0F};
            70: {reg_addr, reg_val} = {16'h5804, 8'h12};
            71: {reg_addr, reg_val} = {16'h5805, 8'h26};
            72: {reg_addr, reg_val} = {16'h5806, 8'h0C};
            73: {reg_addr, reg_val} = {16'h5807, 8'h08};
            74: {reg_addr, reg_val} = {16'h5808, 8'h05};
            75: {reg_addr, reg_val} = {16'h5809, 8'h05};
            76: {reg_addr, reg_val} = {16'h580A, 8'h08};
            77: {reg_addr, reg_val} = {16'h580B, 8'h0D};
            78: {reg_addr, reg_val} = {16'h580C, 8'h08};
            79: {reg_addr, reg_val} = {16'h580D, 8'h03};
            80: {reg_addr, reg_val} = {16'h580E, 8'h00};
            81: {reg_addr, reg_val} = {16'h580F, 8'h00};
            82: {reg_addr, reg_val} = {16'h5810, 8'h03};
            83: {reg_addr, reg_val} = {16'h5811, 8'h09};
            84: {reg_addr, reg_val} = {16'h5812, 8'h07};
            85: {reg_addr, reg_val} = {16'h5813, 8'h03};
            86: {reg_addr, reg_val} = {16'h5814, 8'h00};
            87: {reg_addr, reg_val} = {16'h5815, 8'h01};
            88: {reg_addr, reg_val} = {16'h5816, 8'h03};
            89: {reg_addr, reg_val} = {16'h5817, 8'h08};
            90: {reg_addr, reg_val} = {16'h5818, 8'h0D};
            91: {reg_addr, reg_val} = {16'h5819, 8'h08};
            92: {reg_addr, reg_val} = {16'h581A, 8'h05};
            93: {reg_addr, reg_val} = {16'h581B, 8'h06};
            94: {reg_addr, reg_val} = {16'h581C, 8'h08};
            95: {reg_addr, reg_val} = {16'h581D, 8'h0E};
            96: {reg_addr, reg_val} = {16'h581E, 8'h29};
            97: {reg_addr, reg_val} = {16'h581F, 8'h17};
            98: {reg_addr, reg_val} = {16'h5820, 8'h11};
            99: {reg_addr, reg_val} = {16'h5821, 8'h11};
            100: {reg_addr, reg_val} = {16'h5822, 8'h15};
            101: {reg_addr, reg_val} = {16'h5823, 8'h28};
            102: {reg_addr, reg_val} = {16'h5824, 8'h46};
            103: {reg_addr, reg_val} = {16'h5825, 8'h26};
            104: {reg_addr, reg_val} = {16'h5826, 8'h08};
            105: {reg_addr, reg_val} = {16'h5827, 8'h26};
            106: {reg_addr, reg_val} = {16'h5828, 8'h64};
            107: {reg_addr, reg_val} = {16'h5829, 8'h26};
            108: {reg_addr, reg_val} = {16'h582A, 8'h24};
            109: {reg_addr, reg_val} = {16'h582B, 8'h22};
            110: {reg_addr, reg_val} = {16'h582C, 8'h24};
            111: {reg_addr, reg_val} = {16'h582D, 8'h24};
            112: {reg_addr, reg_val} = {16'h582E, 8'h06};
            113: {reg_addr, reg_val} = {16'h582F, 8'h22};
            114: {reg_addr, reg_val} = {16'h5830, 8'h40};
            115: {reg_addr, reg_val} = {16'h5831, 8'h42};
            116: {reg_addr, reg_val} = {16'h5832, 8'h24};
            117: {reg_addr, reg_val} = {16'h5833, 8'h26};
            118: {reg_addr, reg_val} = {16'h5834, 8'h24};
            119: {reg_addr, reg_val} = {16'h5835, 8'h22};
            120: {reg_addr, reg_val} = {16'h5836, 8'h22};
            121: {reg_addr, reg_val} = {16'h5837, 8'h26};
            122: {reg_addr, reg_val} = {16'h5838, 8'h44};
            123: {reg_addr, reg_val} = {16'h5839, 8'h24};
            124: {reg_addr, reg_val} = {16'h583A, 8'h26};
            125: {reg_addr, reg_val} = {16'h583B, 8'h28};
            126: {reg_addr, reg_val} = {16'h583C, 8'h42};
            127: {reg_addr, reg_val} = {16'h583D, 8'hCE};
            128: {reg_addr, reg_val} = {16'h5180, 8'hFF};
            129: {reg_addr, reg_val} = {16'h5181, 8'hF2};
            130: {reg_addr, reg_val} = {16'h5182, 8'h00};
            131: {reg_addr, reg_val} = {16'h5183, 8'h14};
            132: {reg_addr, reg_val} = {16'h5184, 8'h25};
            133: {reg_addr, reg_val} = {16'h5185, 8'h24};
            134: {reg_addr, reg_val} = {16'h5186, 8'h09};
            135: {reg_addr, reg_val} = {16'h5187, 8'h09};
            136: {reg_addr, reg_val} = {16'h5188, 8'h09};
            137: {reg_addr, reg_val} = {16'h5189, 8'h75};
            138: {reg_addr, reg_val} = {16'h518A, 8'h54};
            139: {reg_addr, reg_val} = {16'h518B, 8'hE0};
            140: {reg_addr, reg_val} = {16'h518C, 8'hB2};
            141: {reg_addr, reg_val} = {16'h518D, 8'h42};
            142: {reg_addr, reg_val} = {16'h518E, 8'h3D};
            143: {reg_addr, reg_val} = {16'h518F, 8'h56};
            144: {reg_addr, reg_val} = {16'h5190, 8'h46};
            145: {reg_addr, reg_val} = {16'h5191, 8'hF8};
            146: {reg_addr, reg_val} = {16'h5192, 8'h04};
            147: {reg_addr, reg_val} = {16'h5193, 8'h70};
            148: {reg_addr, reg_val} = {16'h5194, 8'hF0};
            149: {reg_addr, reg_val} = {16'h5195, 8'hF0};
            150: {reg_addr, reg_val} = {16'h5196, 8'h03};
            151: {reg_addr, reg_val} = {16'h5197, 8'h01};
            152: {reg_addr, reg_val} = {16'h5198, 8'h04};
            153: {reg_addr, reg_val} = {16'h5199, 8'h12};
            154: {reg_addr, reg_val} = {16'h519A, 8'h04};
            155: {reg_addr, reg_val} = {16'h519B, 8'h00};
            156: {reg_addr, reg_val} = {16'h519C, 8'h06};
            157: {reg_addr, reg_val} = {16'h519D, 8'h82};
            158: {reg_addr, reg_val} = {16'h519E, 8'h38};
            159: {reg_addr, reg_val} = {16'h5480, 8'h01};
            160: {reg_addr, reg_val} = {16'h5481, 8'h08};
            161: {reg_addr, reg_val} = {16'h5482, 8'h14};
            162: {reg_addr, reg_val} = {16'h5483, 8'h28};
            163: {reg_addr, reg_val} = {16'h5484, 8'h51};
            164: {reg_addr, reg_val} = {16'h5485, 8'h65};
            165: {reg_addr, reg_val} = {16'h5486, 8'h71};
            166: {reg_addr, reg_val} = {16'h5487, 8'h7D};
            167: {reg_addr, reg_val} = {16'h5488, 8'h87};
            168: {reg_addr, reg_val} = {16'h5489, 8'h91};
            169: {reg_addr, reg_val} = {16'h548A, 8'h9A};
            170: {reg_addr, reg_val} = {16'h548B, 8'hAA};
            171: {reg_addr, reg_val} = {16'h548C, 8'hB8};
            172: {reg_addr, reg_val} = {16'h548D, 8'hCD};
            173: {reg_addr, reg_val} = {16'h548E, 8'hDD};
            174: {reg_addr, reg_val} = {16'h548F, 8'hEA};
            175: {reg_addr, reg_val} = {16'h5490, 8'h1D};
            176: {reg_addr, reg_val} = {16'h5381, 8'h1E};
            177: {reg_addr, reg_val} = {16'h5382, 8'h5B};
            178: {reg_addr, reg_val} = {16'h5383, 8'h08};
            179: {reg_addr, reg_val} = {16'h5384, 8'h0A};
            180: {reg_addr, reg_val} = {16'h5385, 8'h7E};
            181: {reg_addr, reg_val} = {16'h5386, 8'h88};
            182: {reg_addr, reg_val} = {16'h5387, 8'h7C};
            183: {reg_addr, reg_val} = {16'h5388, 8'h6C};
            184: {reg_addr, reg_val} = {16'h5389, 8'h10};
            185: {reg_addr, reg_val} = {16'h538A, 8'h01};
            186: {reg_addr, reg_val} = {16'h538B, 8'h98};
            187: {reg_addr, reg_val} = {16'h5580, 8'h06};
            188: {reg_addr, reg_val} = {16'h5583, 8'h40};
            189: {reg_addr, reg_val} = {16'h5584, 8'h10};
            190: {reg_addr, reg_val} = {16'h5589, 8'h10};
            191: {reg_addr, reg_val} = {16'h558A, 8'h00};
            192: {reg_addr, reg_val} = {16'h558B, 8'hF8};
            193: {reg_addr, reg_val} = {16'h501D, 8'h40};
            194: {reg_addr, reg_val} = {16'h5300, 8'h08};
            195: {reg_addr, reg_val} = {16'h5301, 8'h30};
            196: {reg_addr, reg_val} = {16'h5302, 8'h10};
            197: {reg_addr, reg_val} = {16'h5303, 8'h00};
            198: {reg_addr, reg_val} = {16'h5304, 8'h08};
            199: {reg_addr, reg_val} = {16'h5305, 8'h30};
            200: {reg_addr, reg_val} = {16'h5306, 8'h08};
            201: {reg_addr, reg_val} = {16'h5307, 8'h16};
            202: {reg_addr, reg_val} = {16'h5309, 8'h08};
            203: {reg_addr, reg_val} = {16'h530A, 8'h30};
            204: {reg_addr, reg_val} = {16'h530B, 8'h04};
            205: {reg_addr, reg_val} = {16'h530C, 8'h06};
            206: {reg_addr, reg_val} = {16'h5025, 8'h00};
            207: {reg_addr, reg_val} = {16'h3008, 8'h02};
            208: {reg_addr, reg_val} = {16'h3035, 8'h41};
            209: {reg_addr, reg_val} = {16'h3036, 8'h69};
            210: {reg_addr, reg_val} = {16'h3C07, 8'h07};
            211: {reg_addr, reg_val} = {16'h3820, 8'h46};
            212: {reg_addr, reg_val} = {16'h3821, 8'h00};
            213: {reg_addr, reg_val} = {16'h3814, 8'h31};
            214: {reg_addr, reg_val} = {16'h3815, 8'h31};
            215: {reg_addr, reg_val} = {16'h3800, 8'h00};
            216: {reg_addr, reg_val} = {16'h3801, 8'h00};
            217: {reg_addr, reg_val} = {16'h3802, 8'h00};
            218: {reg_addr, reg_val} = {16'h3803, 8'h00};
            219: {reg_addr, reg_val} = {16'h3804, 8'h0A};
            220: {reg_addr, reg_val} = {16'h3805, 8'h3F};
            221: {reg_addr, reg_val} = {16'h3806, 8'h06};
            222: {reg_addr, reg_val} = {16'h3807, 8'hA9};
            223: {reg_addr, reg_val} = {16'h3808, 8'h05};
            224: {reg_addr, reg_val} = {16'h3809, 8'h00};
            225: {reg_addr, reg_val} = {16'h380A, 8'h02};
            226: {reg_addr, reg_val} = {16'h380B, 8'hD0};
            227: {reg_addr, reg_val} = {16'h380C, 8'h05};
            228: {reg_addr, reg_val} = {16'h380D, 8'hF8};
            229: {reg_addr, reg_val} = {16'h380E, 8'h03};
            230: {reg_addr, reg_val} = {16'h380F, 8'h84};
            231: {reg_addr, reg_val} = {16'h3813, 8'h04};
            232: {reg_addr, reg_val} = {16'h3618, 8'h00};
            233: {reg_addr, reg_val} = {16'h3612, 8'h29};
            234: {reg_addr, reg_val} = {16'h3709, 8'h52};
            235: {reg_addr, reg_val} = {16'h370C, 8'h03};
            236: {reg_addr, reg_val} = {16'h3A02, 8'h02};
            237: {reg_addr, reg_val} = {16'h3A03, 8'hE0};
            238: {reg_addr, reg_val} = {16'h3A14, 8'h02};
            239: {reg_addr, reg_val} = {16'h3A15, 8'hE0};
            240: {reg_addr, reg_val} = {16'h4004, 8'h02};
            241: {reg_addr, reg_val} = {16'h3002, 8'h1C};
            242: {reg_addr, reg_val} = {16'h3006, 8'hC3};
            243: {reg_addr, reg_val} = {16'h4713, 8'h03};
            244: {reg_addr, reg_val} = {16'h4407, 8'h04};
            245: {reg_addr, reg_val} = {16'h460B, 8'h37};
            246: {reg_addr, reg_val} = {16'h460C, 8'h20};
            247: {reg_addr, reg_val} = {16'h4837, 8'h16};
            248: {reg_addr, reg_val} = {16'h3824, 8'h04};
            249: {reg_addr, reg_val} = {16'h5001, 8'hA3};
            250: {reg_addr, reg_val} = {16'h3503, 8'h00};
            251: {reg_addr, reg_val} = {16'h4300, 8'h61};
            252: {reg_addr, reg_val} = {16'h501F, 8'h01};
            253: {reg_addr, reg_val} = {16'h300E, 8'h58};
            254: {reg_addr, reg_val} = {16'h3017, 8'hFF};
            255: {reg_addr, reg_val} = {16'h3018, 8'hFF};
            256: {reg_addr, reg_val} = {16'h3212, 8'h03};
            257: {reg_addr, reg_val} = {16'h3808, 8'h01};
            258: {reg_addr, reg_val} = {16'h3809, 8'h40};
            259: {reg_addr, reg_val} = {16'h380A, 8'h00};
            260: {reg_addr, reg_val} = {16'h380B, 8'hF0};
            261: {reg_addr, reg_val} = {16'h3212, 8'h13};
            262: {reg_addr, reg_val} = {16'h3212, 8'hA3};
            263: {reg_addr, reg_val} = {16'h3008, 8'h02};
            default: {reg_addr, reg_val} = {16'hFFFF, 8'hFF};
        endcase
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_START_WAIT;
            q_phase  <= 0;
            scl      <= 1'b1;
            sda_out  <= 1'b1;
            rom_idx  <= 0;
            bit_idx  <= 0;
            timer    <= 0;
            done     <= 1'b0;
        end else begin
            case (state)
                // Wait ~10ms (250,000 cycles) before starting I2C
                S_START_WAIT: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    if (timer < 20'd250_000)
                        timer <= timer + 1'b1;
                    else begin
                        timer   <= 0;
                        q_phase <= 0;
                        state   <= S_START;
                    end
                end

                // Generate I2C START Condition: SDA goes LOW while SCL is HIGH
                S_START: begin
                    if (q_tick) begin
                        q_phase <= q_phase + 1'b1;
                        case (q_phase)
                            2'd0: begin scl <= 1'b1; sda_out <= 1'b1; end
                            2'd1: begin scl <= 1'b1; sda_out <= 1'b0; end // SDA falls while SCL high
                            2'd2: begin scl <= 1'b1; sda_out <= 1'b0; end
                            2'd3: begin
                                scl     <= 1'b0; // SCL falls
                                bit_idx <= 0;
                                q_phase <= 0;
                                state   <= S_SEND_BITS;
                            end
                        endcase
                    end
                end

                // Transmit 36 bits
                S_SEND_BITS: begin
                    if (q_tick) begin
                        q_phase <= q_phase + 1'b1;
                        case (q_phase)
                            2'd0: begin
                                scl     <= 1'b0;
                                sda_out <= tx_packet[35 - bit_idx]; // Set bit data
                            end
                            2'd1: begin
                                scl <= 1'b1; // SCL rises (slave samples)
                            end
                            2'd2: begin
                                scl <= 1'b1; // Hold
                            end
                            2'd3: begin
                                scl <= 1'b0; // SCL falls
                                if (bit_idx == 35) begin
                                    q_phase <= 0;
                                    state   <= S_STOP;
                                end else begin
                                    bit_idx <= bit_idx + 1'b1;
                                end
                            end
                        endcase
                    end
                end

                // Generate I2C STOP Condition: SDA goes HIGH while SCL is HIGH
                S_STOP: begin
                    if (q_tick) begin
                        q_phase <= q_phase + 1'b1;
                        case (q_phase)
                            2'd0: begin scl <= 1'b0; sda_out <= 1'b0; end
                            2'd1: begin scl <= 1'b1; sda_out <= 1'b0; end
                            2'd2: begin scl <= 1'b1; sda_out <= 1'b1; end // SDA rises while SCL high
                            2'd3: begin
                                scl     <= 1'b1;
                                sda_out <= 1'b1;
                                timer   <= 0;
                                state   <= S_DELAY;
                            end
                        endcase
                    end
                end

                // Delay between register writes (10ms after reset, 100us otherwise)
                S_DELAY: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    // Reset command (rom_idx == 1 is 0x3008=0x82) needs 10ms delay (250,000 cycles)
                    if (rom_idx == 1) begin
                        if (timer < 20'd250_000)
                            timer <= timer + 1'b1;
                        else begin
                            timer   <= 0;
                            rom_idx <= rom_idx + 1'b1;
                            q_phase <= 0;
                            state   <= S_START;
                        end
                    end else begin
                        // Standard ~100us inter-frame delay (2,500 cycles)
                        if (timer < 20'd2500)
                            timer <= timer + 1'b1;
                        else begin
                            timer <= 0;
                            if (rom_idx == TOTAL_REGS - 1) begin
                                state <= S_DONE;
                            end else begin
                                rom_idx <= rom_idx + 1'b1;
                                q_phase <= 0;
                                state   <= S_START;
                            end
                        end
                    end
                end

                S_DONE: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    done    <= 1'b1; // Turn on init_done_led
                end
            endcase
        end
    end

endmodule
