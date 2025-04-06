// `define SIM
// `define LATTICE_SYNTH
`define XILINX_SYNTH

module top # (
    parameter SAMPLING_N = 50,
    parameter BANKS = 9,
    parameter PREAMBLE_MAX_LENGTH = 80,
    parameter SYMBOL_MAX_LENGTH = 13,
    parameter HI_THRESHOLD = 65,
    parameter LO_THRESHOLD = 60,
    parameter SCALING_BITS = 5,
    parameter EL_GATES = 1,
    parameter PW = 200,
    parameter ONE_PERIOD = 875, // PW is 1/3 TARI works
    parameter ZERO_PERIOD = 500,
    parameter RTCAL = 1375,
    parameter TRCAL = 4000,
    parameter DELIMITER = 312
)(
    input       sys_clk, 
    input       sys_rst,
    input wire  pmod1,   // rx_in
    output wire  pmod2,  // tx_out
    output wire  pmod3,  // bit
    output wire  pmod4,  // vld
    output wire  pmod7,  // sample_strobe
    output wire  pmod8,  // preamble_detected
    output wire  pmod9,
    output wire  pmod10
);

    localparam BANK_WIDTH = $clog2(BANKS);

    wire clk;
    wire rst;
    wire rx_in;
    wire tx_out;
    wire sample_strobe;

    assign rx_in = pmod1;
    assign pmod2 = tx_out;
    assign rst = sys_rst;
    assign pmod3 = bits_detector_out_dat;
    assign pmod4 = bits_detector_out_vld;
    assign pmod7 = sample_strobe;
    assign pmod8 = preamble_detected;

    // RX Path Data
    wire sampler_out_dat;
    wire sampler_out_vld;
    wire preamble_detector_out_dat;
    wire preamble_detector_out_vld;
    wire bits_detector_out_dat;
    wire bits_detector_out_vld;

    // TX Path Data
    wire ctrl_fsm_out_dat;
    wire ctrl_fsm_out_rdy;

    wire sending;
    wire receiving;

    wire [BANK_WIDTH-1:0] frequency_bank;

    (* mark_debug = "true" *) wire preamble_detected;

    wire [15:0] crc16_val;
    wire        crc16_chk;

    wire [4:0] crc5_val;
    wire       crc5_chk;

    wire output_pie_preamble;

    `ifdef LATTICE_SYNTH
    // For Lattice Synthesis
    lattice_pll lattice_pll_u1 (
        .clock_in  (sys_clk),
        .clock_out (clk),
        .locked    ()
    );
    `elsif XILINX_SYNTH
     // For Xilinx Synthesis
     xilinx_mmcm xilinx_mmcm_u1 (
         .clk_in1  (sys_clk),
         .clk_out1 (clk),
         .reset    (rst)
     );
    `elsif SIM
    // For simulation
    assign clk = sys_clk;
    `endif

    sampler #(
        .N(SAMPLING_N)
    ) sampler_u1 (
        .clk    (clk),      // Destination clock domain
        .rst    (rst),      // Synchronous reset
        .rx_in  (rx_in),    // Asynchronous input signal
        .out_dat(sampler_out_dat),
        .out_vld(sampler_out_vld),
        .sample_strb(sample_strobe)
    );

    preamble_detector #(
        .LENGTH(PREAMBLE_MAX_LENGTH),
        .BANKS(BANKS),
        .HI_THRESHOLD(HI_THRESHOLD),
        .LO_THRESHOLD(LO_THRESHOLD),
        .SCALING_BITS(SCALING_BITS)
    ) preamble_detector_u1 (
        .clk                (clk),
        .rst                (rst),
        .in_dat             (sampler_out_dat), 
        .in_vld             (sampler_out_vld),
        .out_dat            (preamble_detector_out_dat),
        .out_vld            (preamble_detector_out_vld),
        .frequency_bank     (frequency_bank),
        .preamble_detected  (preamble_detected)
    );

    bits_detector #(
        .LENGTH(SYMBOL_MAX_LENGTH),
        .BANKS(BANKS),
        .EL_GATES(EL_GATES)
    ) bits_detector_u1 (
        .clk            (clk),
        .rst            (preamble_detected || rst),
        .in_dat         (preamble_detector_out_dat), 
        .in_vld         (preamble_detector_out_vld),
        .frequency_bank (frequency_bank),
        .out_dat        (bits_detector_out_dat),
        .out_vld        (bits_detector_out_vld)
    );

    crc16 crc16_u1 (
        .clk    (clk),
        .rst    (preamble_detected || rst),
        .in_dat (bits_detector_out_dat),
        .in_vld (bits_detector_out_vld),
        .crc    (crc16_val),
        .chk    (crc16_chk)
    );

    ctrl_fsm #(
        .RN16_TIMEOUT(500000),
        .EPC_TIMEOUT(5000000),
        .IDLE_TIMEOUT(5000000)
    ) ctrl_fsm_u1 (
        .clk        (clk),
        .rst        (rst),
        .in_dat     (bits_detector_out_dat), 
        .in_vld     (bits_detector_out_vld),
        .crc16_chk  (crc16_chk),
        .crc5_val   (crc5_val),
        .out_dat    (ctrl_fsm_out_dat),
        .out_rdy    (ctrl_fsm_out_rdy),
        .sending    (sending),
        .receiving  (receiving),
        .output_pie_preamble(output_pie_preamble)
    );

    crc5 crc5_u1 (
        .clk    (clk),
        .rst    (!sending || rst),
        .in_dat (ctrl_fsm_out_dat),
        .in_vld (ctrl_fsm_out_rdy),
        .crc    (crc5_val),
        .chk    (crc5_chk)
    );

    pie_encoder
    #(
        .PW         (PW),
        .ONE_PERIOD (ONE_PERIOD), // PW is 1/3 TARI works
        .ZERO_PERIOD(ZERO_PERIOD),
        .RTCAL      (RTCAL),
        .TRCAL      (TRCAL),
        .DELIMITER  (DELIMITER)
    ) pie_encoder_u1 (
        .clk        (clk),
        .rst        (!sending || rst),
        .in_bit     (ctrl_fsm_out_dat),     // Binary input data
        .in_rdy     (ctrl_fsm_out_rdy),
        .out_pie    (tx_out),     // FM0 encoded output
        .output_pie_preamble(output_pie_preamble)
    );

endmodule