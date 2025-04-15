module fm0_stbu #(
    parameter integer TRACEBACK_DEPTH = 5,   // Number of bits to decode (traceback length)
    parameter integer METRIC_WIDTH    = 10,  // Bit-width of path metrics
    parameter integer NUM_STATES      = 4    // Number of states (fixed 4 for FM0)
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   corr_vld,        // Valid signal for incoming decisions
    input  wire [NUM_STATES-1:0]  decisions_in,    // Survivor decisions from ACSU (one bit per state)
    input  wire [NUM_STATES*METRIC_WIDTH-1:0] metrics_in, // Current path metrics from PMU
    output reg  [TRACEBACK_DEPTH-1:0] out_dat,     // Decoded output bits (parallel)
    output reg                    out_vld          // Output valid strobe
);
    // Memory to store decisions for each time step [0..TRACEBACK_DEPTH-1].
    // Each entry is a 4-bit vector (one decision bit for each state at that step).
    reg [NUM_STATES-1:0] dec_mem [0:TRACEBACK_DEPTH-1];
    reg [$clog2(TRACEBACK_DEPTH+1)-1:0] ptr;  // pointer (or counter) for steps processed
    reg done;  // indicates that TRACEBACK_DEPTH bits have been collected (ready to output)

    integer i;
    initial begin
        // (Optional) initialize memory to zero to avoid X (not strictly required for functionality)
        for (i = 0; i < TRACEBACK_DEPTH; i = i + 1) dec_mem[i] = {NUM_STATES{1'b0}};
    end

    // Main sequential process for storing decisions and triggering traceback
    always @(posedge clk) begin
        if (rst) begin
            ptr   <= 0;
            done  <= 1'b0;
            out_vld <= 1'b0;
            out_dat <= {TRACEBACK_DEPTH{1'b0}};
        end else begin
            if (!done) begin
                out_vld <= 1'b0;  // not outputting until done
                if (corr_vld) begin
                    // Store incoming decision bits for this time step
                    dec_mem[ptr] <= decisions_in;
                    ptr <= ptr + 1;
                    // If we've reached the traceback depth, mark done (stop collecting more)
                    if (ptr + 1 == TRACEBACK_DEPTH) begin
                        done <= 1'b1;
                    end
                end
            end else begin
                // Perform traceback once when TRACEBACK_DEPTH inputs have been processed
                // Find the best ending state (max path metric) at this point
                reg [METRIC_WIDTH-1:0] best_metric;
                reg [1:0] best_state;  // 2-bit state index (0 to 3)
                reg [1:0] curr_state;
                reg bit_value;
                // Initialize best state selection
                best_metric = {METRIC_WIDTH{1'b0}};
                best_state  = 2'b00;
                // Unpack metrics_in to find largest
                reg [METRIC_WIDTH-1:0] metric_val [0:NUM_STATES-1];
                metric_val[0] = metrics_in[METRIC_WIDTH-1:0];
                metric_val[1] = metrics_in[2*METRIC_WIDTH-1:METRIC_WIDTH];
                metric_val[2] = metrics_in[3*METRIC_WIDTH-1:2*METRIC_WIDTH];
                metric_val[3] = metrics_in[4*METRIC_WIDTH-1:3*METRIC_WIDTH];
                // Determine which state has the maximum metric
                for (i = 0; i < NUM_STATES; i = i + 1) begin
                    if (i == 0 || metric_val[i] > best_metric) begin
                        best_metric = metric_val[i];
                        best_state  = i[1:0];
                    end
                end
                // Trace back through the decision memory
                curr_state = best_state;
                // The output bit sequence will be assembled MSB-first (first bit decoded is highest index)
                for (i = TRACEBACK_DEPTH-1; i >= 0; i = i - 1) begin
                    // The logical value of the current state indicates the decoded bit:
                    // State indices 0 or 2 represent logical '0' (FM0 0+ or 0-), indices 1 or 3 represent logical '1'.
                    if (curr_state == 2'b00 || curr_state == 2'b10) 
                        bit_value = 1'b0;
                    else 
                        bit_value = 1'b1;
                    out_dat[i] = bit_value;
                    // Move to the previous state using stored decision:
                    // If current state is a "plus" state (0 or 1), decision bit chooses between prev minus states 0- or 1-.
                    // If current state is a "minus" state (2 or 3), decision chooses between prev plus states 0+ or 1+.
                    if (curr_state[1] == 1'b0) begin
                        // curr_state 0 or 1 (plus states)
                        // decision 0 -> prev state 2, decision 1 -> prev state 3
                        if (dec_mem[i][curr_state] == 1'b0)
                            curr_state = 2;  // 0- 
                        else 
                            curr_state = 3;  // 1-
                    end else begin
                        // curr_state 2 or 3 (minus states)
                        // decision 0 -> prev state 0, decision 1 -> prev state 1
                        if (dec_mem[i][curr_state] == 1'b0)
                            curr_state = 0;  // 0+ 
                        else 
                            curr_state = 1;  // 1+
                    end
                end
                // Output the traced bits and raise valid flag
                out_vld <= 1'b1;
                // Prevent repeated outputs – here we hold `done` low after output.
                // (Assume a new decode session will be started by resetting the module if needed.)
                done <= 1'b0;
            end
        end
    end

endmodule
