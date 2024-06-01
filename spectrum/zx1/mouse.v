module mouse (
	clk_sys,
	reset,
	ps2_mouse,
	addr,
	sel,
	dout
);
	input clk_sys;
	input reset;
	input [24:0] ps2_mouse;
	input [2:0] addr;
	output wire sel;
	output wire [7:0] dout;
	reg [7:0] data;
	assign dout = data;
	reg port_sel;
	assign sel = port_sel;
	reg [1:0] button;
	reg mbutton;
	reg [11:0] dx;
	reg [11:0] dy;
	wire [11:0] newdx = dx + {{4 {ps2_mouse[4]}}, ps2_mouse[15:8]};
	wire [11:0] newdy = dy + {{4 {ps2_mouse[5]}}, ps2_mouse[23:16]};
	reg [1:0] swap;
	always @(*) begin
		port_sel = 1;
		casex (addr)
			3'b011: data = dx[7:0];
			3'b111: data = dy[7:0];
			3'bx10: data = ~{5'b00000, mbutton, button[swap[1]], button[~swap[1]]};
			default: {port_sel, data} = 8'hff;
		endcase
	end
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_status;
		old_status <= ps2_mouse[24];
		if (reset) begin
			dx <= 128;
			dy <= 0;
			button <= 0;
			swap <= 0;
		end
		else if (old_status != ps2_mouse[24]) begin
			if (!swap)
				swap <= ps2_mouse[1:0];
			{mbutton, button} <= ps2_mouse[2:0];
			dx <= newdx;
			dy <= newdy;
		end
	end
endmodule
