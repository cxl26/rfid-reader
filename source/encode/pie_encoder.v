module pie_encoder
#(
    parameter PW = 2,
    parameter ONE_PERIOD = 10, // PW is 1/3 TARI works
    parameter ZERO_PERIOD = 6,
    parameter RTCAL = 16,
    parameter TRCAL = 32,
    parameter DELIMITER = 3
) (
    input  wire         clk,        // Clock signal
    input  wire         rst,        // Reset signal
    input  wire         in_bit,     // Binary input data
    output wire         in_rdy,
    output reg          out_pie = 1,     // FM0 encoded output
    input  wire         output_pie_preamble
);

    localparam COUNT_WIDTH = $clog2(TRCAL);

    localparam STATE_DATA_ZERO = 3'd0;
    localparam STATE_DATA_ONE  = 3'd1;
    localparam STATE_DELIMITER = 3'd2;
    localparam STATE_SYNC_ZERO = 3'd3;
    localparam STATE_RTCAL     = 3'd4;
    localparam STATE_TRCAL     = 3'd5;
    localparam STATE_IDLE      = 3'd6;
    
    reg [2:0] state = STATE_DELIMITER;
    reg [2:0] next_state;
    reg change_state;

    reg [COUNT_WIDTH-1:0] count = 0; // Counts samples per symbol

    assign in_rdy = change_state && (next_state == STATE_DATA_ZERO || next_state == STATE_DATA_ONE);
    
    always@(*) begin
        case (state)
            STATE_DATA_ZERO: out_pie = count < ZERO_PERIOD-PW;
            STATE_DATA_ONE : out_pie = count < ONE_PERIOD-PW;
            STATE_DELIMITER: out_pie = 0;
            STATE_SYNC_ZERO: out_pie = count < ZERO_PERIOD-PW;
            STATE_RTCAL    : out_pie = count < RTCAL-PW;
            STATE_TRCAL    : out_pie = count < TRCAL-PW;
            STATE_IDLE     : out_pie = 1;
            default        : out_pie = 1;
        endcase
        case (state)
            STATE_DATA_ZERO: change_state = (count == ZERO_PERIOD-1);
            STATE_DATA_ONE : change_state = (count == ONE_PERIOD-1);
            STATE_DELIMITER: change_state = (count == DELIMITER-1);
            STATE_SYNC_ZERO: change_state = (count == ZERO_PERIOD-1);
            STATE_RTCAL    : change_state = (count == RTCAL-1);
            STATE_TRCAL    : change_state = (count == TRCAL-1);
            STATE_IDLE     : change_state = 1;
            default        : change_state = 1;
        endcase
        case (state)
            STATE_DATA_ZERO: next_state = change_state ? in_bit : STATE_DATA_ZERO;
            STATE_DATA_ONE : next_state = change_state ? in_bit : STATE_DATA_ONE;
            STATE_DELIMITER: next_state = change_state ? STATE_SYNC_ZERO : STATE_DELIMITER;
            STATE_SYNC_ZERO: next_state = change_state ? STATE_RTCAL : STATE_SYNC_ZERO;
            STATE_RTCAL    : next_state = change_state ? (output_pie_preamble ? STATE_TRCAL : in_bit) : STATE_RTCAL;
            STATE_TRCAL    : next_state = change_state ? in_bit  : STATE_TRCAL;
            STATE_IDLE     : next_state = STATE_DELIMITER;
            default        : next_state = STATE_IDLE;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            count <= 0;
        end else begin
            state <= next_state;
            count <= change_state ? 0 : count + 1;
        end
    end

endmodule