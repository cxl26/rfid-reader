module gray_to_bin #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] gray_num,
    output reg  [WIDTH-1:0] bin_num
);
    integer i;
    always @(*) begin
        bin_num[WIDTH-1] = gray_num[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i-1) begin
            bin_num[i] = gray_num[i] ? bin_num[i+1] : !bin_num[i+1];
        end
    end

    // genvar i;
    // generate
    //     for(i=0;i<WIDTH;i++) begin
    //         assign bin_num[i] = ^(gray_num >> i);
    //     end
    // endgenerate

endmodule