module scandoubler (
	clk_sys,
	ce_pix,
	ce_pix_actual,
	hq2x,
	hs_in,
	vs_in,
	line_start,
	r_in,
	g_in,
	b_in,
	mono,
	hs_out,
	vs_out,
	r_out,
	g_out,
	b_out
);
	parameter LENGTH = 0;
	parameter HALF_DEPTH = 0;
	input clk_sys;
	input ce_pix;
	input ce_pix_actual;
	input hq2x;
	input hs_in;
	input vs_in;
	input line_start;
	localparam DWIDTH = (HALF_DEPTH ? 2 : 5);
	input [DWIDTH:0] r_in;
	input [DWIDTH:0] g_in;
	input [DWIDTH:0] b_in;
	input mono;
	output reg hs_out;
	output wire vs_out;
	output wire [DWIDTH:0] r_out;
	output wire [DWIDTH:0] g_out;
	output wire [DWIDTH:0] b_out;
	assign vs_out = vs_in;
	reg [2:0] phase;
	reg [2:0] ce_div;
	reg [7:0] pix_len = 0;
	wire [7:0] pl = pix_len + 1'b1;
	reg ce_x1;
	reg ce_x4;
	reg req_line_reset;
	wire ls_in = hs_in | line_start;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_ce;
		reg [2:0] ce_cnt;
		reg [7:0] pixsz2;
		reg [7:0] pixsz4 = 0;
		old_ce <= ce_pix;
		if (~&pix_len)
			pix_len <= pix_len + 1'd1;
		ce_x4 <= 0;
		ce_x1 <= 0;
		if (((pl == pixsz4) || (pl == pixsz2)) || (pl == (pixsz2 + pixsz4))) begin
			phase <= phase + 1'd1;
			ce_x4 <= 1;
		end
		if (~old_ce & ce_pix) begin
			pixsz2 <= {1'b0, pl[7:1]};
			pixsz4 <= {2'b00, pl[7:2]};
			ce_x1 <= 1;
			ce_x4 <= 1;
			pix_len <= 0;
			phase <= phase + 1'd1;
			ce_cnt <= ce_cnt + 1'd1;
			if (ce_pix_actual) begin
				phase <= 0;
				ce_div <= ce_cnt + 1'd1;
				ce_cnt <= 0;
				req_line_reset <= 0;
			end
			if (ls_in)
				req_line_reset <= 1;
		end
	end
	reg ce_sd;
	always @(*)
		case (ce_div)
			2: ce_sd <= !phase[0];
			4: ce_sd <= !phase[1:0];
			default: ce_sd <= 1;
		endcase
	localparam AWIDTH = (LENGTH <= 2 ? 0 : (LENGTH <= 4 ? 1 : (LENGTH <= 8 ? 2 : (LENGTH <= 16 ? 3 : (LENGTH <= 32 ? 4 : (LENGTH <= 64 ? 5 : (LENGTH <= 128 ? 6 : (LENGTH <= 256 ? 7 : (LENGTH <= 512 ? 8 : (LENGTH <= 1024 ? 9 : 10))))))))));
	reg [10:0] sd_h_actual;
	reg [1:0] sd_line;
/*	Hq2x #(
		.LENGTH(LENGTH),
		.HALF_DEPTH(HALF_DEPTH)
	) Hq2x(
		.clk(clk_sys),
		.ce_x4(ce_x4 & ce_sd),
		.inputpixel({b_in, g_in, r_in}),
		.mono(mono),
		.disable_hq2x(~hq2x),
		.reset_frame(vs_in),
		.reset_line(req_line_reset),
		.read_y(sd_line),
		.read_x(sd_h_actual),
		.outpixel({b_out, g_out, r_out})
	); */
	
	assign b_out = b_in;
	assign g_out = g_in;
	assign r_out = r_in;
	
	reg [10:0] sd_h;
	always @(*)
		case (ce_div)
			2: sd_h_actual = sd_h[10:1];
			4: sd_h_actual = sd_h[10:2];
			default: sd_h_actual = sd_h;
		endcase
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg [11:0] hs_max;
		reg [11:0] hs_rise;
		reg [11:0] hs_ls;
		reg [10:0] hcnt;
		reg [11:0] sd_hcnt;
		reg hs;
		reg hs2;
		reg vs;
		reg ls;
		if (ce_x1) begin
			hs <= hs_in;
			ls <= ls_in;
			if (ls && !ls_in)
				hs_ls <= {hcnt, 1'b1};
			if (hs && !hs_in) begin
				hs_max <= {hcnt, 1'b1};
				hcnt <= 0;
				if (ls && !ls_in)
					hs_ls <= 11'h001;
			end
			else
				hcnt <= hcnt + 1'd1;
			if (!hs && hs_in)
				hs_rise <= {hcnt, 1'b1};
			vs <= vs_in;
			if (vs && ~vs_in)
				sd_line <= 0;
		end
		if (ce_x4) begin
			hs2 <= hs_in;
			sd_hcnt <= sd_hcnt + 1'd1;
			sd_h <= sd_h + 1'd1;
			if (hs2 && !hs_in)
				sd_hcnt <= hs_max;
			if (sd_hcnt == hs_max)
				sd_hcnt <= 0;
			if (sd_hcnt == hs_max)
				hs_out <= 0;
			if (sd_hcnt == hs_rise)
				hs_out <= 1;
			if (sd_hcnt == hs_ls)
				sd_h <= 0;
			if (sd_hcnt == hs_ls)
				sd_line <= sd_line + 1'd1;
		end
	end
endmodule
