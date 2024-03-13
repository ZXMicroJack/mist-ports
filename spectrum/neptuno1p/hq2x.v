module hq2x_in (
	clk,
	rdaddr,
	rdbuf,
	q,
	wraddr,
	wrbuf,
	data,
	wren
);
	parameter LENGTH = 0;
	parameter DWIDTH = 0;
	input clk;
	localparam AWIDTH = (LENGTH <= 2 ? 0 : (LENGTH <= 4 ? 1 : (LENGTH <= 8 ? 2 : (LENGTH <= 16 ? 3 : (LENGTH <= 32 ? 4 : (LENGTH <= 64 ? 5 : (LENGTH <= 128 ? 6 : (LENGTH <= 256 ? 7 : (LENGTH <= 512 ? 8 : (LENGTH <= 1024 ? 9 : 10))))))))));
	input [AWIDTH:0] rdaddr;
	input rdbuf;
	output wire [DWIDTH:0] q;
	input [AWIDTH:0] wraddr;
	input wrbuf;
	input [DWIDTH:0] data;
	input wren;
	wire [DWIDTH:0] out [0:1];
	assign q = out[rdbuf];
	hq2x_buf #(
		.NUMWORDS(LENGTH),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf0(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 0)),
		.q(out[0])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf1(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 1)),
		.q(out[1])
	);
endmodule
module hq2x_out (
	clk,
	rdaddr,
	rdbuf,
	q,
	wraddr,
	wrbuf,
	data,
	wren
);
	parameter LENGTH = 0;
	parameter DWIDTH = 0;
	input clk;
	localparam AWIDTH = ((LENGTH * 2) <= 2 ? 0 : ((LENGTH * 2) <= 4 ? 1 : ((LENGTH * 2) <= 8 ? 2 : ((LENGTH * 2) <= 16 ? 3 : ((LENGTH * 2) <= 32 ? 4 : ((LENGTH * 2) <= 64 ? 5 : ((LENGTH * 2) <= 128 ? 6 : ((LENGTH * 2) <= 256 ? 7 : ((LENGTH * 2) <= 512 ? 8 : ((LENGTH * 2) <= 1024 ? 9 : 10))))))))));
	input [AWIDTH:0] rdaddr;
	input [1:0] rdbuf;
	output wire [DWIDTH:0] q;
	input [AWIDTH:0] wraddr;
	input [1:0] wrbuf;
	input [DWIDTH:0] data;
	input wren;
	wire [DWIDTH:0] out [0:3];
	assign q = out[rdbuf];
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf0(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 0)),
		.q(out[0])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf1(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 1)),
		.q(out[1])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf2(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 2)),
		.q(out[2])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf3(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 3)),
		.q(out[3])
	);
endmodule
module hq2x_buf (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q
);
	parameter NUMWORDS = 0;
	parameter AWIDTH = 0;
	parameter DWIDTH = 0;
	input clock;
	input [DWIDTH:0] data;
	input [AWIDTH:0] rdaddress;
	input [AWIDTH:0] wraddress;
	input wren;
	output wire [DWIDTH:0] q;
	
   reg[DWIDTH:0] mem [0:NUMWORDS-1] /* synthesis ramstyle = "M144K" */;
   reg[AWIDTH:0] address_latched;
   
   always @(posedge clock) begin
     if (wren)
         mem[wraddress] <= data;
      address_latched <= rdaddress;
   end

   assign q = mem[address_latched];

	
