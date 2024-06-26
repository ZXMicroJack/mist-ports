(* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) module RGBtoYPbPr (
	clk,
	ena,
	red_in,
	green_in,
	blue_in,
	hs_in,
	vs_in,
	hb_in,
	vb_in,
	cs_in,
	pixel_in,
	red_out,
	green_out,
	blue_out,
	hs_out,
	vs_out,
	hb_out,
	vb_out,
	cs_out,
	pixel_out
);
	input clk;
	input ena;
	parameter WIDTH = 8;
	input [WIDTH - 1:0] red_in;
	input [WIDTH - 1:0] green_in;
	input [WIDTH - 1:0] blue_in;
	input hs_in;
	input vs_in;
	input hb_in;
	input vb_in;
	input cs_in;
	input pixel_in;
	output wire [WIDTH - 1:0] red_out;
	output wire [WIDTH - 1:0] green_out;
	output wire [WIDTH - 1:0] blue_out;
	output reg hs_out;
	output reg vs_out;
	output reg hb_out;
	output reg vb_out;
	output reg cs_out;
	output reg pixel_out;
	reg [(8 + WIDTH) - 1:0] r_y;
	reg [(8 + WIDTH) - 1:0] g_y;
	reg [(8 + WIDTH) - 1:0] b_y;
	reg [(8 + WIDTH) - 1:0] r_b;
	reg [(8 + WIDTH) - 1:0] g_b;
	reg [(8 + WIDTH) - 1:0] b_b;
	reg [(8 + WIDTH) - 1:0] r_r;
	reg [(8 + WIDTH) - 1:0] g_r;
	reg [(8 + WIDTH) - 1:0] b_r;
	reg [(8 + WIDTH) - 1:0] y;
	reg [(8 + WIDTH) - 1:0] b;
	reg [(8 + WIDTH) - 1:0] r;
	reg hs_d;
	reg vs_d;
	reg cs_d;
	reg pixel_d;
	reg hb_d;
	reg vb_d;
	assign red_out = r[(8 + WIDTH) - 1:8];
	assign green_out = y[(8 + WIDTH) - 1:8];
	assign blue_out = b[(8 + WIDTH) - 1:8];
	always @(posedge clk) begin
		hs_d <= hs_in;
		vs_d <= vs_in;
		cs_d <= cs_in;
		pixel_d <= pixel_in;
		hb_d <= hb_in;
		vb_d <= vb_in;
		if (ena) begin
			r_y <= red_in * 8'd76;
			g_y <= green_in * 8'd150;
			b_y <= blue_in * 8'd29;
			r_b <= red_in * 8'd43;
			g_b <= green_in * 8'd84;
			b_b <= blue_in * 8'd128;
			r_r <= red_in * 8'd128;
			g_r <= green_in * 8'd107;
			b_r <= blue_in * 8'd20;
		end
		else begin
			r_r[(8 + WIDTH) - 1:8] <= red_in;
			g_y[(8 + WIDTH) - 1:8] <= green_in;
			b_b[(8 + WIDTH) - 1:8] <= blue_in;
		end
	end
	always @(posedge clk) begin
		hs_out <= hs_d;
		vs_out <= vs_d;
		cs_out <= cs_d;
		pixel_out <= pixel_d;
		hb_out <= hb_d;
		vb_out <= vb_d;
		if (ena) begin
			y <= (r_y + g_y) + b_y;
			b <= (((2'd2 ** ((8 + WIDTH) - 1)) + b_b) - r_b) - g_b;
			r <= (((2'd2 ** ((8 + WIDTH) - 1)) + r_r) - g_r) - b_r;
		end
		else begin
			y <= g_y;
			b <= b_b;
			r <= r_r;
		end
	end
endmodule
