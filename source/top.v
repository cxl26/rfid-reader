module top (
    input        sys_clk, 
    output wire  pmod1,  // rx_sof
    output wire  pmod2,  // rx_eof
    output wire  pmod3,  // bit
    output wire  pmod4,  // vld
    input wire  pmod7,  // rx_in
    input wire  pmod8,  // rst
    input wire  pmod9,  // tx_out
    input wire  pmod10
);
    parameter SAMPLING_N = 3;
    parameter BANKS = 16;
    parameter PREAMBLE_MAX_LENGTH = 76;
    parameter SYMBOLS_MAX_LENGTH = 10;
    parameter HI_THRESHOLD = 70;
    parameter LO_THRESHOLD;
    parameter EL_GATES;

    localparam BANK_WIDTH = $clog2(BANKS);
    localparam CORR_WIDTH = $clog2(LENGTH+1);

    wire clk;
    wire rst;

    assign rst = pmod8;
    assign rx_in = pmod7;
    assign pmod1 = rx_sof;
    assign pmod2 = rx_eof;
    assign pmod3 = bits_detector_out_dat;
    assign pmod4 = bits_detector_out_vld;

    // RX Path Data
    wire sampler_out_dat;
    wire sampler_out_vld;
    wire preamble_detector_out_dat;
    wire preamble_detector_out_vld;
    wire bits_detector_out_dat;
    wire bits_detector_out_vld;

    // TX Path Data
    wire ctrl_fsm_out_dat;
    wire ctrl_fsm_out_vld;

    wire [BANK_WIDTH-1:0] frequency_bank;

    wire rx_sof;
    wire rx_eof;

    wire tx_sof;
    wire tx_eof

    wire [15:0] crc16_val;
    wire        crc16_chk;

    wire [4:0] crc5_val;
    wire        crc5_chk;


    pll pll_u1 (
        .clock_in  (sys_clk),
        .clock_out (clk),
        .locked    ()
    );

    sampler #(
        N(SAMPLING_N)
    ) sampler_u1 (
        .clk    (clk),      // Destination clock domain
        .rst    (rst),      // Synchronous reset
        .rx_in  (rx_in),    // Asynchronous input signal
        .out_dat(sampler_out_dat),
        .out_vld(sampler_out_vld)
    );

    preamble_detector #(
        .LENGTH(PREAMBLE_MAX_LENGTH),
        .BANKS(BANKS),
        .HI_THRESHOLD(HI_THRESHOLD),
        .LO_THRESHOLD(LO_THRESHOLD)
    ) preamble_detector_u1 (
        .clk                (clk),
        .rst                (rst),
        .in_dat             (sampler_out_dat), 
        .in_vld             (sampler_out_vld),
        .out_dat            (preamble_detector_out_dat),
        .out_vld            (preamble_detector_out_vld),
        .frequency_bank     (frequency_bank),
        .preamble_detected  (rx_sof),
        .postamble_detected (rx_eof)
    );

    bits_detector #(
        .LENGTH(SYMBOLS_MAX_LENGTH),
        .BANKS(BANKS),
        .EL_GATES(EL_GATES)
    ) bits_detector_u1 (
        .clk            (clk),
        .rst            (rx_sof),
        .in_dat         (preamble_detector_out_dat), 
        .in_vld         (preamble_detector_out_vld),
        .frequency_bank (frequency_bank),
        .out_dat        (bits_detector_out_dat),
        .out_vld        (bits_detector_out_vld)
    );

    crc16 crc16_u1 (
        .clk    (clk),
        .rst    (rx_sof),
        .in_dat (bits_detector_out_dat),
        .in_vld (bits_detector_out_vld),
        .crc,   (crc16_val),
        .chk    (crc16_chk)
    );

    crc5 crc5_u1 (
        .clk    (clk),
        .rst    (tx_sof),
        .in_dat (ctrl_fsm_out_dat),
        .in_vld (ctrl_fsm_out_vld),
        .crc,   (crc5_val),
        .chk    (crc5_chk)
    );

endmodule