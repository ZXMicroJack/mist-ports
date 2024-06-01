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
