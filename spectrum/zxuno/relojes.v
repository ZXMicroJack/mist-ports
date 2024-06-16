module relojes (
	CLK_IN1,
	CLK_OUT1
);
	input wire CLK_IN1;
	output wire CLK_OUT1;
	wire clkin1;
	wire clkout0;
	wire clkout1;
	wire clkout2;
	IBUFG clkin1_buf(
		.O(clkin1),
		.I(CLK_IN1)
	);
	wire [15:0] do_unused;
	wire drdy_unused;
	wire locked_unused;
	wire clkfbout;
	wire clkout1_unused;
	wire clkout2_unused;
	wire clkout3_unused;
	wire clkout4_unused;
	wire clkout5_unused;
	PLL_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLK_FEEDBACK("CLKFBOUT"),
		.COMPENSATION("INTERNAL"),
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_MULT(18),
		.CLKFBOUT_PHASE(0.000),
		.CLKOUT0_DIVIDE(8),
		.CLKOUT0_PHASE(0.000),
		.CLKOUT0_DUTY_CYCLE(0.500),
		.CLKIN_PERIOD(20.0),
		.REF_JITTER(0.010)
	) pll_base_inst(
		.CLKFBOUT(clkfbout),
		.CLKOUT0(clkout0),
		.CLKOUT1(clkout1_unused),
		.CLKOUT2(clkout2_unused),
		.CLKOUT3(clkout3_unused),
		.CLKOUT4(clkout4_unused),
		.CLKOUT5(clkout5_unused),
		.LOCKED(locked_unused),
		.RST(1'b0),
		.CLKFBIN(clkfbout),
		.CLKIN(clkin1)
	);
	BUFG clkout1_buf(
		.O(CLK_OUT1),
		.I(clkout0)
	);
endmodule
