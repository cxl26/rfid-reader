
module top_tb;

    // Common Dut Parameters
    parameter BANKS          = 9;
    parameter SAMPLING_N     = 1;

    // Preamble Dut Parameters
    parameter PREAMBLE_MAX_LENGTH = 80;
    parameter HI_THRESHOLD = 75;
    parameter LO_THRESHOLD = 70;
    parameter SCALING_BITS = 5;

    // Symbol Dut Parameters
    parameter SYMBOL_MAX_LENGTH = 13;
    parameter EL_GATES       = 2;

    // Test Parameters
    parameter ONE_IN_X_FLIPPED = 0;
    parameter PREAMBLE = 80'b1111111111110000011111000000000011111100000000000000001111111111;
    parameter SYM_PERIOD = 4'd11;
    parameter NUM_JUNK = 200;
    parameter NUM_PREA = 80;
    parameter NUM_DATA = 2800;
    parameter NUM_ZERO = NUM_PREA/2+1;
    parameter SEED = 10;

    // Bit Widths
    localparam BANK_WIDTH = $clog2(BANKS);
    localparam SYM_CORR_WIDTH = $clog2(SYMBOL_MAX_LENGTH+1);
    localparam PRE_CORR_WIDTH = $clog2(PREAMBLE_MAX_LENGTH+1);

    // generated signals
    reg        queue [$]; 
    integer    seed = SEED;
    reg        send_bit = 0;
    integer    send_count = 0;
    reg [1:0]  send_state = SEND_ZERO;
    reg [1:0]  next_state = 0;
    reg [1:0]  prev_state = 0;
    localparam SEND_JUNK = 2'd0, SEND_PREA = 2'd1, SEND_DATA = 2'd2, SEND_ZERO = 2'd3;
    reg [NUM_PREA-1:0] preamble = PREAMBLE;

    wire queue_rst;
    wire encoder_rst;

    wire out_dat;
    wire out_vld;
    reg in_dat = 0;
    reg clk;
    reg rst;

    // Instantiate DUT
    top # (
        .SAMPLING_N         (SAMPLING_N),
        .BANKS              (BANKS),
        .PREAMBLE_MAX_LENGTH(PREAMBLE_MAX_LENGTH),
        .SYMBOL_MAX_LENGTH  (SYMBOL_MAX_LENGTH),
        .HI_THRESHOLD       (HI_THRESHOLD),
        .LO_THRESHOLD       (LO_THRESHOLD),
        .SCALING_BITS       (SCALING_BITS),
        .EL_GATES           (EL_GATES)
    ) top_u1 (
        .sys_clk    (clk), 
        .pmod1      (in_dat),  // rx_in
        .pmod2      (1'b0),  // rst
        .pmod3      (out_dat),  // bit
        .pmod4      (out_vld)  // vld
    );

    // Instantiate strobe gen for timing samples
    strb_gen #(
        .N(SAMPLING_N)
    ) strb_gen_u1 (
        .clk(clk),  // Clock input
        .rst(1'b0), // Synchronous reset
        .strobe(send_strobe)   // Strobe output
    );

    // Instantiate FM0 encoder for generating samples
    fm0_encoder fm0_encoder_u1
    (
        .clk       (clk),    // Clock signal
        .rst       (encoder_rst),   // Reset signal
        .sym_period(SYM_PERIOD),
        .in_bit    (send_bit),
        .in_rdy    (send_rdy),
        .out_fm0   (fm0),
        .out_rdy   (send_strobe && (send_state == SEND_DATA))
    );
    assign encoder_rst = next_state != send_state && next_state == SEND_DATA && send_strobe; // reset encoder before sending data
    assign queue_rst   = next_state != send_state && next_state == SEND_ZERO && send_strobe; // reset the queue after data received
    always@(posedge clk) if (encoder_rst) queue.push_back(1'b1);          // encoder is preset with 1 bit
    always@(posedge clk) if (queue_rst) queue.delete();                   // encoder has 1 bit in flight

    // TX Driver Process
    always@(posedge clk) begin
        // Set a random seed
        $urandom(seed);

        // Send bits to encoder
        if (send_rdy) begin
            queue.push_back(send_bit);
            send_bit <= $urandom_range(1,0);
        end

        // Send samples to dut
        if (send_strobe) begin
            prev_state <= send_state;
            send_state <= next_state;
            send_count <= (next_state != send_state) ? 0 : send_count + 1;
            case(send_state)
                SEND_JUNK:  in_dat <= $urandom_range(1,0);
                SEND_PREA:  in_dat <= preamble[NUM_PREA-1-send_count];
                SEND_DATA:  in_dat <= ($urandom_range(ONE_IN_X_FLIPPED,0) == 0) ? !fm0 : fm0; // random sample bit flips
                SEND_ZERO:  in_dat <= 1'b0;
            endcase
        end
    end

    // RX Monitor Process
    always@(posedge clk) begin
        if (out_vld && queue.size()>0) begin
            if (out_dat == queue.pop_front()) begin
                $display ("Correct data: %b, Queue size: %0d, Sim time: %0d", out_dat, queue.size(), $time());
            end else begin
                $display ("Incorrect data: %b, Queue size: %0d, Sim time: %0d", out_dat, queue.size(), $time());
            end
        end
    end

    // State machine transitions
    always @(*) begin
       case(send_state)
            SEND_JUNK: next_state = (send_count == NUM_JUNK-1) ? SEND_PREA : SEND_JUNK;
            SEND_PREA: next_state = (send_count == NUM_PREA-1) ? SEND_DATA : SEND_PREA;
            SEND_DATA: next_state = (send_count == NUM_DATA-1) ? SEND_ZERO : SEND_DATA;
            SEND_ZERO: next_state = (send_count == NUM_ZERO-1) ? SEND_JUNK : SEND_ZERO;
        endcase
    end

    // Clock generator
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        repeat(18000) #5 clk = ~clk;
        $finish;
    end

endmodule
