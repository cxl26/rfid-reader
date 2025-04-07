module sampler #(
    parameter N = 10
) (
    input  wire clk,      // Destination clock domain
    input  wire rst,      // Synchronous reset
    input  wire rx_in,    // Asynchronous input signal
    output wire out_dat,
    output wire out_vld,
    output wire sample_strb
);
    localparam COUNT_WIDTH = $clog2(N+1);

    reg ff1 = 0;
    reg ff2 = 0;
    (* mark_debug = "true" *) wire sample_strobe;

    reg [COUNT_WIDTH-1:0] count = 0;
    
    assign sample_strb = sample_strobe;
    // Instantiate sample strobe generator
    strb_gen #(
        .N(N)
    ) sample_strb_gen (
        .clk (clk),
        .rst (rst),
        .strobe (sample_strobe)
    );

    // Two flip flop synchroniser
    always @(posedge clk) begin
        if (rst) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
            count <= 0;
        end else begin
            ff1 <= rx_in;
            ff2 <= ff1;
            count <= sample_strobe ? ff2 : count + ff2;
        end
    end
    
    assign out_dat = count > N/2;
    assign out_vld = sample_strobe;

endmodule

// module sampler #(
//     parameter N = 10
// ) (
//     input  wire clk,      // Destination clock domain
//     input  wire rst,      // Synchronous reset
//     input  wire rx_in,    // Asynchronous input signal
//     output wire out_dat,
//     output wire out_vld,
//     output wire sample_strb
// );

//     reg ff1 = 0;
//     reg ff2 = 0;
//     (* mark_debug = "true" *) wire sample_strobe;
    
//     assign sample_strb = sample_strobe;
//     // Instantiate sample strobe generator
//     strb_gen #(
//         .N(N)
//     ) sample_strb_gen (
//         .clk (clk),
//         .rst (rst),
//         .strobe (sample_strobe)
//     );

//     // Two flip flop synchroniser
//     always @(posedge clk) begin
//         if (rst) begin
//             ff1 <= 1'b0;
//             ff2 <= 1'b0;
//         end else begin
//             ff1 <= rx_in;
//             ff2 <= ff1;
//         end
//     end
    
//     assign out_dat = ff2;
//     assign out_vld = sample_strobe;

// endmodule