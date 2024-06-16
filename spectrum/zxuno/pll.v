module pll (
	areset,
	inclk0,
	c0,
	c1,
	c2,
	locked
);
	input wire areset;
	input wire inclk0;
	output wire c0;
	output wire c1;
	output wire c2;
	output wire locked;
	assign locked = 1'b1;
	relojes relojes_inst(
		.CLK_IN1(inclk0),
		.CLK_OUT1(c0)
	);
	assign c1 = c0;
	assign c2 = c0;
endmodule
