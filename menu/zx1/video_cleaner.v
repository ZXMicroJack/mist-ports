module video_cleaner (
	clk_vid,
	ce_pix,
	enable,
	R,
	G,
	B,
	HSync,
	VSync,
	HBlank,
	VBlank,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_VS,
	VGA_HS,
	HBlank_out,
	VBlank_out
);
	input clk_vid;
	input ce_pix;
	input enable;
	parameter COLOR_DEPTH = 8;
	input [COLOR_DEPTH - 1:0] R;
	input [COLOR_DEPTH - 1:0] G;
	input [COLOR_DEPTH - 1:0] B;
	input HSync;
	input VSync;
	input HBlank;
	input VBlank;
	output reg [COLOR_DEPTH - 1:0] VGA_R;
	output reg [COLOR_DEPTH - 1:0] VGA_G;
	output reg [COLOR_DEPTH - 1:0] VGA_B;
	output reg VGA_VS;
	output reg VGA_HS;
	output reg HBlank_out;
	output reg VBlank_out;
	wire hs;
	wire vs;
	s_fix sync_v(
		.clk(clk_vid),
		.sync_in(HSync),
		.sync_out(hs)
	);
	s_fix sync_h(
		.clk(clk_vid),
		.sync_in(VSync),
		.sync_out(vs)
	);
	wire hbl = hs | HBlank;
	wire vbl = vs | VBlank;
	always @(posedge clk_vid)
		if (!enable) begin
			HBlank_out <= HBlank;
			VBlank_out <= VBlank;
			VGA_HS <= HSync;
			VGA_VS <= VSync;
			VGA_R <= R;
			VGA_G <= G;
			VGA_B <= B;
		end
		else if (ce_pix) begin
			HBlank_out <= hbl;
			VGA_HS <= hs;
			if (~VGA_HS & hs)
				VGA_VS <= vs;
			VGA_R <= R;
			VGA_G <= G;
			VGA_B <= B;
			if (HBlank_out & ~hbl)
				VBlank_out <= vbl;
		end
endmodule
