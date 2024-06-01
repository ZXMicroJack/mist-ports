module relojes (
	CLK_IN1,
	CLK_OUT1,
	CLK_OUT2,
	CLK_OUT3,
	reset,
	locked
);
	input wire CLK_IN1;
	output wire CLK_OUT1;
	output wire CLK_OUT2;
	output wire CLK_OUT3;
	input wire reset;
	output wire locked;
	wire clk_in1_clk_wiz_0;
	wire clk_in2_clk_wiz_0;
	IBUF clkin1_ibufg(
		.O(clk_in1_clk_wiz_0),
		.I(CLK_IN1)
	);
	wire clk_out1_clk_wiz_0;
	wire clk_out2_clk_wiz_0;
	wire clk_out3_clk_wiz_0;
	wire clk_out4_clk_wiz_0;
	wire clk_out5_clk_wiz_0;
	wire clk_out6_clk_wiz_0;
	wire clk_out7_clk_wiz_0;
	wire [15:0] do_unused;
	wire drdy_unused;
	wire psdone_unused;
	wire locked_int;
	wire clkfbout_clk_wiz_0;
	wire clkfboutb_unused;
	wire clkout0b_unused;
	wire clkout1b_unused;
	wire clkout2b_unused;
	wire clkout3_unused;
	wire clkout3b_unused;
	wire clkout4_unused;
	wire clkout5_unused;
	wire clkout6_unused;
	wire clkfbstopped_unused;
	wire clkinstopped_unused;
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKOUT4_CASCADE("FALSE"),
		.COMPENSATION("ZHOLD"),
		.STARTUP_WAIT("FALSE"),
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_MULT_F(18.000),
		.CLKFBOUT_PHASE(0.000),
		.CLKFBOUT_USE_FINE_PS("FALSE"),
		.CLKOUT0_DIVIDE_F(8.000),
		.CLKOUT0_PHASE(0.000),
		.CLKOUT0_DUTY_CYCLE(0.500),
		.CLKOUT0_USE_FINE_PS("FALSE"),
		.CLKOUT1_DIVIDE(8.000),
		.CLKOUT1_PHASE(-22.500),
		.CLKOUT1_DUTY_CYCLE(0.500),
		.CLKOUT1_USE_FINE_PS("FALSE"),
		.CLKOUT2_DIVIDE(18.000),
		.CLKOUT2_PHASE(0.000),
		.CLKOUT2_DUTY_CYCLE(0.500),
		.CLKOUT2_USE_FINE_PS("FALSE"),
		.CLKIN1_PERIOD(20.000)
	) mmcm_adv_inst(
		.CLKFBOUT(clkfbout_clk_wiz_0),
		.CLKFBOUTB(),
		.CLKOUT0(clk_out1_clk_wiz_0),
		.CLKOUT0B(),
		.CLKOUT1(clk_out2_clk_wiz_0),
		.CLKOUT1B(),
		.CLKOUT2(clk_out3_clk_wiz_0),
		.CLKOUT2B(),
		.CLKOUT3(),
		.CLKOUT3B(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKOUT6(),
		.CLKFBIN(clkfbout_clk_wiz_0),
		.CLKIN1(clk_in1_clk_wiz_0),
		.CLKIN2(1'b0),
		.CLKINSEL(1'b1),
		.DADDR(7'h00),
		.DCLK(1'b0),
		.DEN(1'b0),
		.DI(16'h0000),
		.DO(do_unused),
		.DRDY(drdy_unused),
		.DWE(1'b0),
		.PSCLK(1'b0),
		.PSEN(1'b0),
		.PSINCDEC(1'b0),
		.PSDONE(psdone_unused),
		.LOCKED(locked_int),
		.CLKINSTOPPED(clkinstopped_unused),
		.CLKFBSTOPPED(clkfbstopped_unused),
		.PWRDWN(1'b0),
		.RST(reset)
	);
	assign locked = locked_int;
	BUFG bclk_out1(
		.O(CLK_OUT1),
		.I(clk_out1_clk_wiz_0)
	);
	BUFG bclkout2(
		.O(CLK_OUT2),
		.I(clk_out2_clk_wiz_0)
	);
	BUFG bclkout3(
		.O(CLK_OUT3),
		.I(clk_out3_clk_wiz_0)
	);
endmodule
