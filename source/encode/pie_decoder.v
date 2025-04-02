module pie_decoder
#(
    parameter ONE_PERIOD = 10, // Same as encoder
    parameter ZERO_PERIOD = 6,
    parameter RTCAL = 16,
    parameter TRCAL = 32,
    parameter DELIMITER = 3
) (
    input  wire         clk,        // Clock signal
    input  wire         rst,        // Reset signal
    input  wire         in_pie,     // PIE encoded input signal
    output reg          out_bit,    // Decoded binary output
    output reg          out_valid   // Output valid flag
);

    localparam COUNT_WIDTH = $clog2(TRCAL);

    // State encoding
    localparam STATE_IDLE      = 3'd0;
    localparam STATE_MEASURE   = 3'd1;
    localparam STATE_DECODE    = 3'd2;

    reg [2:0] state = STATE_IDLE;
    reg [COUNT_WIDTH-1:0] count = 0;
    reg in_pie_d; // Delayed version for edge detection
    reg sample_ready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            count <= 0;
            out_bit <= 0;
            out_valid <= 0;
            in_pie_d <= 0;
        end else begin
            in_pie_d <= in_pie; // Edge detection

            case (state)
                STATE_IDLE: begin
                    count <= 0;
                    out_valid <= 0;
                    if (in_pie != in_pie_d) // Detect first transition
                        state <= STATE_MEASURE;
                end
                
                STATE_MEASURE: begin
                    count <= count + 1;
                    if (in_pie != in_pie_d) begin // Edge detected
                        sample_ready <= 1;
                        state <= STATE_DECODE;
                    end
                end

                STATE_DECODE: begin
                    sample_ready <= 0;
                    out_valid <= 1;

                    if (count >= ONE_PERIOD - 2 && count <= ONE_PERIOD + 2) 
                        out_bit <= 1;  // Long-high = 1
                    else if (count >= ZERO_PERIOD - 2 && count <= ZERO_PERIOD + 2)
                        out_bit <= 0;  // Short-high = 0

                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule