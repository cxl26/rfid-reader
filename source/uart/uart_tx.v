module uart_tx #(
    parameter       DATA_BITS   = 8,
    parameter       STOP_BITS   = 1,
    parameter       CLK_RATE    = 12000000,
    parameter       BAUD_RATE   = 9600
)(
    input               clk,         // clock
    input [DATA_BITS-1:0] tx_byte,   // byte to serialise
    input               send,        // send trigger
    output wire         ready,       // ready flag
    output wire         tx_bits      // bits serialised
 );

    /* States */
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_START   = 2'd1;
    localparam STATE_TX      = 2'd2;
    localparam STATE_STOP    = 2'd3;
    reg [1:0]  state         = STATE_IDLE;

    /* Shift Register */
    localparam SHIFT_COUNTER_VALUE = DATA_BITS-1;
    localparam SHIFT_COUNTER_WIDTH = $clog2(SHIFT_COUNTER_VALUE+1);
    reg [DATA_BITS-1:0]           shift_register;
    reg [SHIFT_COUNTER_WIDTH-1:0] shift_counter;

    /* Serial Counter */
    localparam SERIAL_COUNTER_VALUE = CLK_RATE/BAUD_RATE-1;
    localparam SERIAL_COUNTER_WIDTH = $clog2(SERIAL_COUNTER_VALUE+1);
    wire                           serial_strobe;
    reg [SERIAL_COUNTER_WIDTH-1:0] serial_counter = SERIAL_COUNTER_VALUE;
  
    /* Finite State Machine */
    always @(posedge clk) begin

        // Drive serial counter
        if (serial_strobe || state==STATE_IDLE) begin
            serial_counter <= SERIAL_COUNTER_VALUE;
        end else begin
            serial_counter <= serial_counter-1;
        end

        // Drive states and shifting
        case (state)
            STATE_IDLE: begin
                if (send) begin
                    state          <= STATE_START;
                    shift_counter  <= DATA_BITS-1;
                    shift_register <= tx_byte;
                end
            end

            STATE_START: begin
                if (serial_strobe) begin
                    state          <= STATE_TX;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

            STATE_TX: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_STOP    : STATE_TX;
                    shift_counter  <= (shift_counter == 0) ? STOP_BITS-1   : shift_counter-1;
                    shift_register <= shift_register >> 1;
                end
            end

            STATE_STOP: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_IDLE    : STATE_STOP;
                    shift_counter  <= (shift_counter == 0) ? DATA_BITS-1   : shift_counter-1;
                    shift_register <= shift_register;
                end
            end
        endcase

    end

    assign ready         = (state == STATE_IDLE);
    assign serial_strobe = (serial_counter == 0);
    assign tx_bits       = state==STATE_STOP || state==STATE_IDLE || (state==STATE_TX && shift_register[0]);

endmodule