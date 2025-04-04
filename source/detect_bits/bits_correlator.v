// `define XILINX_SYNTH

module bits_correlator #(
    parameter       LENGTH    = 64,
    parameter       BANKS     = 16
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_dat, 
    input  wire                    in_vld,
    input  wire [BANK_WIDTH-1:0]   frequency_bank,
    output wire [CORR_WIDTH*4-1:0] corr_dat,
    output reg                     corr_vld
);
    localparam BANK_WIDTH = $clog2(BANKS);
    localparam CORR_WIDTH = $clog2(LENGTH+1);

    reg [LENGTH-1:0]        shift_register = 0;
    reg [LENGTH-1:0]        correlator_coeffs [BANKS-1:0];
    reg [CORR_WIDTH-1:0]    correlator_lengths [BANKS-1:0];
    reg [CORR_WIDTH-1:0]  s1_correlation;
    reg [CORR_WIDTH-1:0]  s2_correlation;
    reg [CORR_WIDTH-1:0]  s3_correlation;
    reg [CORR_WIDTH-1:0]  s4_correlation;

    integer j;

    `ifdef XILINX_SYNTH
    initial begin
        $readmemb("bits_correlator_coeffs.mem", correlator_coeffs);
        $readmemb("bits_correlator_lengths.mem", correlator_lengths);
    end
    `else
    initial begin
        $readmemb("../source/detect_bits/bits_correlator_coeffs.mem", correlator_coeffs);
        $readmemb("../source/detect_bits/bits_correlator_lengths.mem", correlator_lengths);
    end
    `endif

    always @(posedge clk) begin
        if (rst) begin
            shift_register <= 0;
            corr_vld <= 0;
        end else begin
            if (in_vld) begin
                shift_register <= {shift_register[LENGTH-2:0], in_dat};
            end
            corr_vld <= in_vld;
        end
    end

    always@(*) begin
        s1_correlation = 0;
        s2_correlation = 0;
        s3_correlation = 0;
        s4_correlation = 0;
        for (j=0; j<LENGTH; j=j+1) begin
            if (j < correlator_lengths[frequency_bank]) begin
                s1_correlation = s1_correlation + shift_register[j];
                s2_correlation = s2_correlation + (shift_register[j] == correlator_coeffs[frequency_bank][j]);
                s3_correlation = s3_correlation + (shift_register[j] != correlator_coeffs[frequency_bank][j]);
                s4_correlation = s4_correlation + !shift_register[j];
            end
        end
    end

    assign corr_dat = {s4_correlation, s3_correlation, s2_correlation, s1_correlation};

endmodule