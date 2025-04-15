module fm0_acsu #(
    parameter integer CORR_WIDTH   = 8,   // Bit-width of each correlation value
    parameter integer METRIC_WIDTH = 10,  // Bit-width of path metrics
    parameter integer NUM_STATES   = 4    // Number of states (fixed 4 for FM0)
)(
    input  wire [NUM_STATES*METRIC_WIDTH-1:0] metrics_in,  // Previous path metrics from PMU
    input  wire [4*CORR_WIDTH-1:0]           corr_dat,     // 4 correlation values (for 4 FM0 branches)
    output reg  [NUM_STATES*METRIC_WIDTH-1:0] metrics_out, // Updated path metrics for each state
    output reg  [NUM_STATES-1:0]             decisions_out // Survivor decisions for each state (1 bit per state)
);
    // Internal signals: extract previous metrics and correlation values for clarity
    reg [METRIC_WIDTH-1:0] pm [0:NUM_STATES-1];   // previous metrics for states 0..3
    reg [METRIC_WIDTH-1:0] new_pm [0:NUM_STATES-1]; // new metrics to calculate
    reg [CORR_WIDTH-1:0]   corr_val [0:NUM_STATES-1]; // correlation values for branches 0+,...,1-
    
    // Unpack input buses for ease of use
    integer i;
    always @* begin
        // Previous path metrics (unpacked from metrics_in)
        pm[0] = metrics_in[METRIC_WIDTH-1:0];
        pm[1] = metrics_in[2*METRIC_WIDTH-1:METRIC_WIDTH];
        pm[2] = metrics_in[3*METRIC_WIDTH-1:2*METRIC_WIDTH];
        pm[3] = metrics_in[4*METRIC_WIDTH-1:3*METRIC_WIDTH];
        // Correlation values for the 4 possible symbol patterns (0+,1+,0-,1-)
        corr_val[0] = corr_dat[CORR_WIDTH-1:0]; 
        corr_val[1] = corr_dat[2*CORR_WIDTH-1:CORR_WIDTH];
        corr_val[2] = corr_dat[3*CORR_WIDTH-1:2*CORR_WIDTH];
        corr_val[3] = corr_dat[4*CORR_WIDTH-1:3*CORR_WIDTH];
        
        // Compute new metrics and decisions for each state:
        // State 0 (0+): can come from state2 (0-) or state3 (1-) with input=0
        //   Compare pm[2] + corr(0+) vs pm[3] + corr(0+)
        if ((pm[2] + corr_val[0]) >= (pm[3] + corr_val[0])) begin
            new_pm[0] = pm[2] + corr_val[0];
            decisions_out[0] = 1'b0;  // 0 -> chose prev state2 (0-)
        end else begin
            new_pm[0] = pm[3] + corr_val[0];
            decisions_out[0] = 1'b1;  // 1 -> chose prev state3 (1-)
        end

        // State 1 (1+): can come from state2 (0-) or state3 (1-) with input=1
        if ((pm[2] + corr_val[1]) >= (pm[3] + corr_val[1])) begin
            new_pm[1] = pm[2] + corr_val[1];
            decisions_out[1] = 1'b0;  // chose prev state2 (0-)
        end else begin
            new_pm[1] = pm[3] + corr_val[1];
            decisions_out[1] = 1'b1;  // chose prev state3 (1-)
        end

        // State 2 (0-): can come from state0 (0+) or state1 (1+) with input=0
        if ((pm[0] + corr_val[2]) >= (pm[1] + corr_val[2])) begin
            new_pm[2] = pm[0] + corr_val[2];
            decisions_out[2] = 1'b0;  // chose prev state0 (0+)
        end else begin
            new_pm[2] = pm[1] + corr_val[2];
            decisions_out[2] = 1'b1;  // chose prev state1 (1+)
        end

        // State 3 (1-): can come from state0 (0+) or state1 (1+) with input=1
        if ((pm[0] + corr_val[3]) >= (pm[1] + corr_val[3])) begin
            new_pm[3] = pm[0] + corr_val[3];
            decisions_out[3] = 1'b0;  // chose prev state0 (0+)
        end else begin
            new_pm[3] = pm[1] + corr_val[3];
            decisions_out[3] = 1'b1;  // chose prev state1 (1+)
        end

        // Pack new path metrics into output bus
        metrics_out = { new_pm[3], new_pm[2], new_pm[1], new_pm[0] };
        // decisions_out bus already constructed above for each state
    end

endmodule
