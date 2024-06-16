module turbosound (
	CLK,
	CE,
	RESET,
	BDIR,
	BC,
	DI,
	DO,
	AUDIO_L,
	AUDIO_R,
	IOA_in,
	IOA_out,
	IOB_in,
	IOB_out
);
	input CLK;
	input CE;
	input RESET;
	input BDIR;
	input BC;
	input [7:0] DI;
	output wire [7:0] DO;
	output wire [10:0] AUDIO_L;
	output wire [10:0] AUDIO_R;
	input [7:0] IOA_in;
	output wire [7:0] IOA_out;
	input [7:0] IOB_in;
	output wire [7:0] IOB_out;
	reg ay_select = 1'b1;
	wire BC_0;
	wire BC_1;
	wire [7:0] DO_0;
	wire [7:0] DO_1;
	wire [9:0] ay0_left;
	wire [9:0] ay0_right;
	wire [9:0] ay1_left;
	wire [9:0] ay1_right;
	always @(posedge CLK or posedge RESET)
		if (RESET == 1'b1)
			ay_select <= 1'b1;
		else if ((BDIR && BC) && (DI[7:1] == 7'b1111111))
			ay_select <= DI[0];
	YM2149 ym2149_0(
		.CLK(CLK),
		.ENA(CE),
		.RESET_L(!RESET),
		.I_BDIR(BDIR),
		.I_BC1(BC_0),
		.I_DA(DI),
		.O_DA(DO_0),
		.I_STEREO(1'b0),
		.O_AUDIO_L(ay0_left),
		.O_AUDIO_R(ay0_right),
		.I_IOA(),
		.O_IOA(),
		.I_IOB(),
		.O_IOB()
	);
	YM2149 ym2149_1(
		.CLK(CLK),
		.ENA(CE),
		.RESET_L(!RESET),
		.I_BDIR(BDIR),
		.I_BC1(BC_1),
		.I_DA(DI),
		.O_DA(DO_1),
		.I_STEREO(1'b0),
		.O_AUDIO_L(ay1_left),
		.O_AUDIO_R(ay1_right),
		.I_IOA(IOA_in),
		.O_IOA(IOA_out),
		.I_IOB(IOB_in),
		.O_IOB(IOB_out)
	);
	assign BC_0 = ~ay_select & BC;
	assign BC_1 = ay_select & BC;
	assign DO = (ay_select ? DO_1 : DO_0);
	assign AUDIO_L = {1'b0, ay0_left} + {1'b0, ay1_left};
	assign AUDIO_R = {1'b0, ay0_right} + {1'b0, ay1_right};
endmodule
