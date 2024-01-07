/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
`define ROM_SIZE 2048

module rom_t49(output reg[7:0] q, input wire[10:0] address, input wire clock);

   reg [7:0] mem [0:`ROM_SIZE-1] /* synthesis ramstyle = "M144K" */;
   initial begin
     $readmemh("ipc8049-hermesx.hex", mem);
   end

   always @(posedge clock) begin
     q <= mem[address];
   end
endmodule
