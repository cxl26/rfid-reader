
`timescale 1ns/1ps

module strb_gen_tb;
    reg clk;

    strb_gen #(
        .N(10)
    ) strb_gen_u1 (
        .clk(clk),  // Clock input
        .rst(1'b0), // Synchronous reset
        .strobe()   // Strobe output
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        repeat(9000) #5 clk = ~clk;
        $finish;
    end

endmodule