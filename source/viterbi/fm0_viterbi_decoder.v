module fm0_viterbi_decoder #(
    parameter integer CORR_WIDTH      = 8,
    parameter integer TRACEBACK_DEPTH = 5
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [4*CORR_WIDTH-1:0]  corr_dat,
    input  wire                     corr_vld,
    output wire [TRACEBACK_DEPTH-1:0] out_dat,
    output wire                     out_vld
);
    // Derive metric width: enough bits to accumulate TRACEBACK_DEPTH correlations
    localparam integer NUM_STATES   = 4;
    localparam integer METRIC_WIDTH = CORR_WIDTH + $clog2(TRACEBACK_DEPTH) + 1;
    
    // Internal interconnect signals
    wire [NUM_STATES*METRIC_WIDTH-1:0] path_metrics;    // current metrics from PMU to ACSU and STBU
    wire [NUM_STATES*METRIC_WIDTH-1:0] new_metrics;     // new metrics output from ACSU to PMU
    wire [NUM_STATES-1:0]             decisions;        // 4-bit decisions from ACSU to STBU

    // Instantiate Path Metrics Unit (PMU)
    fm0_pmu #(
        .METRIC_WIDTH(METRIC_WIDTH),
        .NUM_STATES(NUM_STATES)
    ) u_pmu (
        .clk         (clk),
        .rst         (rst),
        .corr_vld    (corr_vld),
        .metrics_in  (new_metrics),
        .metrics_out (path_metrics)
    );

    // Instantiate Add Compare Select Unit (ACSU)
    fm0_acsu #(
        .CORR_WIDTH(CORR_WIDTH),
        .METRIC_WIDTH(METRIC_WIDTH),
        .NUM_STATES(NUM_STATES)
    ) u_acsu (
        .metrics_in   (path_metrics),
        .corr_dat     (corr_dat),
        .metrics_out  (new_metrics),
        .decisions_out(decisions)
    );

    // Instantiate Survivor Traceback Unit (STBU)
    fm0_stbu #(
        .TRACEBACK_DEPTH(TRACEBACK_DEPTH),
        .METRIC_WIDTH   (METRIC_WIDTH),
        .NUM_STATES     (NUM_STATES)
    ) u_stbu (
        .clk         (clk),
        .rst         (rst),
        .corr_vld    (corr_vld),
        .decisions_in(decisions),
        .metrics_in  (path_metrics),
        .out_dat     (out_dat),
        .out_vld     (out_vld)
    );

endmodule
