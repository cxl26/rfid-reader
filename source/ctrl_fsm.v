module ctrl_fsm #(
    parameter       QRY_BITS      = 17,    // Bits in query msg, excluding CRC5 checksum
    parameter       RN16_BITS     = 16,    // Bits in rn16 msg
    parameter       ACK_BITS      = 18,    // Bits in ack msg
    parameter       EPC_BITS      = 16,   // Bits in epc msg excluding CRC16 checksum and EPC words (so just PC)
    parameter       REP_BITS      = 4,   // Bits in queryrep msg
    parameter       NAK_BITS      = 8,   // Bits in nak msg
    parameter       RN16_TIMEOUT  = 1000,
    parameter       EPC_TIMEOUT   = 20000,
    parameter       IDLE_TIMEOUT  = 500
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         in_dat, 
    input  wire         in_vld,
    input  wire         crc16_chk,
    input  wire [4:0]   crc5_val,
    output reg          out_dat,
    input  wire         out_rdy,
    output wire         sending,
    output wire         receiving,
    output wire         output_pie_preamble
);
    // State machine
    localparam SND_QRY  = 3'd0;
    localparam RCV_RN16 = 3'd1;
    localparam SND_ACK  = 3'd2;
    localparam RCV_EPC  = 3'd3;
    localparam SND_REP  = 3'd4;
    localparam SND_NAK  = 3'd5;
    localparam IDLE     = 3'd6;
    (* mark_debug = "true" *) reg [2:0] state = IDLE;
    reg [2:0] next_state;
    
    localparam TIME_COUNT_WIDTH = $clog2(IDLE_TIMEOUT);
    
    // Counters
    reg [9:0] bits_counter = 0;
    reg [TIME_COUNT_WIDTH-1:0] time_counter = 0;
    reg [6:0] slot_counter = 2**CMD_Q - 1;

    reg [4:0]   epc_len = 5'b11111;
    reg [511:0] epc_val = 0;

    // State transition trigger signals
    wire timeout;
    wire still_querying;
    wire qry_sent;
    wire rn16_rcvd;
    wire ack_sent;
    wire epc_rcvd;
    wire rep_sent;
    wire nak_sent;

    localparam QRY_CMD = 4'b1000;
    localparam ACK_CMD = 2'b01;
    localparam REP_CMD = 2'b00;
    localparam NAK_CMD = 8'b11000000;
    localparam CMD_DR = 1'b0;
    localparam CMD_M = 2'b00;
    localparam CMD_TREXT = 1'b0;
    localparam CMD_SELECT = 2'b00;
    localparam CMD_SESSION = 2'b00;
    localparam CMD_TARGET = 1'b0;
    localparam CMD_Q = 4'b0000;
    localparam CMD_CRC = 5'b10000;

    reg [0:QRY_BITS+5-1] qry_command = {QRY_CMD,CMD_DR,CMD_M,CMD_TREXT,CMD_SELECT,CMD_SESSION,CMD_TARGET,CMD_Q,CMD_CRC};
    reg [0:ACK_BITS-1]   ack_command = {ACK_CMD,{16{1'b0}}};
    reg [0:REP_BITS-1]   rep_command = {REP_CMD, CMD_SESSION};
    reg [0:NAK_BITS-1]   nak_command = NAK_CMD;

    // Receiving and sending flags
    assign receiving = state == RCV_RN16 || state == RCV_EPC;
    assign sending   = state == SND_QRY || state == SND_ACK || state == SND_REP || state == SND_NAK;

    // State transition triggers
    assign timeout = (time_counter == IDLE_TIMEOUT && state == IDLE)
                  || (time_counter == EPC_TIMEOUT && state == RCV_EPC)
                  || (time_counter == RN16_TIMEOUT && state == RCV_RN16);
    assign still_querying = (slot_counter != 0);
    assign qry_sent  = (state == SND_QRY) && (bits_counter == QRY_BITS + 5) && out_rdy;
    assign rn16_rcvd = (state == RCV_RN16) && (bits_counter == RN16_BITS);
    assign ack_sent  = (state == SND_ACK) && (bits_counter == ACK_BITS) && out_rdy;
    assign epc_rcvd  = (state == RCV_EPC) && (bits_counter == EPC_BITS + epc_len*16 + 16);
    assign rep_sent  = (state == SND_REP) && (bits_counter == REP_BITS) && out_rdy;
    assign nak_sent  = (state == SND_NAK) && (bits_counter == NAK_BITS) && out_rdy;

    // State machine
    always@(*) begin
        case(state)
            SND_QRY:    next_state = qry_sent ? RCV_RN16 : SND_QRY;
            SND_ACK:    next_state = ack_sent ? RCV_EPC : SND_ACK;
            SND_REP:    next_state = rep_sent ? RCV_RN16 : SND_REP;
            SND_NAK:    next_state = nak_sent ? IDLE : SND_NAK;
            IDLE:       next_state = timeout ? SND_QRY : IDLE;
            RCV_RN16:
            begin
                if (rn16_rcvd) begin
                    next_state = SND_ACK;
                end else begin
                    if (timeout)    next_state = (slot_counter == 0) ? IDLE : SND_REP;
                    else            next_state = RCV_RN16;
                end 
            end
            RCV_EPC:
            begin
                if (epc_rcvd) begin
                    if (crc16_chk)  next_state = (slot_counter == 0) ? SND_NAK : SND_REP;
                    else            next_state = IDLE;
                end else begin
                    if (timeout)    next_state = IDLE;
                    else            next_state = RCV_EPC;
                end 
            end
            default:    next_state = IDLE;
        endcase
    end

    // always@(*) begin
    //     if (sending) begin
    //         out_vld = 1'b1;
    //         case(state)
    //             SND_QRY: out_dat = qry_command[bits_counter];
    //             SND_ACK: out_dat = ack_command[bits_counter];
    //             SND_REP: out_dat = rep_command[bits_counter];
    //             SND_NAK: out_dat = nak_command[bits_counter];
    //         endcase
    //     end else begin
    //         out_vld = 1'b0;
    //         out_dat = 1'b0;
    //     end
    // end

    always@(*) begin
        case(state)
            SND_QRY: out_dat = qry_command[0];
            SND_ACK: out_dat = ack_command[0];
            SND_REP: out_dat = rep_command[0];
            SND_NAK: out_dat = nak_command[0];
            default: out_dat = 1'b0;
        endcase
    end
    assign output_pie_preamble = (state == SND_QRY);

    always@(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bits_counter <= 0;
            time_counter <= 0;
            slot_counter <= 2**CMD_Q -1;
            epc_len <= 5'b11111;
            epc_val <= 0;
            qry_command <= {QRY_CMD,CMD_DR,CMD_M,CMD_TREXT,CMD_SELECT,CMD_SESSION,CMD_TARGET,CMD_Q,CMD_CRC};
            ack_command <= {ACK_CMD,{16{1'b0}}};
            rep_command <= {REP_CMD, CMD_SESSION};
            nak_command <= NAK_CMD;
        end else begin
            state <= next_state; 
            if (state != next_state) begin
                bits_counter <= 0;
                time_counter <= 0;
            end else begin
                bits_counter <= bits_counter + (receiving && in_vld) + (sending && out_rdy);
                time_counter <= time_counter + 1;
            end
            if (state != next_state && state == SND_REP && slot_counter != 0) begin
                slot_counter <= slot_counter-1;
            end

            // Receiving behaviour
            if (receiving && in_vld) begin
                case(state)
                    RCV_RN16:
                    begin
                        // write rn16 into ack command to send back
                        ack_command[bits_counter+2] <= in_dat;
                    end 
                    RCV_EPC:
                    begin
                        // write first 5 bits of 16-bit protocol control to epc_len
                        if (bits_counter < 5) begin
                            epc_len[bits_counter] <= in_dat;
                        end 
                        // write all bits after 16-bit protocol control to epc_val
                        if (bits_counter > 15) begin
                            epc_val[bits_counter-16] <= in_dat;
                        end
                    end
                endcase
            end

            // Sending behaviour
            if (sending && out_rdy && next_state == state) begin
                case(state)
                    SND_QRY: qry_command <= {qry_command[1:QRY_BITS+5-1], qry_command[0]};
                    SND_ACK: ack_command <= {ack_command[1:ACK_BITS-1], ack_command[0]};
                    SND_REP: rep_command <= {rep_command[1:REP_BITS-1], rep_command[0]};
                    SND_NAK: nak_command <= {nak_command[1:NAK_BITS-1], nak_command[0]};
                endcase
            end

        end
    end



endmodule