endmodule
module DiffCheck (
	rgb1,
	rgb2,
	result
);
	input [17:0] rgb1;
	input [17:0] rgb2;
	output wire result;
	wire [5:0] r = rgb1[5:1] - rgb2[5:1];
	wire [5:0] g = rgb1[11:7] - rgb2[11:7];
	wire [5:0] b = rgb1[17:13] - rgb2[17:13];
	wire [6:0] t = $signed(r) + $signed(b);
	wire [6:0] gx = {g[5], g};
	wire [7:0] y = $signed(t) + $signed(gx);
	wire [6:0] u = $signed(r) - $signed(b);
	wire [7:0] v = $signed({g, 1'b0}) - $signed(t);
	wire y_inside = (y < 8'h18) || (y >= 8'he8);
	wire u_inside = (u < 7'h04) || (u >= 7'h7c);
	wire v_inside = (v < 8'h06) || (v >= 8'hfa);
	assign result = !((y_inside && u_inside) && v_inside);
endmodule
module InnerBlend (
	Op,
	A,
	B,
	C,
	O
);
	input [8:0] Op;
	input [5:0] A;
	input [5:0] B;
	input [5:0] C;
	output wire [5:0] O;
	function [8:0] mul6x3;
		input [5:0] op1;
		input [2:0] op2;
		begin
			mul6x3 = 9'd0;
			if (op2[0])
				mul6x3 = mul6x3 + op1;
			if (op2[1])
				mul6x3 = mul6x3 + {op1, 1'b0};
			if (op2[2])
				mul6x3 = mul6x3 + {op1, 2'b00};
		end
	endfunction
	wire OpOnes = Op[4];
	wire [8:0] Amul = mul6x3(A, Op[7:5]);
	wire [8:0] Bmul = mul6x3(B, {Op[3:2], 1'b0});
	wire [8:0] Cmul = mul6x3(C, {Op[1:0], 1'b0});
	wire [8:0] At = Amul;
	wire [8:0] Bt = (OpOnes == 0 ? Bmul : {3'b000, B});
	wire [8:0] Ct = (OpOnes == 0 ? Cmul : {3'b000, C});
	wire [9:0] Res = ({At, 1'b0} + Bt) + Ct;
	assign O = (Op[8] ? A : Res[9:4]);
endmodule
module Blend (
	rule,
	disable_hq2x,
	E,
	A,
	B,
	D,
	F,
	H,
	Result
);
	input [5:0] rule;
	input disable_hq2x;
	input [17:0] E;
	input [17:0] A;
	input [17:0] B;
	input [17:0] D;
	input [17:0] F;
	input [17:0] H;
	output wire [17:0] Result;
	reg [1:0] input_ctrl;
	reg [8:0] op;
	localparam BLEND0 = 9'b1xxxxxxxx;
	localparam BLEND1 = 9'b011001000;
	localparam BLEND2 = 9'b010001010;
	localparam BLEND3 = 9'b010101001;
	localparam BLEND4 = 9'b011000101;
	localparam BLEND5 = 9'b001001111;
	localparam BLEND6 = 9'b01111xxxx;
	localparam AB = 2'b00;
	localparam AD = 2'b01;
	localparam DB = 2'b10;
	localparam BD = 2'b11;
	wire is_diff;
	DiffCheck diff_checker(
		.rgb1((rule[1] ? B : H)),
		.rgb2((rule[0] ? D : F)),
		.result(is_diff)
	);
	always @(*) begin
		case ({!is_diff, rule[5:2]})
			1, 17: {op, input_ctrl} = {BLEND1, AB};
			2, 18: {op, input_ctrl} = {BLEND1, DB};
			3, 19: {op, input_ctrl} = {BLEND1, BD};
			4, 20: {op, input_ctrl} = {BLEND2, DB};
			5, 21: {op, input_ctrl} = {BLEND2, AB};
			6, 22: {op, input_ctrl} = {BLEND2, AD};
			8: {op, input_ctrl} = {BLEND0, 2'bxx};
			9: {op, input_ctrl} = {BLEND0, 2'bxx};
			10: {op, input_ctrl} = {BLEND0, 2'bxx};
			11: {op, input_ctrl} = {BLEND1, AB};
			12: {op, input_ctrl} = {BLEND1, AB};
			13: {op, input_ctrl} = {BLEND1, AB};
			14: {op, input_ctrl} = {BLEND1, DB};
			15: {op, input_ctrl} = {BLEND1, BD};
			24: {op, input_ctrl} = {BLEND2, DB};
			25: {op, input_ctrl} = {BLEND5, DB};
			26: {op, input_ctrl} = {BLEND6, DB};
			27: {op, input_ctrl} = {BLEND2, DB};
			28: {op, input_ctrl} = {BLEND4, DB};
			29: {op, input_ctrl} = {BLEND5, DB};
			30: {op, input_ctrl} = {BLEND3, BD};
			31: {op, input_ctrl} = {BLEND3, DB};
			default: {op, input_ctrl} = 11'bxxxxxxxxxxx;
		endcase
		if (disable_hq2x)
			op[8] = 1;
	end
	wire [17:0] Input1 = E;
	wire [17:0] Input2 = (!input_ctrl[1] ? A : (!input_ctrl[0] ? D : B));
	wire [17:0] Input3 = (!input_ctrl[0] ? B : D);
	InnerBlend inner_blend1(
		.Op(op),
		.A(Input1[5:0]),
		.B(Input2[5:0]),
		.C(Input3[5:0]),
		.O(Result[5:0])
	);
	InnerBlend inner_blend2(
		.Op(op),
		.A(Input1[11:6]),
		.B(Input2[11:6]),
		.C(Input3[11:6]),
		.O(Result[11:6])
	);
	InnerBlend inner_blend3(
		.Op(op),
		.A(Input1[17:12]),
		.B(Input2[17:12]),
		.C(Input3[17:12]),
		.O(Result[17:12])
	);
endmodule
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
endmodule
