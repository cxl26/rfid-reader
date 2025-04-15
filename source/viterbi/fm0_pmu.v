module fm0_pmu #(
    parameter integer METRIC_WIDTH   = 10,   // Bit-width for path metrics
    parameter integer NUM_STATES     = 4     // Number of trellis states (fixed 4 for FM0)
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     corr_vld,         // Valid signal for metric update
    input  wire [NUM_STATES*METRIC_WIDTH-1:0] metrics_in,  // New metrics from ACSU
    output wire [NUM_STATES*METRIC_WIDTH-1:0] metrics_out  // Stored metrics to ACSU
);
    // Path metric registers for each state
    reg [METRIC_WIDTH-1:0] path_metric [0:NUM_STATES-1];
    integer i;
    
    // On reset, initialize all path metrics to zero (assuming no prior state bias)
    // On valid input, update path metrics with new values from ACSU
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NUM_STATES; i = i + 1) begin
                path_metric[i] <= {METRIC_WIDTH{1'b0}};
            end
        end else if (corr_vld) begin
            // Unpack metrics_in and store into path_metric registers
            path_metric[0] <= metrics_in[METRIC_WIDTH-1:0];
            path_metric[1] <= metrics_in[2*METRIC_WIDTH-1:METRIC_WIDTH];
            path_metric[2] <= metrics_in[3*METRIC_WIDTH-1:2*METRIC_WIDTH];
            path_metric[3] <= metrics_in[4*METRIC_WIDTH-1:3*METRIC_WIDTH];
        end
    end

    // Continuously output the current path metrics (packed into a bus)
    assign metrics_out = {path_metric[3], path_metric[2], path_metric[1], path_metric[0]};

endmodule
