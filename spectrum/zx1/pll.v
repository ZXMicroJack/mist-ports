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
	relojes relojes_inst(
		.CLK_IN1(inclk0),
		.CLK_OUT1(c0),
		.CLK_OUT2(c1),
		.CLK_OUT3(c2),
		.reset(areset),
		.locked(locked)
	);
endmodule
