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
	input wire [5:0] rule;
	input wire disable_hq2x;
	input wire [17:0] E;
	input wire [17:0] A;
	input wire [17:0] B;
	input wire [17:0] D;
	input wire [17:0] F;
	input wire [17:0] H;
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
