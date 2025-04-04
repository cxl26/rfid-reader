// `define XILINX_SYNTH

module bits_detector #(
    parameter       LENGTH   = 4,
    parameter       BANKS    = 4,
    parameter       EL_GATES = 1
)(
    input  wire clk,
    input  wire rst,
    input  wire in_dat, 
    input  wire in_vld,
    input  wire [BANK_WIDTH-1:0] frequency_bank,
    output wire out_dat,
    output wire out_vld
);

    localparam BANK_WIDTH = $clog2(BANKS);
    localparam CORR_WIDTH = $clog2(LENGTH+1);

    reg [CORR_WIDTH-1:0]   correlator_lengths [BANKS-1:0];

    `ifdef XILINX_SYNTH
    initial begin
        $readmemb("bits_correlator_lengths.mem", correlator_lengths);
    end
    `else
    initial begin
        $readmemb("../source/detect_bits/bits_correlator_lengths.mem", correlator_lengths);
    end
    `endif

    reg  [CORR_WIDTH+EL_GATES:0]  count = 0;
    reg                           valid = 0;

    reg update_bit_symbol = 0;
    reg update_bit_period = 0;

    reg [BANK_WIDTH-1:0] frequency_bank_reg = 0;

    reg [1:0]                   bit_symbol = 0;
    reg [CORR_WIDTH+EL_GATES:0] bit_period = 0;

    reg [CORR_WIDTH*4-1:0] ontime_corr;
    reg [CORR_WIDTH*4-1:0] late_corr;
    reg [CORR_WIDTH*4-1:0] erly_corr;

    wire [CORR_WIDTH*4-1:0] corr_dat;
    wire                    corr_vld;

    localparam S1 = 2'd0;
    localparam S2 = 2'd1;
    localparam S3 = 2'd2;
    localparam S4 = 2'd3;
    reg [1:0] max_symbol; // combinational, not register

    localparam ONTIME = 2'b00;
    localparam LATE   = 2'b01;
    localparam ERLY   = 2'b11;
    reg [1:0] max_sample; // combinational, not register

    wire ontime_strobe;
    wire late_strobe;
    wire erly_strobe;

    // Generate sampling timing strobes based on count
    assign ontime_strobe = (count == bit_period-1) && corr_vld;
    assign late_strobe   = (count == EL_GATES-1) && corr_vld;
    assign erly_strobe   = (count == bit_period-EL_GATES-1) && corr_vld;

    // Generate output valid and data signals
    assign out_vld = valid;
    assign out_dat = (bit_symbol == 2'd0 || bit_symbol == 2'd3);

    // Instantiate bits correlator bank
    bits_correlator #(
       .LENGTH(LENGTH),
       .BANKS(BANKS)
    ) bits_correlator_u1 (
        .clk(clk),
        .rst(rst),
        .in_dat(in_dat),
        .in_vld(in_vld),
        .frequency_bank(frequency_bank_reg),
        .corr_dat(corr_dat),
        .corr_vld(corr_vld)
    );

    // Determine max symbol combinationally
    always @(*) begin
        // S1 Symbol
        if (
            ontime_corr[0+:CORR_WIDTH] >= ontime_corr[1*CORR_WIDTH+:CORR_WIDTH]
            && ontime_corr[0+:CORR_WIDTH] >= ontime_corr[2*CORR_WIDTH+:CORR_WIDTH]
            && ontime_corr[0+:CORR_WIDTH] >= ontime_corr[3*CORR_WIDTH+:CORR_WIDTH]
        ) begin
            max_symbol = S1;
        // S2 Symbol
        end else if (
            ontime_corr[CORR_WIDTH+:CORR_WIDTH] >= ontime_corr[2*CORR_WIDTH+:CORR_WIDTH]
            && ontime_corr[CORR_WIDTH+:CORR_WIDTH] >= ontime_corr[3*CORR_WIDTH+:CORR_WIDTH]
        ) begin
            max_symbol = S2;
        // S3 Symbol
        end else if (
            ontime_corr[2*CORR_WIDTH+:CORR_WIDTH] >= ontime_corr[3*CORR_WIDTH+:CORR_WIDTH]
        ) begin
            max_symbol = S3;
        // S4 Symbol
        end else begin
            max_symbol = S4;
        end
    end

    // Determine max sample combinationally
    always @(*) begin
        // Ontime Sample
        if (
            ontime_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH] >= erly_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH]
            && ontime_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH] >= late_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH]
        ) begin
            max_sample = ONTIME;
        // Late Sample
        end else if (
            late_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH] >= erly_corr[bit_symbol*CORR_WIDTH+:CORR_WIDTH]
        ) begin
            max_sample = LATE;
        // Early Sample
        end else begin
            max_sample = ERLY;
        end
    end

    // Update correlation registers, symbol, period, and count sequentially
    always @(posedge clk) begin
        if (rst) begin
            // Reset count and valid registers
            count <= 0;
            valid <= 0;

            // Reset bit symbol registers
            bit_symbol <= 0;
            update_bit_symbol <= 0;

            // Reset bit period registers
            bit_period <= correlator_lengths[frequency_bank];
            update_bit_period <= 0;
            frequency_bank_reg <= frequency_bank;

            // Reset correlation registers
            ontime_corr <= {4*CORR_WIDTH{1'b1}};
            late_corr <= 0;
            erly_corr <= 0;

        end else begin

            // Update count and valid
            if (corr_vld) begin
                count <= (count == bit_period-1) ? 0 : count + 1;
            end
            valid <= update_bit_symbol;

            // Update bit symbol after ontime strobe
            update_bit_symbol <= ontime_strobe;
            if (update_bit_symbol) begin
                bit_symbol <= max_symbol;
            end

            // Update bit period after late strobe
            update_bit_period <= late_strobe;
            if (update_bit_period) begin
                case (max_sample)
                    LATE:    bit_period <= bit_period + EL_GATES;
                    ERLY:    bit_period <= bit_period - EL_GATES;
                    default: bit_period <= bit_period;
                endcase
            end

            // Sample ontime, late, early correlations
            if (ontime_strobe) ontime_corr <= corr_dat;
            if (late_strobe) late_corr <= corr_dat;
            if (erly_strobe) erly_corr <= corr_dat;

        end
    end

endmodule