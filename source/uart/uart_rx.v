module uart_rx #(
    parameter       DATA_BITS   = 8,
    parameter       STOP_BITS   = 2,
    parameter       CLK_RATE    = 12000000,
    parameter       BAUD_RATE   = 9600
)(
    input                       clk,         // clock
    input                       rx_bits,     // received bits
    input                       receive,     // receive signal
    output wire                 valid,       // ready flag
    output wire [DATA_BITS-1:0] rx_byte     // byte to serialise
);


    /* States */
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_START   = 2'd1;
    localparam STATE_RX      = 2'd2;
    localparam STATE_DONE    = 2'd3;
    reg [4:0]  state         = 2'd0;

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

    /* Synchroniser Registers */
    reg [3:0] rx_reg = 4'b1111;

    /* Double Flop Synchroniser */
    always@(posedge clk) begin  
        rx_reg <= {rx_bits,rx_reg[3:1]};
    end
    
    /* Finite State Machine */
    always @(posedge clk) begin

        // Drive serial counter
        if (state == STATE_IDLE) begin
            serial_counter <= SERIAL_COUNTER_VALUE/2;
        end else if (serial_strobe) begin
            serial_counter <= SERIAL_COUNTER_VALUE;
        end else begin
            serial_counter <= serial_counter-1;
        end

        // Drive states and shifting
        case (state)
            
            STATE_IDLE: begin
              if (rx_reg[2:0]==3'b001) begin
                    state          <= STATE_START;
                    shift_counter  <= DATA_BITS-1;
                    shift_register <= shift_register;
                end
            end

            STATE_START: begin
                if (serial_strobe) begin
                    state          <= STATE_RX;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

            STATE_RX: begin
                if (serial_strobe) begin
                    state          <= (shift_counter == 0) ? STATE_DONE     : STATE_RX;
                    shift_counter  <= (shift_counter == 0) ? DATA_BITS - 1  : shift_counter - 1;
                    shift_register <= {rx_reg[0], shift_register[7:1]};
                end
            end

            STATE_DONE: begin
                if (receive) begin
                    state          <= receive ? STATE_IDLE : STATE_START;
                    shift_counter  <= shift_counter;
                    shift_register <= shift_register;
                end
            end

        endcase
    end

    assign valid         = (state == STATE_DONE);
    assign serial_strobe = (serial_counter == 0);
    assign rx_byte       = shift_register;

endmodule