module preamble_correlator #(
    parameter       LENGTH = 64,
    parameter       BANKS  = 16,
    parameter       SCALING_BITS = 10
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

    integer i;
    integer j;

    reg [LENGTH-1:0] shift_register = 0;
    reg [LENGTH-1:0]        correlator_coeffs [BANKS-1:0];
    reg [CORR_WIDTH-1:0]    correlator_lengths [BANKS-1:0];
    reg [SCALING_BITS-1:0]  correlator_scaling [BANKS-1:0];

    reg [CORR_WIDTH*BANKS-1:0]                  corr;
    reg [(CORR_WIDTH+2*SCALING_BITS)*BANKS-1:0] product;

    initial begin
        $readmemb("../source/detect_preamble/correlator_coeffs.txt", correlator_coeffs);
        $readmemb("../source/detect_preamble/correlator_lengths.txt", correlator_lengths);
        $readmemb("../source/detect_preamble/correlator_scaling.txt", correlator_scaling);
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

        for (i=0; i<BANKS; i=i+1) begin
            corr[i*CORR_WIDTH+:CORR_WIDTH] = 0;
            for (j=0; j<LENGTH; j=j+1)
                if (shift_register[j] == correlator_coeffs[i][j] && j < correlator_lengths[i])
                    corr[i*CORR_WIDTH+:CORR_WIDTH]=corr[i*CORR_WIDTH+:CORR_WIDTH]+1;
            product[i*(CORR_WIDTH+2*SCALING_BITS)+:(CORR_WIDTH+2*SCALING_BITS)] = (corr[i*CORR_WIDTH+:CORR_WIDTH]<<(SCALING_BITS-1))*correlator_scaling[i];
            corr_dat[i*CORR_WIDTH+:CORR_WIDTH] = product[i*(CORR_WIDTH+2*SCALING_BITS)+:(CORR_WIDTH+2*SCALING_BITS)]>>((SCALING_BITS-1)*2);
        end
    end

    assign all_zeros =  ~| shift_register[(LENGTH/3):0];

endmodule