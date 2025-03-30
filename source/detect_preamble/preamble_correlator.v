module preamble_correlator #(
    parameter       LENGTH = 64,
    parameter       BANKS  = 16
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         in_dat, 
    input  wire                         in_vld,
    output reg  [CORR_WIDTH*BANKS-1:0]  corr_dat,
    output reg                          corr_vld,
    output wire                         all_zeros
);
    localparam CORR_WIDTH = $clog2(LENGTH+1);

    reg [LENGTH-1:0] shift_register = 0;
    reg [LENGTH-1:0]        correlator_coeffs [BANKS-1:0];
    reg [CORR_WIDTH-1:0]    correlator_lengths [BANKS-1:0];

    initial begin
        $readmemb("../source/detect_preamble/correlator_coeffs.txt", correlator_coeffs);
        $readmemb("../source/detect_preamble/correlator_lengths.txt", correlator_lengths);
    end

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
        integer i, j;
        for (i=0; i<BANKS; i=i+1) begin
            corr_dat[i*CORR_WIDTH+:CORR_WIDTH] = 0;
            for (j=0; j<LENGTH; j=j+1)
                if (shift_register[j] == correlator_coeffs[i][j] && j < correlator_lengths[i])
                    corr_dat[i*CORR_WIDTH+:CORR_WIDTH]=corr_dat[i*CORR_WIDTH+:CORR_WIDTH]+1;
        end
    end

    assign all_zeros =  ~| shift_register[(LENGTH/2):0];

endmodule