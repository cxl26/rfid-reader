module sync_fifo_tb;

    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 12;

    logic clk;

    wire full;
    wire empty;

    reg jump = 0;
    reg [ADDR_WIDTH-1:0] jump_value = 1;

    reg rd_en = 0;
    reg wr_en = 0;

    reg  [DATA_WIDTH-1:0] wr_data = 0;
    wire [DATA_WIDTH-1:0] rd_data;

    sync_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sync_fifo_u1 (
        .clk(clk),
        .rst(1'b0),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .empty(empty),
        .full(full),
        .jump (jump),
        .jump_value (jump_value),
        .jump_error ()
    );
    always@(posedge clk) begin
        if ($time() < 600 && $urandom_range(1, 0) && !full) begin
            wr_data <= wr_data + 1;
            wr_en   <= 1;
        end else begin
            wr_data <= wr_data;
            wr_en   <= 0;
        end
    end

    always@(posedge clk) begin
        if ($time() > 300 && $urandom_range(1, 0) && !empty) begin
            rd_en <= 1;
        end else begin
            rd_en <= 0;
        end
    end

    initial begin
        $dumpvars;
        clk = 1;
        #40000
        $finish;
    end
        
    always #5  clk = ~clk;
    initial begin
        #60 jump = 1;
        #15 jump = 0;
    end

endmodule