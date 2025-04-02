`timescale 1ns/1ps

module preamble_detector_tb;

    parameter LENGTH         = 80;
    parameter BANKS          = 9;
    parameter HI_THRESHOLD   = 75;
    parameter LO_THRESHOLD   = 70;
    parameter SCALING_BITS   = 5;

    parameter NUM_JUNK = 200;
    parameter NUM_DATA = 5;
    parameter NUM_ZEROS = LENGTH/2+1;
    parameter PREAMBLE = 80'b1111111111000011110000000011111000000000000011111111;

    localparam BANK_WIDTH = $clog2(BANKS);

    //outputs
    reg out_dat;
    reg out_vld;
    reg [BANK_WIDTH-1:0] frequency_bank;
    reg preamble_detected;
    reg postamble_detected;

    //inputs
    reg  in_dat = 0;
    reg  in_vld = 0;
    reg  clk;

    // generated signals
    reg        queue [$]; 
    reg        rand_data;
    reg [LENGTH-1:0] preamble = PREAMBLE;
    integer    send_count = 0;
    integer    recv_count = 0;
    reg [1:0]  send_state = 0;
    reg [1:0]  next_state = 0;
    localparam SEND_JUNK = 2'd0, SEND_PREA = 2'd1, SEND_DATA = 2'd2, SEND_ZERO = 2'd3;

    // instantiate top dut
    preamble_detector #(
        .LENGTH       (LENGTH),
        .BANKS        (BANKS),
        .HI_THRESHOLD (HI_THRESHOLD),
        .LO_THRESHOLD (LO_THRESHOLD),
        .SCALING_BITS (SCALING_BITS)
    ) preamble_detector_u1 (
        .clk    (clk),
        .rst    (1'b0),
        .in_dat (in_dat), 
        .in_vld (in_vld),
        .out_dat(out_dat),
        .out_vld(out_vld),
        .frequency_bank     (frequency_bank),
        .preamble_detected  (preamble_detected),
        .postamble_detected (postamble_detected)
    );

    always@(posedge clk) begin
        if ($urandom_range(1, 0)) begin
        //if (1'b0) begin
            in_dat <= $random();
            in_vld <= 1'b0;
        end else begin
            rand_data = $random();
            in_vld <= 1'b1;
            send_state <= next_state;
            send_count <= (next_state != send_state) ? 0 : send_count + 1;
            case(send_state)
                SEND_JUNK: begin
                    in_dat <= rand_data;
                end
                SEND_PREA: begin
                    in_dat <= preamble[LENGTH-1-send_count];
                end
                SEND_DATA: begin
                    in_dat <= rand_data;
                    queue.push_back(rand_data);
                end
                SEND_ZERO: begin
                    in_dat <= 1'b0;
                end
            endcase
        end
    end

    always@(posedge clk) begin
        if (send_state == SEND_JUNK) begin
            recv_count <= 0;
        end else if (out_vld && recv_count < NUM_DATA && queue.size()>0) begin
            recv_count <= recv_count+1;
            if (out_dat == queue.pop_front()) begin
                $display ("Correct data: %b, Queue size: %0d, Sim time: %0d", out_dat, queue.size(), $time());
            end else begin
                $display ("Incorrect data: %b, Queue size: %0d, Sim time: %0d", out_dat, queue.size(), $time());
            end
        end
    end

    always @(*) begin
       case(send_state)
            SEND_JUNK: next_state = (send_count == NUM_JUNK-1) ? SEND_PREA : SEND_JUNK;
            SEND_PREA: next_state = (send_count == LENGTH-1) ? SEND_DATA : SEND_PREA;
            SEND_DATA: next_state = (send_count == NUM_DATA-1) ? SEND_ZERO : SEND_DATA;
            SEND_ZERO: next_state = (send_count == NUM_ZEROS-1) ? SEND_JUNK : SEND_ZERO;
        endcase
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        repeat(90000) #5 clk = ~clk;
        $finish;
    end

endmodule