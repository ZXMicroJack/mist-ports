module mist_video (
	clk_sys,
	SPI_SCK,
	SPI_SS3,
	SPI_DI,
	scanlines,
	ce_divider,
	scandoubler_disable,
	no_csync,
	ypbpr,
	rotate,
	blend,
	R,
	G,
	B,
	HBlank,
	VBlank,
	HSync,
	VSync,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_VS,
	VGA_HS,
	VGA_HB,
	VGA_VB,
	VGA_DE
);
	input clk_sys;
	input SPI_SCK;
	input SPI_SS3;
	input SPI_DI;
	input [1:0] scanlines;
	input [2:0] ce_divider;
	input scandoubler_disable;
	input no_csync;
	input ypbpr;
	input [1:0] rotate;
	input blend;
	parameter COLOR_DEPTH = 6;
	input [COLOR_DEPTH - 1:0] R;
	input [COLOR_DEPTH - 1:0] G;
	input [COLOR_DEPTH - 1:0] B;
	input HBlank;
	input VBlank;
	input HSync;
	input VSync;
	parameter OUT_COLOR_DEPTH = 6;
	output reg [OUT_COLOR_DEPTH - 1:0] VGA_R;
	output reg [OUT_COLOR_DEPTH - 1:0] VGA_G;
	output reg [OUT_COLOR_DEPTH - 1:0] VGA_B;
	output reg VGA_VS;
	output reg VGA_HS;
	output reg VGA_HB;
	output reg VGA_VB;
	output reg VGA_DE;
	parameter OSD_COLOR = 3'd4;
	parameter OSD_X_OFFSET = 10'd0;
	parameter OSD_Y_OFFSET = 10'd0;
	parameter SD_HCNT_WIDTH = 9;
	parameter OSD_AUTO_CE = 1'b1;
	parameter SYNC_AND = 1'b0;
	parameter USE_BLANKS = 1'b0;
	parameter SD_HSCNT_WIDTH = 12;
	parameter BIG_OSD = 1'b0;
	parameter VIDEO_CLEANER = 1'b0;
	wire [OUT_COLOR_DEPTH - 1:0] SD_R_O;
	wire [OUT_COLOR_DEPTH - 1:0] SD_G_O;
	wire [OUT_COLOR_DEPTH - 1:0] SD_B_O;
	wire SD_HS_O;
	wire SD_VS_O;
	wire SD_HB_O;
	wire SD_VB_O;
	wire pixel_ena;
	scandoubler #(
		.HCNT_WIDTH(SD_HCNT_WIDTH),
		.COLOR_DEPTH(COLOR_DEPTH),
		.HSCNT_WIDTH(SD_HSCNT_WIDTH),
		.OUT_COLOR_DEPTH(OUT_COLOR_DEPTH)
	) scandoubler(
		.clk_sys(clk_sys),
		.bypass(scandoubler_disable),
		.ce_divider(ce_divider),
		.scanlines(scanlines),
		.pixel_ena(pixel_ena),
		.hb_in(HBlank),
		.vb_in(VBlank),
		.hs_in(HSync),
		.vs_in(VSync),
		.r_in(R),
		.g_in(G),
		.b_in(B),
		.hb_out(SD_HB_O),
		.vb_out(SD_VB_O),
		.hs_out(SD_HS_O),
		.vs_out(SD_VS_O),
		.r_out(SD_R_O),
		.g_out(SD_G_O),
		.b_out(SD_B_O)
	);
	wire [OUT_COLOR_DEPTH - 1:0] osd_r_o;
	wire [OUT_COLOR_DEPTH - 1:0] osd_g_o;
	wire [OUT_COLOR_DEPTH - 1:0] osd_b_o;
	osd #(
		.OSD_X_OFFSET(OSD_X_OFFSET),
		.OSD_Y_OFFSET(OSD_Y_OFFSET),
		.OSD_COLOR(OSD_COLOR),
		.OSD_AUTO_CE(OSD_AUTO_CE),
		.USE_BLANKS(USE_BLANKS),
		.OUT_COLOR_DEPTH(OUT_COLOR_DEPTH),
		.BIG_OSD(BIG_OSD)
	) osd(
		.clk_sys(clk_sys),
		.rotate(rotate),
		.ce(pixel_ena),
		.SPI_DI(SPI_DI),
		.SPI_SCK(SPI_SCK),
		.SPI_SS3(SPI_SS3),
		.R_in(SD_R_O),
		.G_in(SD_G_O),
		.B_in(SD_B_O),
		.HBlank(SD_HB_O),
		.VBlank(SD_VB_O),
		.HSync(SD_HS_O),
		.VSync(SD_VS_O),
		.R_out(osd_r_o),
		.G_out(osd_g_o),
		.B_out(osd_b_o)
	);
	wire [OUT_COLOR_DEPTH - 1:0] cofi_r;
	wire [OUT_COLOR_DEPTH - 1:0] cofi_g;
	wire [OUT_COLOR_DEPTH - 1:0] cofi_b;
	wire cofi_hs;
	wire cofi_vs;
	wire cofi_hb;
	wire cofi_vb;
	wire cofi_pixel_ena;
	cofi #(.VIDEO_DEPTH(OUT_COLOR_DEPTH)) cofi(
		.clk(clk_sys),
		.pix_ce(pixel_ena),
		.enable(blend),
		.hblank((USE_BLANKS ? SD_HB_O : ~SD_HS_O)),
		.vblank(SD_VB_O),
		.hs(SD_HS_O),
		.vs(SD_VS_O),
		.red(osd_r_o),
		.green(osd_g_o),
		.blue(osd_b_o),
		.hs_out(cofi_hs),
		.vs_out(cofi_vs),
		.hblank_out(cofi_hb),
		.vblank_out(cofi_vb),
		.red_out(cofi_r),
		.green_out(cofi_g),
		.blue_out(cofi_b),
		.pix_ce_out(cofi_pixel_ena)
	);
	wire [OUT_COLOR_DEPTH - 1:0] cleaner_r_o;
	wire [OUT_COLOR_DEPTH - 1:0] cleaner_g_o;
	wire [OUT_COLOR_DEPTH - 1:0] cleaner_b_o;
	wire cleaner_hs_o;
	wire cleaner_vs_o;
	wire cleaner_hb_o;
	wire cleaner_vb_o;
	video_cleaner #(.COLOR_DEPTH(OUT_COLOR_DEPTH)) video_cleaner(
		.clk_vid(clk_sys),
		.ce_pix((scandoubler_disable ? 1'b1 : cofi_pixel_ena)),
		.enable(VIDEO_CLEANER),
		.R(cofi_r),
		.G(cofi_g),
		.B(cofi_b),
		.HSync(cofi_hs),
		.VSync(cofi_vs),
		.HBlank(cofi_hb),
		.VBlank(cofi_vb),
		.VGA_R(cleaner_r_o),
		.VGA_G(cleaner_g_o),
		.VGA_B(cleaner_b_o),
		.VGA_VS(cleaner_vs_o),
		.VGA_HS(cleaner_hs_o),
		.HBlank_out(cleaner_hb_o),
		.VBlank_out(cleaner_vb_o)
	);
	wire hs;
	wire vs;
	wire cs;
	wire hb;
	wire vb;
	wire [OUT_COLOR_DEPTH - 1:0] r;
	wire [OUT_COLOR_DEPTH - 1:0] g;
	wire [OUT_COLOR_DEPTH - 1:0] b;
	RGBtoYPbPr #(.WIDTH(OUT_COLOR_DEPTH)) rgb2ypbpr(
		.clk(clk_sys),
		.ena(ypbpr),
		.red_in(cleaner_r_o),
		.green_in(cleaner_g_o),
		.blue_in(cleaner_b_o),
		.hs_in(cleaner_hs_o),
		.vs_in(cleaner_vs_o),
		.cs_in((SYNC_AND ? cleaner_hs_o & cleaner_vs_o : ~(cleaner_hs_o ^ cleaner_vs_o))),
		.hb_in(cleaner_hb_o),
		.vb_in(cleaner_vb_o),
		.red_out(r),
		.green_out(g),
		.blue_out(b),
		.hs_out(hs),
		.vs_out(vs),
		.cs_out(cs),
		.hb_out(hb),
		.vb_out(vb)
	);
	always @(posedge clk_sys) begin
		VGA_R <= r;
		VGA_G <= g;
		VGA_B <= b;
		VGA_HS <= ((~no_csync & scandoubler_disable) || ypbpr ? cs : hs);
		VGA_VS <= ((~no_csync & scandoubler_disable) || ypbpr ? 1'b1 : vs);
		VGA_HB <= hb;
		VGA_VB <= vb;
		VGA_DE <= ~(hb | vb);
	end
endmodule
