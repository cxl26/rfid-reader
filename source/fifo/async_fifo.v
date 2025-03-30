module async_fifo #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 24
)(
    input  wire rd_clk,
    input  wire wr_clk,
    input  wire wr_en,
    input  wire rd_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data,
    output reg  rd_empty = 1,
    output reg  wr_full  = 0
);

    reg  [ADDR_WIDTH:0] rd_ptr_bin  = 0;
    reg  [ADDR_WIDTH:0] wr_ptr_bin  = 0;
    reg  [ADDR_WIDTH:0] rd_ptr_gray = 0;
    reg  [ADDR_WIDTH:0] wr_ptr_gray = 0;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;

    reg  [ADDR_WIDTH:0] rd_ptr_sync1 = 0;
    reg  [ADDR_WIDTH:0] rd_ptr_sync2 = 0;

    reg  [ADDR_WIDTH:0] wr_ptr_sync1 = 0;
    reg  [ADDR_WIDTH:0] wr_ptr_sync2 = 0;

    wire rd_empty_next;
    wire wr_full_next;
  
    integer               i;

    assign rd_ptr_bin_next = rd_ptr_bin + (rd_en && !rd_empty);
    assign wr_ptr_bin_next = wr_ptr_bin + (wr_en && !wr_full );

    bin_to_gray #(
        .WIDTH(ADDR_WIDTH+1)
    ) bin_to_gray_u1 (
        .bin_num  (rd_ptr_bin_next),
        .gray_num (rd_ptr_gray_next)
    );

    bin_to_gray #(
        .WIDTH(ADDR_WIDTH+1)
    ) bin_to_gray_u2 (
        .bin_num  (wr_ptr_bin_next),
        .gray_num (wr_ptr_gray_next)
    );

    always@(posedge rd_clk) begin
        rd_ptr_bin  <= rd_ptr_bin_next;
        rd_ptr_gray <= rd_ptr_gray_next;
    end

    always@(posedge rd_clk) begin
        wr_ptr_sync2 <= wr_ptr_sync1;
        wr_ptr_sync1 <= wr_ptr_gray;
    end

    always@(posedge wr_clk) begin
        wr_ptr_bin  <= wr_ptr_bin_next;
        wr_ptr_gray <= wr_ptr_gray_next;
    end

    always@(posedge wr_clk) begin
        rd_ptr_sync2 <= rd_ptr_sync1;
        rd_ptr_sync1 <= rd_ptr_gray;
    end

    assign rd_empty_next = (rd_ptr_gray_next == wr_ptr_sync2);

    assign wr_full_next  = (wr_ptr_gray_next[ADDR_WIDTH   -: 2] == ~rd_ptr_sync2[ADDR_WIDTH   -: 2]) &&
                           (wr_ptr_gray_next[ADDR_WIDTH-2  : 0] ==  rd_ptr_sync2[ADDR_WIDTH-2  : 0]);

    always@(posedge rd_clk) begin
        rd_empty <= rd_empty_next;
    end

    always@(posedge wr_clk) begin
        wr_full <= wr_full_next;
    end

    sdp_2clk_bram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sdp_2clk_bram_u1 (
        .rd_clk (rd_clk),
        .wr_clk (wr_clk),
        .rd_addr(rd_ptr_bin[ADDR_WIDTH-1:0]),
        .wr_addr(wr_ptr_bin[ADDR_WIDTH-1:0]),
        .wr_en  (wr_en && !wr_full),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

endmodule