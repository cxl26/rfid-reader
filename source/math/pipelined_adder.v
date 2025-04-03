module pipelined_adder #(
    parameter INPUT_NUM   = 8,                            // Number of inputs
    parameter INPUT_WIDTH = 8,                            // Bit width of each input
    parameter STAGE_NUM   = 2,                            // Number of pipeline stages
    parameter OUTPUT_WIDTH = INPUT_WIDTH + $clog2(INPUT_NUM) // Output width
)(
    input wire clk,
    input wire [INPUT_NUM*INPUT_WIDTH-1:0] in_dat,
    input wire [OUTPUT_WIDTH-1:0] out_dat
)

    LEVEL_NUM = $clog2(INPUT_NUM);

    LEVELS_EACH_STAGE = LEVEL_NUM/STAGE_NUM;
    LEVELS_LAST_STAGE = LEVEL_NUM - LEVELS_EACH_STAGE*STAGE_NUM;

    generate
        genvar i;
        genvar j;
        for (i = 0; i < STAGE_NUM; i = i + 1) begin : input_assign
            localparam STAGE_INPUT_WIDTH = INPUT_WIDTH+$clog2(LEVELS_LAST_STAGE+i*LEVELS_EACH_STAGE);
            localparam STAGE_INPUT_NUM = INPUT_NUM/(2**(LEVELS_LAST_STAGE+i*LEVELS_EACH_STAGE));

            localparam STAGE_OUTPUT_WIDTH = INPUT_WIDTH+$clog2(LEVELS_LAST_STAGE+(i+1)*LEVELS_EACH_STAGE);
            localparam STAGE_OUTPUT_NUM = INPUT_NUM/(2**(LEVELS_LAST_STAGE+(i+1)*LEVELS_EACH_STAGE));

            reg [STAGE_INPUT_WIDTH-1:0] stage_input_register [STAGE_INPUT_NUM-1:0];
            reg [STAGE_OUTPUT_WIDTH-1:0] stage_output_wires [STAGE_OUTPUT_NUM-1:0];

            for (j = 0; j < OUTPUT_NUM; j = j + 1) begin
                stage_output_wires[j] = 0;
                for (k = j*k; k < 2**LEVELS_EACH_STAGE; k = k + 1) begin
                    stage_output_wires[j] = stage_output_wires[j] + stage_input_register[k];
                end

                module add #(
    parameter INPUT_NUM   = 8,                            // Number of inputs
    parameter INPUT_WIDTH = 8,                            // Bit width of each input
    parameter OUTPUT_WIDTH = INPUT_WIDTH + $clog2(INPUT_NUM) // Output width
)(
    input  wire [INPUT_NUM*INPUT_WIDTH-1:0] in_dat,       // Concatenated inputs
    output wire [OUTPUT_WIDTH-1:0]          out_dat       // Summed output
);
            end


        end
    endgenerate

    // generate
    //     genvar i; 
    //     for (i = 0; i < INPUT_NUM; i = i + 1) begin : input_assign
    //         assign sum_tree[i] = {{(OUTPUT_WIDTH-INPUT_WIDTH){1'b0}}, in_dat[i*INPUT_WIDTH +: INPUT_WIDTH]};
    //     end
    // endgenerate

endmodule