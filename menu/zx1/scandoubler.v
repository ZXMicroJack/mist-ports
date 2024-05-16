module scandoubler (
	clk_sys,
	bypass,
	ce_divider,
	pixel_ena,
	scanlines,
	hb_in,
	vb_in,
	hs_in,
	vs_in,
	r_in,
	g_in,
	b_in,
	hb_out,
	vb_out,
	hs_out,
	vs_out,
	r_out,
	g_out,
	b_out
);
	input clk_sys;
	input bypass;
	input [2:0] ce_divider;
	output wire pixel_ena;
	input [1:0] scanlines;
	input hb_in;
	input vb_in;
	input hs_in;
	input vs_in;
	parameter COLOR_DEPTH = 6;
	input [COLOR_DEPTH - 1:0] r_in;
	input [COLOR_DEPTH - 1:0] g_in;
	input [COLOR_DEPTH - 1:0] b_in;
	output wire hb_out;
	output wire vb_out;
	output wire hs_out;
	output wire vs_out;
	parameter OUT_COLOR_DEPTH = 6;
	output wire [OUT_COLOR_DEPTH - 1:0] r_out;
	output wire [OUT_COLOR_DEPTH - 1:0] g_out;
	output wire [OUT_COLOR_DEPTH - 1:0] b_out;
	parameter HCNT_WIDTH = 9;
	parameter HSCNT_WIDTH = 12;
	reg scanline;
	reg [OUT_COLOR_DEPTH - 1:0] r;
	reg [OUT_COLOR_DEPTH - 1:0] g;
	reg [OUT_COLOR_DEPTH - 1:0] b;
	reg [(COLOR_DEPTH * 3) - 1:0] sd_out;
	wire [(COLOR_DEPTH * 3) - 1:0] sd_mux = (bypass ? {r_in, g_in, b_in} : sd_out[(COLOR_DEPTH * 3) - 1:0]);
	localparam m = OUT_COLOR_DEPTH / COLOR_DEPTH;
	localparam n = OUT_COLOR_DEPTH % COLOR_DEPTH;
	always @(*)
		if (n > 0) begin
			b = {{m {sd_mux[COLOR_DEPTH - 1:0]}}, sd_mux[COLOR_DEPTH - 1-:n]};
			g = {{m {sd_mux[(COLOR_DEPTH * 2) - 1:COLOR_DEPTH]}}, sd_mux[(COLOR_DEPTH * 2) - 1-:n]};
			r = {{m {sd_mux[(COLOR_DEPTH * 3) - 1:COLOR_DEPTH * 2]}}, sd_mux[(COLOR_DEPTH * 3) - 1-:n]};
		end
		else begin
			b = {m {sd_mux[COLOR_DEPTH - 1:0]}};
			g = {m {sd_mux[(COLOR_DEPTH * 2) - 1:COLOR_DEPTH]}};
			r = {m {sd_mux[(COLOR_DEPTH * 3) - 1:COLOR_DEPTH * 2]}};
		end
	reg [OUT_COLOR_DEPTH + 6:0] r_mul;
	reg [OUT_COLOR_DEPTH + 6:0] g_mul;
	reg [OUT_COLOR_DEPTH + 6:0] b_mul;
	reg hb_o;
	reg vb_o;
	reg hs_o;
	reg vs_o;
	wire scanline_bypass = (!scanline | !(|scanlines)) | bypass;
	wire [6:0] scanline_coeff = (scanline_bypass ? 7'b1000000 : {~(&scanlines), scanlines[0], 1'b1, ~scanlines[0], 2'b10});
	reg [2:0] ce_divider_out;
	reg [2:0] sd_i_div;
	wire ce_x2 = (sd_i_div == ce_divider_out) | (sd_i_div == {1'b0, ce_divider_out[2:1]});
	reg hb_sd = 0;
	reg hs_sd = 0;
	reg vb_sd = 0;
	reg vs_sd = 0;
	always @(posedge clk_sys)
		if (ce_x2) begin
			hs_o <= hs_sd;
			vs_o <= vs_sd;
			hb_o <= hb_sd;
			vb_o <= vb_sd;
			if (vs_o != vs_in)
				scanline <= 0;
			if (hs_o && !hs_sd)
				scanline <= !scanline;
			r_mul <= r * scanline_coeff;
			g_mul <= g * scanline_coeff;
			b_mul <= b * scanline_coeff;
		end
	wire [OUT_COLOR_DEPTH - 1:0] r_o = r_mul[OUT_COLOR_DEPTH + 5-:OUT_COLOR_DEPTH];
	wire [OUT_COLOR_DEPTH - 1:0] g_o = g_mul[OUT_COLOR_DEPTH + 5-:OUT_COLOR_DEPTH];
	wire [OUT_COLOR_DEPTH - 1:0] b_o = b_mul[OUT_COLOR_DEPTH + 5-:OUT_COLOR_DEPTH];
	wire blank_out = hb_out | vb_out;
	assign r_out = (blank_out ? {OUT_COLOR_DEPTH {1'b0}} : (bypass ? r : r_o));
	assign g_out = (blank_out ? {OUT_COLOR_DEPTH {1'b0}} : (bypass ? g : g_o));
	assign b_out = (blank_out ? {OUT_COLOR_DEPTH {1'b0}} : (bypass ? b : b_o));
	assign hb_out = (bypass ? hb_in : hb_o);
	assign vb_out = (bypass ? vb_in : vb_o);
	assign hs_out = (bypass ? hs_in : hs_o);
	assign vs_out = (bypass ? vs_in : vs_o);
	(* ramstyle = "no_rw_check" *) reg [(COLOR_DEPTH * 3) - 1:0] sd_buffer [0:(2 * (2 ** HCNT_WIDTH)) - 1];
	reg line_toggle;
	reg [HCNT_WIDTH - 1:0] hcnt;
	reg [HSCNT_WIDTH:0] hs_max;
	reg [HSCNT_WIDTH:0] hs_rise;
	reg [HCNT_WIDTH:0] hb_fall [0:1];
	reg [HCNT_WIDTH:0] hb_rise [0:1];
	reg [HCNT_WIDTH + 1:0] vb_event [0:1];
	reg [HCNT_WIDTH + 1:0] vs_event [0:1];
	reg [HSCNT_WIDTH:0] synccnt;
	wire [2:0] ce_divider_adj = (|ce_divider ? ce_divider : 3'd3);
	reg [2:0] ce_divider_in;
	reg [2:0] i_div;
	wire ce_x1 = i_div == ce_divider_in;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg hsD;
		reg vsD;
		reg vbD;
		reg hbD;
		if (ce_x1) begin
			hcnt <= hcnt + 1'd1;
			vsD <= vs_in;
			vbD <= vb_in;
			sd_buffer[{line_toggle, hcnt}] <= {r_in, g_in, b_in};
			if (vbD ^ vb_in)
				vb_event[line_toggle] <= {1'b1, vb_in, hcnt};
			if (vsD ^ vs_in)
				vs_event[line_toggle] <= {1'b1, vs_in, hcnt};
			hbD <= hb_in;
			if (!hbD && hb_in)
				hb_rise[line_toggle] <= {1'b1, hcnt};
			if (hbD && !hb_in)
				hb_fall[line_toggle] <= {1'b1, hcnt};
		end
		i_div <= i_div + 1'd1;
		if (i_div == ce_divider_adj)
			i_div <= 3'b000;
		synccnt <= synccnt + 1'd1;
		hsD <= hs_in;
		if (hsD && !hs_in) begin
			ce_divider_out <= ce_divider_in;
			ce_divider_in <= ce_divider_adj;
			hs_max <= {1'b0, synccnt[HSCNT_WIDTH:1]};
			hcnt <= 0;
			synccnt <= 0;
			i_div <= 3'b000;
		end
		if (!hsD && hs_in)
			hs_rise <= {1'b0, synccnt[HSCNT_WIDTH:1]};
		if (hsD && !hs_in) begin
			line_toggle <= !line_toggle;
			vb_event[!line_toggle] <= 0;
			vs_event[!line_toggle] <= 0;
			hb_rise[!line_toggle][HCNT_WIDTH] <= 0;
			hb_fall[!line_toggle][HCNT_WIDTH] <= 0;
		end
	end
	reg [HSCNT_WIDTH:0] sd_synccnt;
	reg [HCNT_WIDTH - 1:0] sd_hcnt;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg hsD;
		if (ce_x2) begin
			sd_hcnt <= sd_hcnt + 1'd1;
			sd_out <= sd_buffer[{~line_toggle, sd_hcnt}];
			if (vb_event[~line_toggle][HCNT_WIDTH + 1] && (sd_hcnt == vb_event[~line_toggle][HCNT_WIDTH - 1:0]))
				vb_sd <= vb_event[~line_toggle][HCNT_WIDTH];
			if (vs_event[~line_toggle][HCNT_WIDTH + 1] && (sd_hcnt == vs_event[~line_toggle][HCNT_WIDTH - 1:0]))
				vs_sd <= vs_event[~line_toggle][HCNT_WIDTH];
			if (hb_rise[~line_toggle][HCNT_WIDTH] && (sd_hcnt == hb_rise[~line_toggle][HCNT_WIDTH - 1:0]))
				hb_sd <= 1;
			if (hb_fall[~line_toggle][HCNT_WIDTH] && (sd_hcnt == hb_fall[~line_toggle][HCNT_WIDTH - 1:0]))
				hb_sd <= 0;
		end
		sd_i_div <= sd_i_div + 1'd1;
		if (sd_i_div == ce_divider_adj)
			sd_i_div <= 3'b000;
		sd_synccnt <= sd_synccnt + 1'd1;
		hsD <= hs_in;
		if ((sd_synccnt == hs_max) || (hsD && !hs_in)) begin
			sd_synccnt <= 0;
			sd_hcnt <= 0;
			hs_sd <= 0;
			sd_i_div <= 3'b000;
		end
		if (sd_synccnt == hs_rise)
			hs_sd <= 1;
	end
	wire ce_x4 = sd_i_div[0];
	assign pixel_ena = (ce_divider_out > 3'd5 ? (bypass ? ce_x2 : ce_x4) : (bypass ? ce_x1 : ce_x2));
endmodule
