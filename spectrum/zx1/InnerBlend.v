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
