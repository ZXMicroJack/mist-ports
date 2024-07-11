module lfsr2(
   input wire clk,
   output wire[22:0] rnd
);

   reg [23:1] r_LFSR = 0;

   assign rnd[22:0] = r_LFSR[23:1];

   always @(posedge clk) r_LFSR <= {r_LFSR[22:1], r_LFSR[23] ^~ r_LFSR[18]};

endmodule // LFSR
