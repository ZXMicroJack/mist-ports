module video_mixer (
	clk_sys,
	ce_pix,
	ce_pix_actual,
	SPI_SCK,
	SPI_SS3,
	SPI_DI,
	scanlines,
	scandoubler_disable,
	hq2x,
	ypbpr,
	ypbpr_full,
	R,
	G,
	B,
	mono,
	HSync,
	VSync,
	line_start,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_VS,
	VGA_HS
);
	parameter LINE_LENGTH = 768;
	parameter HALF_DEPTH = 0;
	parameter OSD_COLOR = 3'd4;
	parameter OSD_X_OFFSET = 10'd0;
	parameter OSD_Y_OFFSET = 10'd0;
	input clk_sys;
	input ce_pix;
	input ce_pix_actual;
	input SPI_SCK;
	input SPI_SS3;
	input SPI_DI;
	input [1:0] scanlines;
	input scandoubler_disable;
	input hq2x;
	input ypbpr;
	input ypbpr_full;
	localparam DWIDTH = (HALF_DEPTH ? 2 : 5);
	input [DWIDTH:0] R;
	input [DWIDTH:0] G;
	input [DWIDTH:0] B;
	input mono;
	input HSync;
	input VSync;
	input line_start;
	output wire [5:0] VGA_R;
	output wire [5:0] VGA_G;
	output wire [5:0] VGA_B;
	output wire VGA_VS;
	output wire VGA_HS;
	wire [DWIDTH:0] R_sd;
	wire [DWIDTH:0] G_sd;
	wire [DWIDTH:0] B_sd;
	wire hs_sd;
	wire vs_sd;
	scandoubler #(
		.LENGTH(LINE_LENGTH),
		.HALF_DEPTH(HALF_DEPTH)
	) scandoubler(
		.clk_sys(clk_sys),
		.ce_pix(ce_pix),
		.ce_pix_actual(ce_pix_actual),
		.hq2x(hq2x),
		.line_start(line_start),
		.mono(mono),
		.hs_in(HSync),
		.vs_in(VSync),
		.r_in(R),
		.g_in(G),
		.b_in(B),
		.hs_out(hs_sd),
		.vs_out(vs_sd),
		.r_out(R_sd),
		.g_out(G_sd),
		.b_out(B_sd)
	);
	wire [DWIDTH:0] rt = (scandoubler_disable ? R : R_sd);
	wire [DWIDTH:0] gt = (scandoubler_disable ? G : G_sd);
	wire [DWIDTH:0] bt = (scandoubler_disable ? B : B_sd);
	wire [5:0] r = (mono ? {gt, rt} : {rt, rt});
	wire [5:0] g = (mono ? {gt, rt} : {gt, gt});
	wire [5:0] b = (mono ? {gt, rt} : {bt, bt});
	wire hs = (scandoubler_disable ? HSync : hs_sd);
	wire vs = (scandoubler_disable ? VSync : vs_sd);
	reg scanline = 0;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_hs;
		reg old_vs;
		old_hs <= hs;
		old_vs <= vs;
		if (old_hs && ~hs)
			scanline <= ~scanline;
		if (old_vs && ~vs)
			scanline <= 0;
	end
	reg [5:0] r_out;
	reg [5:0] g_out;
	reg [5:0] b_out;
	always @(*)
		case (scanlines & {scanline, scanline})
			1: begin
				r_out = {1'b0, r[5:1]} + {2'b00, r[5:2]};
				g_out = {1'b0, g[5:1]} + {2'b00, g[5:2]};
				b_out = {1'b0, b[5:1]} + {2'b00, b[5:2]};
			end
			2: begin
				r_out = {1'b0, r[5:1]};
				g_out = {1'b0, g[5:1]};
				b_out = {1'b0, b[5:1]};
			end
			3: begin
				r_out = {2'b00, r[5:2]};
				g_out = {2'b00, g[5:2]};
				b_out = {2'b00, b[5:2]};
			end
			default: begin
				r_out = r;
				g_out = g;
				b_out = b;
			end
		endcase
	reg [3:0] i_div;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg last_hsync;
		last_hsync <= HSync;
		if (last_hsync & !HSync)
			i_div <= 4'd0;
		else
			i_div <= i_div + 4'd1;
	end
	wire osd_pix_ce = (scandoubler_disable ? i_div == 4'b0001 : i_div[2:0] == 3'b001);
	wire [5:0] red;
	wire [5:0] green;
	wire [5:0] blue;
	osd #(
		.OSD_X_OFFSET(OSD_X_OFFSET),
		.OSD_Y_OFFSET(OSD_Y_OFFSET),
		.OSD_COLOR(OSD_COLOR),
		.OSD_AUTO_CE(1'b0)
	) osd(
		.clk_sys(clk_sys),
		.SPI_SCK(SPI_SCK),
		.SPI_SS3(SPI_SS3),
		.SPI_DI(SPI_DI),
		.ce(osd_pix_ce),
		.rotate(0),
		.R_in(r_out),
		.G_in(g_out),
		.B_in(b_out),
		.HSync(hs),
		.VSync(vs),
		.R_out(red),
		.G_out(green),
		.B_out(blue)
	);
	wire [1349:0] yuv_full = 1350'h10410420820c30c31041051451461861c71c720820924924a28a2cb2cb30c30d34d34e38e3cf3cf4104114514524924d34d35145155555565965d75d761861965965a69a6db6db71c71d75d75e79e7df7df8208218618628a28e38e39249249659669a69a79e7a28a28a69a6aaaaaabaebb2cb2cb6db6ebaebafbefc30c30c71c72cb2cb3cf3d34d34d75d76db6db7df7e38e38e79e7aebaebbefbf3cf3cf7df7efbefbffff;
	wire [18:0] y_8 = ((19'd4096 + ({red, 8'd0} + {red, 3'd0})) + ({green, 9'd0} + {green, 2'd0})) + (({blue, 6'd0} + {blue, 5'd0}) + {blue, 2'd0});
	wire [18:0] pb_8 = ((19'd32768 - (({red, 7'd0} + {red, 4'd0}) + {red, 3'd0})) - (({green, 8'd0} + {green, 5'd0}) + {green, 3'd0})) + (({blue, 8'd0} + {blue, 7'd0}) + {blue, 6'd0});
	wire [18:0] pr_8 = ((19'd32768 + (({red, 8'd0} + {red, 7'd0}) + {red, 6'd0})) - (((({green, 8'd0} + {green, 6'd0}) + {green, 5'd0}) + {green, 4'd0}) + {green, 3'd0})) - ({blue, 6'd0} + {blue, 3'd0});
	wire [7:0] y = (y_8[17:8] < 16 ? 8'd16 : (y_8[17:8] > 235 ? 8'd235 : y_8[15:8]));
	wire [7:0] pb = (pb_8[17:8] < 16 ? 8'd16 : (pb_8[17:8] > 240 ? 8'd240 : pb_8[15:8]));
	wire [7:0] pr = (pr_8[17:8] < 16 ? 8'd16 : (pr_8[17:8] > 240 ? 8'd240 : pr_8[15:8]));
	assign VGA_R = (ypbpr ? (ypbpr_full ? yuv_full[((224 + 8'd16) - pr) * 6+:6] : pr[7:2]) : red);
	assign VGA_G = (ypbpr ? (ypbpr_full ? yuv_full[((224 + 8'd16) - y) * 6+:6] : y[7:2]) : green);
	assign VGA_B = (ypbpr ? (ypbpr_full ? yuv_full[((224 + 8'd16) - pb) * 6+:6] : pb[7:2]) : blue);
	assign VGA_VS = (scandoubler_disable | ypbpr ? 1'b1 : ~vs_sd);
	assign VGA_HS = (scandoubler_disable ? ~(HSync ^ VSync) : (ypbpr ? ~(hs_sd ^ vs_sd) : ~hs_sd));
endmodule
