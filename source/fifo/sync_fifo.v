module sync_fifo #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 24
)(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire rd_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire  empty,
    output wire  full,
    input  wire  jump,
    input  wire [ADDR_WIDTH-1:0] jump_value,
    output wire  jump_error
);

    reg                   rd_wrap = 0;
    reg                   wr_wrap = 0;
    reg  [ADDR_WIDTH-1:0] rd_ptr  = 0;
    reg  [ADDR_WIDTH-1:0] wr_ptr  = 0;

    reg                   wr_wrap_reg = 0;
    reg  [ADDR_WIDTH-1:0] wr_ptr_reg  = 0;

    reg wr_en_reg = 0;

    wire                   jump_wrap;
    wire  [ADDR_WIDTH-1:0] jump_ptr;

    assign empty = (rd_wrap == wr_wrap_reg) && (rd_ptr == wr_ptr_reg); // wraps equal, ptrs equal
    assign full  = (rd_wrap != wr_wrap_reg) && (rd_ptr == wr_ptr_reg); // wraps not equal, ptrs equal

    assign {jump_wrap, jump_ptr} = {rd_wrap, rd_ptr} + {1'b0,jump_value};
    assign jump_error = (jump_wrap == wr_wrap_reg) && (jump_ptr >= wr_ptr_reg);


    always@(posedge clk) begin
        if (rst) begin
            {rd_wrap, rd_ptr} <= 0;
            {wr_wrap, wr_ptr} <= 0;
            {wr_wrap_reg, wr_ptr_reg} <= 0;
        end else begin
            if (jump && !jump_error) begin
                {rd_wrap, rd_ptr} <= {jump_wrap, jump_ptr};
            end else begin
                {rd_wrap, rd_ptr} <= {rd_wrap, rd_ptr} + (rd_en && !empty);
            end
            {wr_wrap, wr_ptr} <= {wr_wrap, wr_ptr} + (wr_en && !full);
            {wr_wrap_reg, wr_ptr_reg} <= {wr_wrap, wr_ptr};
        end
    end

    sdp_1clk_bram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sdp_1clk_bram_u1 (
        .clk    (clk),
        .rd_addr(rd_ptr),
        .wr_addr(wr_ptr),
        .wr_en  (wr_en && !full),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

endmodule