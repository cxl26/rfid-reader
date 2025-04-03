module add #(
    parameter INPUT_NUM   = 8,                            // Number of inputs
    parameter INPUT_WIDTH = 8,                            // Bit width of each input
    parameter OUTPUT_WIDTH = INPUT_WIDTH + $clog2(INPUT_NUM) // Output width
)(
    input  wire [INPUT_NUM*INPUT_WIDTH-1:0] in_dat,       // Concatenated inputs
    output wire [OUTPUT_WIDTH-1:0]          out_dat       // Summed output
);

    integer i;
    reg [OUTPUT_WIDTH-1:0] sum;

    always @(*) begin
        sum = 0;
        for (i = 0; i < INPUT_NUM; i = i + 1) begin
            sum = sum + in_dat[i*INPUT_WIDTH +: INPUT_WIDTH];
        end
    end

    assign out_dat = sum;

endmodule