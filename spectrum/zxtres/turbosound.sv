module turbosound
(
	input         CLK,		   // Global clock
	input         CE,        // PSG Clock enable
	input  wire   RESET,	   // Chip RESET (set all Registers to '0', active high)
	input         BDIR,	   // Bus Direction (0 - read , 1 - write)
	input         BC,		   // Bus control
	input   [7:0] DI,	      // Data In
	output wire [7:0] DO,	      // Data Out
	output wire [10:0] AUDIO_L,
	output wire [10:0] AUDIO_R,

	input  [7:0] IOA_in,
	output wire [7:0] IOA_out,

	input  [7:0] IOB_in,
	output wire [7:0] IOB_out,
	output wire MIDI_OUT
);

// AY1 selected by default
reg ay_select = 1'b1;

// Bus control for each AY chips
wire BC_0;
wire BC_1;

// Data outputs for each AY chips
wire [7:0] DO_0;
wire [7:0] DO_1;

// AY0 channel output data
//wire [9:0] ay0_left;
//wire [9:0] ay0_right;

// AY1 channel output data
//wire [9:0] ay1_left;
//wire [9:0] ay1_right;

always_ff @(posedge CLK or posedge RESET) begin
	if (RESET == 1'b1) begin
		// Select AY1 after reset
		ay_select <= 1'b1;
	end
	else if (BDIR && BC && DI[7:1] == 7'b1111111) begin
		// Select AY0 or AY1 according to lower bit of data register (1111 111N)
		ay_select <= DI[0];
	end
end

assign MIDI_OUT = ay_select ? io1[2] : io0[2];

/*module psg
(
	input  wire       clock,
	input  wire       sel,
	input  wire       ce,

	input  wire       reset,
	input  wire       bdir,
	input  wire       bc1,
	input  wire[ 7:0] d,
	output reg [ 7:0] q,

	output wire[11:0] a,
	output wire[11:0] b,
	output wire[11:0] c,

	output wire[ 7:0] io
);*/

wire[7:0] io0;
wire[7:0] io1;

wire[11:0] a1, a2;
wire[11:0] b1, b2;
wire[11:0] c1, c2;

psg ym2149_0
(
.clock(CLK), // input  wire
.sel(1'b0), // input  wire
.ce(CE), // input  wire
.reset(!RESET), // input  wire
.bdir(BDIR), // input  wire
.bc1(BC_0), //input  wire
.d(DI), //	input  wire[ 7:0]
.q(DO_0), //	output reg [ 7:0]
.a(a1), // output wire[11:0]
.b(b1), // output wire[11:0]
.c(c1), // output wire[11:0]
.io(io0) //output wire[ 7:0] io
);

psg ym2149_1
(
.clock(CLK), // input  wire
.sel(1'b0), // input  wire
.ce(CE), // input  wire
.reset(!RESET), // input  wire
.bdir(BDIR), // input  wire
.bc1(BC_1), //input  wire
.d(DI), //	input  wire[ 7:0]
.q(DO_1), //	output reg [ 7:0]
.a(a2), // output wire[11:0]
.b(b2), // output wire[11:0]
.c(c2), // output wire[11:0]
.io(io1) //output wire[ 7:0] io
);

wire[15:0] lmix = { 3'd0, a1, 1'd0 }+{ 3'd0, a2, 1'd0 }+{ 4'd0, b1 }+{ 4'd0, b2};
wire[15:0] rmix = { 3'd0, c1, 1'd0 }+{ 3'd0, c2, 1'd0 }+{ 4'd0, b1 }+{ 4'd0, b2};

assign AUDIO_L = lmix[15:5];
assign AUDIO_R = rmix[15:5];


/*YM2149 ym2149_0
(
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
);*/

// AY1 (Default AY)
/*YM2149 ym2149_1
(
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
);*/

assign BC_0 = ~ay_select & BC;
assign BC_1 = ay_select & BC;
assign DO = ay_select ? DO_1 : DO_0;

// Mix channel signals from both AY/YM chips (extending to 10 bits width to prevent clipping)
//assign AUDIO_L = { 1'b0, ay0_left  } + { 1'b0, ay1_left  };
//assign AUDIO_R = { 1'b0, ay0_right } + { 1'b0, ay1_right };


endmodule
