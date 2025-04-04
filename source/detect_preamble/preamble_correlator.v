`define XILINX_SYNTH

// module preamble_correlator #(
//     parameter       LENGTH = 64,
//     parameter       BANKS  = 16,
//     parameter       SCALING_BITS = 10
// )(
//     input  wire                         clk,
//     input  wire                         rst,
//     input  wire                         in_dat, 
//     input  wire                         in_vld,
//     output reg  [CORR_WIDTH*BANKS-1:0]  corr_dat,
//     output reg                          corr_vld,
//     output wire                         all_zeros
// );
//     localparam CORR_WIDTH = $clog2(LENGTH+1);

//     integer i;
//     integer j;

//     reg [LENGTH-1:0] shift_register = 0;
//     reg [LENGTH-1:0]        correlator_coeffs [BANKS-1:0];
//     reg [CORR_WIDTH-1:0]    correlator_lengths [BANKS-1:0];
//     reg [SCALING_BITS-1:0]  correlator_scaling [BANKS-1:0];

//     reg [CORR_WIDTH*BANKS-1:0]                  corr;
//     reg [(CORR_WIDTH+2*SCALING_BITS)*BANKS-1:0] product;

//     `ifdef XILINX_SYNTH
//     initial begin
//         $readmemb("preamble_correlator_coeffs.mem", correlator_coeffs);
//         $readmemb("preamble_correlator_lengths.mem", correlator_lengths);
//         $readmemb("preamble_correlator_scaling.mem", correlator_scaling);
//     end
//     `else
//     initial begin
//         $readmemb("../source/detect_preamble/preamble_correlator_coeffs.mem", correlator_coeffs);
//         $readmemb("../source/detect_preamble/preamble_correlator_lengths.mem", correlator_lengths);
//         $readmemb("../source/detect_preamble/preamble_correlator_scaling.mem", correlator_scaling);
//     end
//     `endif

//     always @(posedge clk) begin
//         if (rst) begin
//             shift_register <= 0;
//             corr_vld <= 0;
//         end else begin
//             if (in_vld) begin
//                 shift_register <= {shift_register[LENGTH-2:0], in_dat};
//             end
//             corr_vld <= in_vld;
//         end
//     end

//     always@(*) begin
//         for (i=0; i<BANKS; i=i+1) begin
//             corr[i*CORR_WIDTH+:CORR_WIDTH] = 0;
//             for (j=0; j<LENGTH; j=j+1)
//                 if (shift_register[j] == correlator_coeffs[i][j] && j < correlator_lengths[i])
//                     corr[i*CORR_WIDTH+:CORR_WIDTH]=corr[i*CORR_WIDTH+:CORR_WIDTH]+1;
//             product[i*(CORR_WIDTH+2*SCALING_BITS)+:(CORR_WIDTH+2*SCALING_BITS)] = (corr[i*CORR_WIDTH+:CORR_WIDTH]<<(SCALING_BITS-1))*correlator_scaling[i];
//             corr_dat[i*CORR_WIDTH+:CORR_WIDTH] = product[i*(CORR_WIDTH+2*SCALING_BITS)+:(CORR_WIDTH+2*SCALING_BITS)]>>((SCALING_BITS-1)*2);
//         end
//     end

//     assign all_zeros =  ~| shift_register[(LENGTH/3):0];

// endmodule

module preamble_correlator #(
    parameter       LENGTH = 64,
    parameter       BANKS  = 16,
    parameter       SCALING_BITS = 5
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         in_dat, 
    input  wire                         in_vld,
    output reg [CORR_WIDTH*BANKS-1:0]   corr_dat,
    output reg                          corr_vld,
    output wire                         all_zeros
);
    localparam CORR_WIDTH = $clog2(LENGTH+1);

    integer i;
    integer j;
    integer k;

    reg [LENGTH-1:0] shift_register = 0;
    reg [LENGTH-1:0]        correlator_coeffs [BANKS-1:0];
    reg [CORR_WIDTH-1:0]    correlator_lengths [BANKS-1:0];
    reg [SCALING_BITS-1:0]  correlator_scaling [BANKS-1:0];

    reg [3:0] vld_reg;

    `ifdef XILINX_SYNTH
    initial begin
        $readmemb("preamble_correlator_coeffs.mem", correlator_coeffs);
        $readmemb("preamble_correlator_lengths.mem", correlator_lengths);
        $readmemb("preamble_correlator_scaling.mem", correlator_scaling);
    end
    `else
    initial begin
        $readmemb("../source/detect_preamble/preamble_correlator_coeffs.mem", correlator_coeffs);
        $readmemb("../source/detect_preamble/preamble_correlator_lengths.mem", correlator_lengths);
        $readmemb("../source/detect_preamble/preamble_correlator_scaling.mem", correlator_scaling);
    end
    `endif
    
    reg [LENGTH-1:0] xnored_wire [BANKS-1:0];
    reg [LENGTH-1:0] xnored_reg  [BANKS-1:0];

    reg [CORR_WIDTH-1:0] added_wire [BANKS-1:0];
    reg [CORR_WIDTH-1:0] added_reg  [BANKS-1:0];

    reg [CORR_WIDTH+2*SCALING_BITS:0] scaled_wire [BANKS-1:0];
    reg [CORR_WIDTH-1:0] scaled_reg  [BANKS-1:0];

    always@(*) begin
        for (i=0; i<BANKS; i=i+1) begin
            xnored_wire[i] = shift_register ~^ correlator_coeffs[i];
        end

        for (i=0; i<BANKS; i=i+1) begin
            added_wire[i] = 0;
            for (j=0; j<correlator_lengths[i]; j=j+1) begin
                added_wire[i] = added_wire[i] + xnored_reg[i][j];
            end
        end

        for (i=0; i<BANKS; i=i+1) begin
            scaled_wire[i] = (added_reg[i]<<(SCALING_BITS-1))*correlator_scaling[i];
        end

        for (i=0; i<BANKS; i=i+1) begin
            corr_dat[i*CORR_WIDTH+:CORR_WIDTH] = scaled_reg[i];
        end
        corr_vld = vld_reg[0];
    end

    always@(posedge clk) begin
        if (rst) begin
            shift_register <= 0;
            vld_reg <= 0;
            for (k=0; k<BANKS; k=k+1) begin
                xnored_reg[k] <= 0;
                added_reg[k] <= 0;
                scaled_reg[k] <= 0;
            end
        end else begin
            if (in_vld) shift_register <= {shift_register[LENGTH-2:0], in_dat};
            vld_reg <= {in_vld, vld_reg[3:1]};
            for (k=0; k<BANKS; k=k+1) begin
                xnored_reg[k] <= xnored_wire[k];
                added_reg[k] <= added_wire[k];
                scaled_reg[k] <= scaled_wire[k] >> ((SCALING_BITS-1)*2);
            end
        end
    end
    
    assign all_zeros =  ~| shift_register[(LENGTH/3):0];

endmodule