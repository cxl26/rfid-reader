module pie_decoder
#(
    parameter PW = 2,                     // Pulse width (same as encoder)
    parameter ONE_PERIOD = 10,            // Same as encoder
    parameter ZERO_PERIOD = 6,            // Same as encoder
    parameter RTCAL = 16,                 // Same as encoder
    parameter TRCAL = 32,                 // Same as encoder
    parameter DELIMITER = 3,              // Same as encoder
    parameter SYNC_THRESHOLD = 2          // Tolerance for symbol detection
) (
    input  wire        clk,               // Clock signal
    input  wire        rst,               // Reset signal (synchronous)
    input  wire        in_pie,            // PIE encoded input
    output reg         out_bit,           // Decoded binary output
    output reg         out_valid,         // Valid output indicator
    output reg         preamble_detected, // Preamble detection flag
    output reg         frame_sync_done    // Frame sync completion flag
);

    // State encoding using localparam
    localparam STATE_IDLE            = 3'd0;
    localparam STATE_DELIMITER_DETECT = 3'd1;
    localparam STATE_SYNC_ZERO_DETECT = 3'd2;
    localparam STATE_RTCAL_DETECT    = 3'd3;
    localparam STATE_TRCAL_DETECT    = 3'd4;
    localparam STATE_DATA_DECODE     = 3'd5;
    
    // State registers
    reg [2:0] state = STATE_IDLE;
    reg [2:0] next_state;
    
    // Timing counters
    reg [31:0] pulse_counter = 0;
    reg [31:0] space_counter = 0;
    reg [31:0] symbol_counter = 0;
    reg        last_in_pie;
    
    // Timing thresholds (with tolerance)
    localparam DELIMITER_MIN = DELIMITER - SYNC_THRESHOLD;
    localparam DELIMITER_MAX = DELIMITER + SYNC_THRESHOLD;
    localparam ZERO_MIN = ZERO_PERIOD - SYNC_THRESHOLD;
    localparam ZERO_MAX = ZERO_PERIOD + SYNC_THRESHOLD;
    localparam ONE_MIN = ONE_PERIOD - SYNC_THRESHOLD;
    localparam ONE_MAX = ONE_PERIOD + SYNC_THRESHOLD;
    localparam RTCAL_MIN = RTCAL - SYNC_THRESHOLD;
    localparam RTCAL_MAX = RTCAL + SYNC_THRESHOLD;
    localparam TRCAL_MIN = TRCAL - SYNC_THRESHOLD;
    localparam TRCAL_MAX = TRCAL + SYNC_THRESHOLD;

    // Edge detection
    wire rising_edge = in_pie && !last_in_pie;
    wire falling_edge = !in_pie && last_in_pie;
    
    // Symbol detection
    wire is_delimiter = (space_counter >= DELIMITER_MIN) && (space_counter <= DELIMITER_MAX);
    wire is_zero = (symbol_counter >= ZERO_MIN) && (symbol_counter <= ZERO_MAX);
    wire is_one = (symbol_counter >= ONE_MIN) && (symbol_counter <= ONE_MAX);
    wire is_rtcal = (symbol_counter >= RTCAL_MIN) && (symbol_counter <= RTCAL_MAX);
    wire is_trcal = (symbol_counter >= TRCAL_MIN) && (symbol_counter <= TRCAL_MAX);

    // Synchronous state machine
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            pulse_counter <= 0;
            space_counter <= 0;
            symbol_counter <= 0;
            last_in_pie <= 0;
            out_bit <= 0;
            out_valid <= 0;
            preamble_detected <= 0;
            frame_sync_done <= 0;
        end else begin
            state <= next_state;
            last_in_pie <= in_pie;
            
            // Count pulse and space durations
            if (in_pie) begin
                pulse_counter <= pulse_counter + 1;
                space_counter <= 0;
            end else begin
                space_counter <= space_counter + 1;
                pulse_counter <= 0;
            end
            
            // Count complete symbol duration (pulse + space)
            if (rising_edge || falling_edge) begin
                symbol_counter <= pulse_counter + space_counter;
            end
            
            // Output control
            out_valid <= 0;
            if (state == STATE_DATA_DECODE && falling_edge) begin
                if (is_zero) begin
                    out_bit <= 0;
                    out_valid <= 1;
                end else if (is_one) begin
                    out_bit <= 1;
                    out_valid <= 1;
                end
            end
            
            // Preamble and frame sync flags
            preamble_detected <= (state == STATE_RTCAL_DETECT) || 
                                (state == STATE_TRCAL_DETECT) || 
                                (state == STATE_DATA_DECODE);
            frame_sync_done <= (state == STATE_DATA_DECODE);
        end
    end

    // Combinational next state logic
    always @(*) begin
        // Default to current state
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (in_pie) begin
                    next_state = STATE_DELIMITER_DETECT;
                end
            end
            
            STATE_DELIMITER_DETECT: begin
                if (falling_edge && is_delimiter) begin
                    next_state = STATE_SYNC_ZERO_DETECT;
                end else if (!in_pie && (space_counter > DELIMITER_MAX)) begin
                    next_state = STATE_IDLE;
                end
            end
            
            STATE_SYNC_ZERO_DETECT: begin
                if (falling_edge) begin
                    if (is_zero) begin
                        next_state = STATE_RTCAL_DETECT;
                    end else begin
                        next_state = STATE_IDLE;
                    end
                end
            end
            
            STATE_RTCAL_DETECT: begin
                if (falling_edge) begin
                    if (is_rtcal) begin
                        next_state = STATE_TRCAL_DETECT;
                    end else begin
                        next_state = STATE_IDLE;
                    end
                end
            end
            
            STATE_TRCAL_DETECT: begin
                if (falling_edge) begin
                    if (is_trcal) begin
                        next_state = STATE_DATA_DECODE;
                    end else begin
                        next_state = STATE_IDLE;
                    end
                end
            end
            
            STATE_DATA_DECODE: begin
                // Stay in this state until loss of signal
                if (space_counter > ONE_MAX * 2) begin
                    next_state = STATE_IDLE;
                end
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end

endmodule