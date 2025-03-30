module clk_div #(
    parameter DIVISOR = 1250
)(
    input  wire in_clk,
    output reg  out_clk
);
    localparam COUNTER_WIDTH = $clog2(DIVISOR);
    reg [COUNTER_WIDTH-1:0] counter = 0;

    // NOTE: can only divide by integer multiple of 2, would need to clock on both posedge negedge otherwise
    // could fix with a fractional accumulator if we want fractional divisions.
    initial out_clk = 0;
  
    always @ (posedge in_clk) begin
        counter <= (counter >= DIVISOR-1) ? 0 : counter+1;
        out_clk <= (counter < DIVISOR/2)  ? 1 : 0;
    end
endmodule