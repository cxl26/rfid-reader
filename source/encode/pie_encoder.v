module pie_encoder
#(
    parameter THIRD_TARI = 2
)
(
    input  wire         clk,        // Clock signal
    input  wire         rst,        // Reset signal
    input  wire         in_bit,     // Binary input data
    output wire         in_rdy,
    output wire         out_pie,     // FM0 encoded output
    input  wire         out_rdy
);

    wire      load;
    reg       cur = 0; // Holds the current symbol
    reg [3:0] cnt = 0; // Counts samples per symbol

    assign out_pie = cur ? (cnt < THIRD_TARI*4) : (cnt < THIRD_TARI*2);
    assign in_rdy  = load && out_rdy;

    assign load = cur ? (cnt == THIRD_TARI*5-1) : (cnt == THIRD_TARI*3-1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cur <= 0;
            cnt <= 0;
        end else if (out_rdy) begin
            if (load) begin
                cnt <= 0;
                cur <= in_bit;
            end else begin
                cnt <= cnt+1;
                cur <= cur;
            end
        end
    end

endmodule