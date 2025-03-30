// CRC5 101001  x5+ x3+ x0
// Preset 5'b01001
// Residue 5'b00000

module crc5 #(
    parameter PRESET = 5'b01001,
    parameter RESIDUE = 5'b00000
)(
   input  wire      clk
   input  wire      rst;   // clear crc 
   input  wire      in_dat;   // bit input
   input  wire      in_vld;   // bit valid
   output reg [4:0] crc;   // crc value
   output wire      chk;   // high if crc matches residue (only used for checking)
);

   wire   inv;
   assign inv = in_dat ^ crc[4];                   // XOR required?
   assign chk = (crc == RESIDUE);
   
   always @(posedge clk) begin
      if (rst) begin
         crc = PRESET;
      end else if (in_vld) begin
         crc[4] = crc[3];
         crc[3] = crc[2] ^ inv;
         crc[2] = crc[1];
         crc[1] = crc[0];
         crc[0] = inv;
      end
   end
   
endmodule
