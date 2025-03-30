`timescale 1ns/1ps

module bits_detector_tb;

    parameter LENGTH         = 10;
    parameter BANKS          = 4;

    parameter NUM_RSET = 20;
    parameter NUM_DATA = 300;
    parameter NUM_ZERO = 5;

    localparam BANK_WIDTH = $clog2(BANKS);

    //outputs
    wire out_dat;
    wire out_vld;

    //inputs
    reg                   in_dat = 0;
    reg                   in_vld = 0;
    reg  [BANK_WIDTH-1:0] frequency_bank;
    reg                   clk;
    reg                   dut_rst = 0;

    // generated signals
    reg        queue [$]; 
    reg        rand_data;
    integer    send_count = 0;
    integer    recv_count = 0;
    
    wire       send_strobe;

    wire send_rdy;
    reg  send_bit = 1;
    wire fm0;

    integer seed = 28;

    // State machine
    reg [1:0]  send_state = SEND_RSET;
    reg [1:0]  next_state = 0;
    localparam SEND_RSET = 2'd0, SEND_DATA = 2'd1, SEND_ZERO = 2'd2;

    strb_gen #(
        .N(1)
    ) strb_gen_u1 (
        .clk(clk),  // Clock input
        .rst(1'b0), // Synchronous reset
        .strobe(send_strobe)   // Strobe output
    );

    // instantiate top dut
    bits_detector #(
        .LENGTH (LENGTH),
        .BANKS  (BANKS),
        .EL_GATES (1)
    ) bits_detector_u1 (
        .clk (clk),
        .rst (dut_rst),
        .in_dat (in_dat),
        .in_vld (in_vld),
        .frequency_bank (frequency_bank),
        .out_dat (out_dat),
        .out_vld (out_vld)
    );

    initial queue.push_back(1'b1);
    assign frequency_bank = 2;

    fm0_encoder fm0_encoder_u1
    (
        .clk       (clk),    // Clock signal
        .rst       (1'b0),   // Reset signal
        .sym_period(4'd11),
        .in_bit    (send_bit),
        .in_rdy    (send_rdy),
        .out_fm0   (fm0),
        .out_rdy   (send_strobe && (send_state == SEND_DATA))
    );
    
    always@(posedge clk) begin
        $urandom(seed); // Set a different seed

        if (send_rdy) begin
            queue.push_back(send_bit);
            //$display("Sent data: %b, Sim time: %0d", send_bit, $time());
            send_bit <= $urandom_range(1,0);
        end
        if (send_strobe) begin
            send_state <= next_state;
            send_count <= (next_state != send_state) ? 0 : send_count + 1;
            case(send_state)        
                SEND_RSET: begin
                    in_dat  <= $urandom_range(1,0);
                    in_vld  <= 1'b1;
                    dut_rst <= 1'b1;
                end
                SEND_DATA: begin
                    in_dat  <= fm0;
                    in_vld  <= 1'b1;
                    dut_rst <= 1'b0;
                end
                SEND_ZERO: begin
                    in_dat  <= 1'b0;
                    in_vld  <= 1'b1;
                    dut_rst <= 1'b0;
                end
            endcase
        end else begin
            in_dat  <= $urandom_range(1,0);
            in_vld  <= 1'b0;
            dut_rst <= dut_rst;
        end
    end

    always@(posedge clk) begin
        if (send_state == SEND_RSET) begin
            recv_count <= 0;
        end else if (out_vld && queue.size()>0) begin
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
            SEND_RSET: next_state = (send_count == NUM_RSET-1) ? SEND_DATA : SEND_RSET;
            SEND_DATA: next_state = (send_count == NUM_DATA-1) ? SEND_ZERO : SEND_DATA;
            SEND_ZERO: next_state = (send_count == NUM_ZERO-1) ? SEND_RSET : SEND_ZERO;
        endcase
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        repeat(900) #5 clk = ~clk;
        $finish;
    end

endmodule