module top_tb;
    //outputs
    wire  out_mclk;
    wire  out_ws;
    wire  out_sck;
    wire  out_sd;
    wire  led1;
    wire  led2;
    wire  led3;
    wire  led4;
    wire  led5;
    wire  tx_pin;

    //inputs
    wire rx_pin;
    reg  sys_clk;

    //test variables
    int num_rand = $urandom_range(200, 10)
    int num_data = $urandom_range(200, 10)

    // bits
    logic data_bits [];
    logic crc_bits [];

    // values
    logic preamble_vals [] = '{1,1,0,1,0,0,1,0,0,0,1,1};
    logic data_vals [];
    logic crc_vals [];

    // samples
    logic rand_samp []
    logic preamble_samp [];
    logic data_samp [];
    logic crc_samp []

    // output samples
    logic output_samp [];

    initial begin
        for (int i=0; i<num_bits; i++) begin
            
        end
    end

    crc16_comb #(
        .NUM_BITS()
    ) crc16_comb_u1 (
        .dat(),   // clear crc
        .crc()    // crc value
    );

    reg preamble_vals [] = {1,1,0,1,0,0,1,0,0,0,1,1};

    // instantiate top dut
    top top_u1 (
        .sys_clk(sys_clk), 
        .out_mclk(out_mclk),
        .out_ws(out_ws),
        .out_sck(out_sck),
        .out_sd(out_sd),
        .led1(led1),
        .led2(led2),
        .led3(led3),
        .led4(led4),
        .led5(led5),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        sys_clk = 1;
        repeat(900000) #5 sys_clk = ~sys_clk;
        $finish;
    end

endmodule