module pll (
	input wire inclk0,
	output wire c0,
	output wire c1,
	output wire c2,
	output wire locked
	);

	reg[1:0] clk = 2'b00;

	always @(posedge inclk0)
    clk <= clk + 1;

  assign c0 = inclk0;
  assign c1 = clk[0];
  assign c2 = clk[1];
  assign locked = 1'b1;

endmodule
