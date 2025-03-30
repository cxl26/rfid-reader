module bin_to_gray #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] bin_num,
    output reg  [WIDTH-1:0] gray_num
);
    integer i;
    always @(*) begin
        gray_num[WIDTH-1] = bin_num[WIDTH-1];
        for (i=0; i<WIDTH-1; i++) begin
            gray_num[i] = bin_num[i] ^ bin_num[i+1];
        end
    end

    // genvar i;
    // generate
    //     for(i=0;i<WIDTH-1;i++) begin
    //         assign gray_num[i] = bin_num[i] ^ bin_num[i+1];;
    //     end
    // endgenerate
    // assign gray_num[WIDTH-1] = bin_num[WIDTH-1];

endmodule
