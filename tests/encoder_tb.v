`timescale 1ns/1ps

module fm0_encoder_tb;

    // dut connections
    reg  clk;
    reg  in_bit = 0;
    wire in_rdy;
    wire out_dat;
    reg  out_rdy;

    // generated signals
    reg        queue [$]; 
    reg        rand_data;

    // fm0_encoder fm0_encoder_u1
    // (
    //     .clk(clk),         // Clock signal
    //     .rst(1'b0),        // Reset signal
    //     .sym_period(4'd15),
    //     .in_bit(in_bit),           // Binary input data
    //     .in_rdy(in_rdy),
    //     .out_fm0(out_dat),          // FM0 encoded output
    //     .out_rdy(1'b1)
    // );

    pie_encoder #(
        .THIRD_TARI(1)
    ) fm0_encoder_u1 (
        .clk(clk),         // Clock signal
        .rst(1'b0),        // Reset signal
        .in_bit(in_bit),           // Binary input data
        .in_rdy(in_rdy),
        .out_pie(out_dat),          // FM0 encoded output
        .out_rdy(1'b1)
    );

    always@(posedge clk) begin
        if (in_rdy) begin
            rand_data = $urandom_range(1,0);
            in_bit <= rand_data;
            queue.push_back(rand_data);
        end
        out_rdy <= 1'b1;

    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        repeat(9000) #5 clk = ~clk;
        $finish;
    end

endmodule