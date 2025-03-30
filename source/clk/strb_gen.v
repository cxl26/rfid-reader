// Strobe generator that pulses a strobe high for single cycle with period of N clock cycles.
module strb_gen #(
    parameter N = 10  // Number of cycles per strobe pulse
)(
    input wire clk,     // Clock input
    input wire rst,     // Synchronous reset
    output reg strobe   // Strobe output
);

    reg [$clog2(N)-1:0] counter = 0;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            strobe <= 0;
        end else begin
            if (counter == N-1) begin
                strobe <= 1;  // Assert strobe
                counter <= 0; // Reset counter
            end else begin
                strobe <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule