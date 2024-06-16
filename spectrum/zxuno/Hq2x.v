module Hq2x (
	clk,
	ce_x4,
	inputpixel,
	mono,
	disable_hq2x,
	reset_frame,
	reset_line,
	read_y,
	read_x,
	outpixel
);
	reg _sv2v_0;
	parameter LENGTH = 0;
	parameter HALF_DEPTH = 0;
	input clk;
	input ce_x4;
	localparam DWIDTH = (HALF_DEPTH ? 8 : 17);
	input [DWIDTH:0] inputpixel;
	input mono;
	input disable_hq2x;
	input reset_frame;
	input reset_line;
	input [1:0] read_y;
	localparam AWIDTH = (LENGTH <= 2 ? 0 : (LENGTH <= 4 ? 1 : (LENGTH <= 8 ? 2 : (LENGTH <= 16 ? 3 : (LENGTH <= 32 ? 4 : (LENGTH <= 64 ? 5 : (LENGTH <= 128 ? 6 : (LENGTH <= 256 ? 7 : (LENGTH <= 512 ? 8 : (LENGTH <= 1024 ? 9 : 10))))))))));
	input [AWIDTH + 1:0] read_x;
	output wire [DWIDTH:0] outpixel;
	wire [1535:0] hqTable = 1536'h4d368b4d368b5cfbe35cfde74d36ba4d36ba5cf8e35cf1e34d368b4d368b5cfde75cfceb4d36ba4d36ba5cfce35cf1eb4d368b4d368b5fd8e35fdce34d368b4d368b5cfce35cfce34d368b4d368b5fd1e35fd1eb4d368b4d36ba5cfce35fd1eb4d368b4d368b5cfbe35cfde74d368b4d368b5cfce35cfce34d368b4d368b5cfde75cfceb4d368b4d368b5cfce75cf1eb4d368b4d368b5cfce35cfce74d368b4d368b5cfce35cf1e34d368b4d368b5cfce35cf1eb4d368b4d368b5cf1e35cf1eb;
	reg [17:0] Prev0;
	reg [17:0] Prev1;
	reg [17:0] Prev2;
	reg [17:0] Curr0;
	reg [17:0] Curr1;
	reg [17:0] Next0;
	reg [17:0] Next1;
	reg [17:0] Next2;
	reg [17:0] A;
	reg [17:0] B;
	reg [17:0] D;
	reg [17:0] F;
	reg [17:0] G;
	reg [17:0] H;
	reg [7:0] pattern;
	reg [7:0] nextpatt;
	reg [1:0] i;
	reg [7:0] y;
	wire curbuf = y[0];
	reg prevbuf = 0;
	wire iobuf = !curbuf;
	wire diff0;
	wire diff1;
	DiffCheck diffcheck0(
		.rgb1(Curr1),
		.rgb2((i == 0 ? Prev0 : (i == 1 ? Curr0 : (i == 2 ? Prev2 : Next1)))),
		.result(diff0)
	);
	wire [DWIDTH:0] Curr2tmp;
	function [17:0] h2rgb;
		input [8:0] v;
		h2rgb = (mono ? {v[5:3], v[2:0], v[5:3], v[2:0], v[5:3], v[2:0]} : {v[8:6], v[8:6], v[5:3], v[5:3], v[2:0], v[2:0]});
	endfunction
	wire [17:0] Curr2 = (HALF_DEPTH ? h2rgb(Curr2tmp) : Curr2tmp);
	DiffCheck diffcheck1(
		.rgb1(Curr1),
		.rgb2((i == 0 ? Prev1 : (i == 1 ? Next0 : (i == 2 ? Curr2 : Next2)))),
		.result(diff1)
	);
	wire [7:0] new_pattern = {diff1, diff0, pattern[7:2]};
	wire [17:0] X = (i == 0 ? A : (i == 1 ? Prev1 : (i == 2 ? Next1 : G)));
	wire [17:0] blend_result;
	Blend blender(
		.rule(hqTable[(255 - nextpatt) * 6+:6]),
		.disable_hq2x(disable_hq2x),
		.E(Curr0),
		.A(X),
		.B(B),
		.D(D),
		.F(F),
		.H(H),
		.Result(blend_result)
	);
	reg Curr2_addr1;
	reg [AWIDTH:0] Curr2_addr2;
	reg [AWIDTH:0] wrin_addr2;
	reg [DWIDTH:0] wrpix;
	reg wrin_en;
	function [8:0] rgb2h;
		input [17:0] v;
		rgb2h = (mono ? {3'b000, v[17:15], v[14:12]} : {v[17:15], v[11:9], v[5:3]});
	endfunction
	hq2x_in #(
		.LENGTH(LENGTH),
		.DWIDTH(DWIDTH)
	) hq2x_in(
		.clk(clk),
		.rdaddr(Curr2_addr2),
		.rdbuf(Curr2_addr1),
		.q(Curr2tmp),
		.wraddr(wrin_addr2),
		.wrbuf(iobuf),
		.data(wrpix),
		.wren(wrin_en)
	);
	reg [1:0] wrout_addr1;
	reg [AWIDTH + 1:0] wrout_addr2;
	reg wrout_en;
	reg [DWIDTH:0] wrdata;
	hq2x_out #(
		.LENGTH(LENGTH),
		.DWIDTH(DWIDTH)
	) hq2x_out(
		.clk(clk),
		.rdaddr(read_x),
		.rdbuf(read_y),
		.q(outpixel),
		.wraddr(wrout_addr2),
		.wrbuf(wrout_addr1),
		.data(wrdata),
		.wren(wrout_en)
	);
	always @(posedge clk) begin : sv2v_autoblock_1
		reg [AWIDTH:0] offs;
		reg old_reset_line;
		reg old_reset_frame;
		wrout_en <= 0;
		wrin_en <= 0;
		if (ce_x4) begin
			pattern <= new_pattern;
			if (~&offs) begin
				if (i == 0) begin
					Curr2_addr1 <= prevbuf;
					Curr2_addr2 <= offs;
				end
				if (i == 1) begin
					Prev2 <= Curr2;
					Curr2_addr1 <= curbuf;
					Curr2_addr2 <= offs;
				end
				if (i == 2) begin
					Next2 <= (HALF_DEPTH ? h2rgb(inputpixel) : inputpixel);
					wrpix <= inputpixel;
					wrin_addr2 <= offs;
					wrin_en <= 1;
				end
				if (i == 3)
					offs <= offs + 1'd1;
				if (HALF_DEPTH)
					wrdata <= rgb2h(blend_result);
				else
					wrdata <= blend_result;
				wrout_addr1 <= {curbuf, i[1]};
				wrout_addr2 <= {offs, i[1] ^ i[0]};
				wrout_en <= 1;
			end
			if (i == 3) begin
				nextpatt <= {new_pattern[7:6], new_pattern[3], new_pattern[5], new_pattern[2], new_pattern[4], new_pattern[1:0]};
				{A, G} <= {Prev0, Next0};
				{B, F, H, D} <= {Prev1, Curr2, Next1, Curr0};
				{Prev0, Prev1} <= {Prev1, Prev2};
				{Curr0, Curr1} <= {Curr1, Curr2};
				{Next0, Next1} <= {Next1, Next2};
			end
			else begin
				nextpatt <= {nextpatt[5], nextpatt[3], nextpatt[0], nextpatt[6], nextpatt[1], nextpatt[7], nextpatt[4], nextpatt[2]};
				{B, F, H, D} <= {F, H, D, B};
			end
			i <= i + 1'b1;
			if (old_reset_line && ~reset_line) begin
				old_reset_frame <= reset_frame;
				offs <= 0;
				i <= 0;
				y <= y + 1'd1;
				prevbuf <= curbuf;
				if (old_reset_frame & ~reset_frame) begin
					y <= 0;
					prevbuf <= 0;
				end
			end
			old_reset_line <= reset_line;
		end
	end
	initial _sv2v_0 = 0;
endmodule
