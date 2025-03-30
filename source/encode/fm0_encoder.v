module fm0_encoder
(
    input  wire         clk,        // Clock signal
    input  wire         rst,        // Reset signal
    input  wire [3:0]   sym_period,
    input  wire         in_bit,     // Binary input data
    output wire         in_rdy,
    output reg          out_fm0,     // FM0 encoded output
    input  wire         out_rdy
);
    localparam S1 = 2'd0;
    localparam S2 = 2'd1;
    localparam S3 = 2'd2;
    localparam S4 = 2'd3;

    reg [1:0] next_symbol;            // Holds the next symbol
    reg [1:0] curr_symbol = 0;        // Holds the current symbol
    reg [3:0] sample_count = 0; // Counts samples per symbol

    always@(*) begin
        case (curr_symbol)
            S1: next_symbol = in_bit ? S4 : S3;
            S2: next_symbol = in_bit ? S1 : S2;
            S3: next_symbol = in_bit ? S4 : S3;
            S4: next_symbol = in_bit ? S1 : S2;
        endcase

        case (curr_symbol)
            S1: out_fm0 = 1;
            S2: out_fm0 = (sample_count < (sym_period)/2);
            S3: out_fm0 = (sample_count >= (sym_period)/2);
            S4: out_fm0 = 0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_count <= 0;
            curr_symbol <= 0;
        end else if (out_rdy) begin
            if (sample_count == sym_period-1) begin
                sample_count <= 0;
                curr_symbol <= next_symbol;
            end else begin
                sample_count <= sample_count+1;
                curr_symbol <= curr_symbol;
            end
        end
    end

    assign in_rdy = (sample_count == sym_period-1) && out_rdy;

endmodule