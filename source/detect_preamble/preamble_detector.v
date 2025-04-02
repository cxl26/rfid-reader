module preamble_detector #(
    parameter       LENGTH = 4,
    parameter       BANKS  = 4,
    parameter       HI_THRESHOLD = 3,
    parameter       LO_THRESHOLD = 2,
    parameter       SCALING_BITS = 5
)(
    input  wire clk,
    input  wire rst,
    input  wire in_dat, 
    input  wire in_vld,
    output wire out_dat,
    output reg  out_vld, // reg
    output wire [BANK_WIDTH-1:0] frequency_bank,
    output wire preamble_detected,
    output wire postamble_detected
);

    localparam BANK_WIDTH = $clog2(BANKS);
    localparam CORR_WIDTH = $clog2(LENGTH+1);
    localparam COUNT_WIDTH = 15;

    localparam IDLE_STATE = 2'd0; // Idling for preamble
    localparam FIND_STATE = 2'd1; // Finding max correlation
    localparam DATA_STATE = 2'd2; // Outputting data

    reg [1:0]              state = IDLE_STATE; //reg
    reg [1:0]              next_state; // combinational, not a register
    reg [COUNT_WIDTH-1:0]  count = 0; // reg
    reg [COUNT_WIDTH-1:0]  next_count; // combinational, not a register

    reg [COUNT_WIDTH-1:0]  offset  = 0; // reg

    reg [BANK_WIDTH-1:0]   cur_bank; // combinational, not a register
    reg [CORR_WIDTH-1:0]   cur_corr; // combinational, not a register

    reg [BANK_WIDTH-1:0]   max_bank; // reg
    reg [CORR_WIDTH-1:0]   max_corr = 0; // reg

    wire [BANKS*CORR_WIDTH-1:0]  corr_dat;
    wire                         corr_vld;

    integer i;

    wire above_thresh;
    wire below_thresh;
    assign above_thresh = (cur_corr >= HI_THRESHOLD);
    assign below_thresh = (cur_corr <= LO_THRESHOLD);

    wire all_zeros;

    wire push;
    wire pop;
    wire fifo_empty;
    wire fifo_full;

    wire fifo_rst;
    wire fifo_jump;
    wire fifo_jump_error;

    assign preamble_detected = (state == FIND_STATE) && (next_state == DATA_STATE);
    assign postamble_detected = (state == DATA_STATE) && (next_state == IDLE_STATE);
    assign frequency_bank = max_bank;

    preamble_correlator #(
        .LENGTH(LENGTH),
        .BANKS (BANKS),
        .SCALING_BITS (SCALING_BITS)
    ) preamble_correlator_u1 (
        .clk (clk),
        .rst (rst),
        .in_dat (in_dat), 
        .in_vld (in_vld),
        .corr_dat(corr_dat),
        .corr_vld(corr_vld),
        .all_zeros(all_zeros)
    );

    // cur_bank and cur_corr determined (combinational) by taking maximum correlator bank
    always@(*) begin
        cur_bank = 0;
        cur_corr = 0;
        for (i=0; i<BANKS; i=i+1) begin
            if (corr_dat[i*CORR_WIDTH+:CORR_WIDTH] > cur_corr) begin
                cur_bank = i;
                cur_corr = corr_dat[i*CORR_WIDTH+:CORR_WIDTH];
            end
        end
    end

    // max_bank and max_corr updated (sequential) if in FIND_STATE and new valid sample
    always@(posedge clk) begin
        if (rst) begin
            max_corr <= 0;
            max_bank <= 0;
            offset   <= 0;
        end else begin
            if ((state == FIND_STATE || next_state == FIND_STATE) && in_vld && cur_corr > max_corr) begin
                max_corr <= cur_corr;
                max_bank <= cur_bank;
                offset   <= count;
            end else if (state == DATA_STATE) begin
                max_corr <= 0;
                max_bank <= 0;
                offset   <= 0;
            end
        end
    end

    sync_fifo #(
        .ADDR_WIDTH(COUNT_WIDTH),
        .DATA_WIDTH(1)
    ) sync_fifo_u1 (
        .clk(clk),
        .rst(fifo_rst),
        .wr_en(push),
        .rd_en(pop),
        .wr_data(in_dat),
        .rd_data(out_dat),
        .empty(fifo_empty),
        .full(fifo_full),
        .jump (fifo_jump),
        .jump_value (offset),
        .jump_error (fifo_jump_error)
    );

    assign push = in_vld && (state != IDLE_STATE || next_state != IDLE_STATE) && !fifo_full;
    assign pop  = (state == DATA_STATE) && !fifo_empty;

    assign fifo_jump = (state == FIND_STATE && next_state == DATA_STATE);
    assign fifo_rst = (state == IDLE_STATE && next_state == IDLE_STATE); // needs at least 3 cycles of idle state

    // always @(*) if (fifo_jump && fifo_jump_error) $error();

    always@(*) begin
        case(state)
            IDLE_STATE: begin
                next_state = (above_thresh) ? FIND_STATE : IDLE_STATE;
                next_count = 0;
            end
            FIND_STATE: begin
                next_state = (below_thresh) ? DATA_STATE : FIND_STATE;
                next_count = count+push;
            end
            DATA_STATE: begin
                next_state = (all_zeros)    ? IDLE_STATE : DATA_STATE;
                next_count = 0; 
            end
        endcase
    end
    
    always@(posedge clk) begin
        if (rst) begin
            state <= IDLE_STATE;
            count <= 0;
            out_vld <= 0;
        end else begin
            state <= next_state;
            count <= next_count;
            out_vld <= pop;
        end
    end

endmodule