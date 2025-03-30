// CRC16 10001000000100001  x16+ x12+ x5+ x0
// Preset 16'hFFFF
// Residue 16'h1D0F

module crc16 #(
    parameter PRESET = 16'hFFFF,
    parameter RESIDUE = 16'h1D0F
)(
    input  wire       clk,
    input  wire       rst,   // clear crc
    input  wire       in_data,   // bit input
    input  wire       in_vld,   // bit valid
    output reg [15:0] crc,   // crc value
    output wire       chk    // high if crc matches residue (only used for checking)
);

    wire   inv;
    assign inv = in_dat ^ crc[15];                   // XOR required?
    assign chk = crc == RESIDUE;

    always @(posedge clk) begin
        // initialise with preset when cleared
        if (rst) begin
            crc = PRESET;
        // run crc when input bits are valid
        end else if (in_vld) begin
            crc[15] = crc[14];
            crc[14] = crc[13];
            crc[13] = crc[12];
            crc[12] = crc[11] ^ inv;
            crc[11] = crc[10];
            crc[10] = crc[9];
            crc[9] = crc[8];
            crc[8] = crc[7];
            crc[7] = crc[6];
            crc[6] = crc[5];
            crc[5] = crc[4] ^ inv;
            crc[4] = crc[3];
            crc[3] = crc[2];
            crc[2] = crc[1];
            crc[1] = crc[0];
            crc[0] = inv;
        end
    end
   
endmodule