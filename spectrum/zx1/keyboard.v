module keyboard (
	reset,
	clk_sys,
	ps2_key,
	addr,
	key_data,
	Fn,
	mod
);
	input reset;
	input clk_sys;
	input [10:0] ps2_key;
	input [15:0] addr;
	output wire [4:0] key_data;
	output reg [11:1] Fn = 0;
	output reg [2:0] mod = 0;
	reg [4:0] keys [7:0];
	reg release_btn = 0;
	reg [7:0] code;
	assign key_data = (((((((!addr[8] ? keys[0] : 5'b11111) & (!addr[9] ? keys[1] : 5'b11111)) & (!addr[10] ? keys[2] : 5'b11111)) & (!addr[11] ? keys[3] : 5'b11111)) & (!addr[12] ? keys[4] : 5'b11111)) & (!addr[13] ? keys[5] : 5'b11111)) & (!addr[14] ? keys[6] : 5'b11111)) & (!addr[15] ? keys[7] : 5'b11111);
	reg input_strobe = 0;
	wire shift = mod[0];
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_reset = 0;
		old_reset <= reset;
		if (~old_reset & reset) begin
			keys[0] <= 5'b11111;
			keys[1] <= 5'b11111;
			keys[2] <= 5'b11111;
			keys[3] <= 5'b11111;
			keys[4] <= 5'b11111;
			keys[5] <= 5'b11111;
			keys[6] <= 5'b11111;
			keys[7] <= 5'b11111;
		end
		if (input_strobe) begin
			case (code)
				8'h59: mod[0] <= ~release_btn;
				8'h11: mod[1] <= ~release_btn;
				8'h14: mod[2] <= ~release_btn;
				8'h05: Fn[1] <= ~release_btn;
				8'h06: Fn[2] <= ~release_btn;
				8'h04: Fn[3] <= ~release_btn;
				8'h0c: Fn[4] <= ~release_btn;
				8'h03: Fn[5] <= ~release_btn;
				8'h0b: Fn[6] <= ~release_btn;
				8'h83: Fn[7] <= ~release_btn;
				8'h0a: Fn[8] <= ~release_btn;
				8'h01: Fn[9] <= ~release_btn;
				8'h09: Fn[10] <= ~release_btn;
				8'h78: Fn[11] <= ~release_btn;
			endcase
			case (code)
				8'h12: keys[0][0] <= release_btn;
				8'h59: keys[0][0] <= release_btn;
				8'h1a: keys[0][1] <= release_btn;
				8'h22: keys[0][2] <= release_btn;
				8'h21: keys[0][3] <= release_btn;
				8'h2a: keys[0][4] <= release_btn;
				8'h1c: keys[1][0] <= release_btn;
				8'h1b: keys[1][1] <= release_btn;
				8'h23: keys[1][2] <= release_btn;
				8'h2b: keys[1][3] <= release_btn;
				8'h34: keys[1][4] <= release_btn;
				8'h15: keys[2][0] <= release_btn;
				8'h1d: keys[2][1] <= release_btn;
				8'h24: keys[2][2] <= release_btn;
				8'h2d: keys[2][3] <= release_btn;
				8'h2c: keys[2][4] <= release_btn;
				8'h16: keys[3][0] <= release_btn;
				8'h1e: keys[3][1] <= release_btn;
				8'h26: keys[3][2] <= release_btn;
				8'h25: keys[3][3] <= release_btn;
				8'h2e: keys[3][4] <= release_btn;
				8'h45: keys[4][0] <= release_btn;
				8'h46: keys[4][1] <= release_btn;
				8'h3e: keys[4][2] <= release_btn;
				8'h3d: keys[4][3] <= release_btn;
				8'h36: keys[4][4] <= release_btn;
				8'h4d: keys[5][0] <= release_btn;
				8'h44: keys[5][1] <= release_btn;
				8'h43: keys[5][2] <= release_btn;
				8'h3c: keys[5][3] <= release_btn;
				8'h35: keys[5][4] <= release_btn;
				8'h5a: keys[6][0] <= release_btn;
				8'h4b: keys[6][1] <= release_btn;
				8'h42: keys[6][2] <= release_btn;
				8'h3b: keys[6][3] <= release_btn;
				8'h33: keys[6][4] <= release_btn;
				8'h29: keys[7][0] <= release_btn;
				8'h14: keys[7][1] <= release_btn;
				8'h3a: keys[7][2] <= release_btn;
				8'h31: keys[7][3] <= release_btn;
				8'h32: keys[7][4] <= release_btn;
				8'h6b: begin
					keys[0][0] <= release_btn;
					keys[3][4] <= release_btn;
				end
				8'h72: begin
					keys[0][0] <= release_btn;
					keys[4][4] <= release_btn;
				end
				8'h75: begin
					keys[0][0] <= release_btn;
					keys[4][3] <= release_btn;
				end
				8'h74: begin
					keys[0][0] <= release_btn;
					keys[4][2] <= release_btn;
				end
				8'h66: begin
					keys[0][0] <= release_btn;
					keys[4][0] <= release_btn;
				end
				8'h58: begin
					keys[0][0] <= release_btn;
					keys[3][1] <= release_btn;
				end
				8'h76: begin
					keys[0][0] <= release_btn;
					keys[7][0] <= release_btn;
				end
				8'h49: begin
					keys[7][1] <= release_btn;
					keys[2][4] <= release_btn | ~shift;
					keys[7][2] <= release_btn | shift;
				end
				8'h41: begin
					keys[7][1] <= release_btn;
					keys[2][3] <= release_btn | ~shift;
					keys[7][3] <= release_btn | shift;
				end
				8'h4a: begin
					keys[7][1] <= release_btn;
					keys[0][3] <= release_btn | ~shift;
					keys[0][4] <= release_btn | shift;
				end
				8'h4c: begin
					keys[7][1] <= release_btn;
					keys[0][1] <= release_btn | ~shift;
					keys[5][1] <= release_btn | shift;
				end
				8'h52: begin
					keys[7][1] <= release_btn;
					keys[4][3] <= release_btn | ~shift;
					keys[5][0] <= release_btn | shift;
				end
				8'h54: begin
					keys[7][1] <= release_btn;
					keys[4][2] <= release_btn;
				end
				8'h5b: begin
					keys[7][1] <= release_btn;
					keys[4][1] <= release_btn;
				end
				8'h4e: begin
					keys[7][1] <= release_btn;
					keys[4][0] <= release_btn | ~shift;
					keys[6][3] <= release_btn | shift;
				end
				8'h55: begin
					keys[7][1] <= release_btn;
					keys[6][2] <= release_btn | ~shift;
					keys[6][1] <= release_btn | shift;
				end
				8'h0e: begin
					keys[7][1] <= release_btn;
					keys[4][3] <= release_btn;
				end
				8'h5d: begin
					keys[7][1] <= release_btn;
					keys[7][4] <= release_btn;
				end
				default:
					;
			endcase
		end
	end
	reg [413:0] auto = 1219'h7f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056623141dceca5520000000029548b55a000000ff;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		integer div;
		reg [5:0] auto_pos = 0;
		reg old_reset = 0;
		reg old_state;
		input_strobe <= 0;
		old_reset <= reset;
		old_state <= ps2_key[10];
		if (~old_reset & reset)
			auto_pos <= 0;
		else if (auto[(45 - auto_pos) * 9+:9] == 255) begin
			div <= 0;
			if (old_state != ps2_key[10]) begin
				release_btn <= ~ps2_key[9];
				code <= ps2_key[7:0];
				input_strobe <= 1;
				if (((ps2_key[8:0] == 'h78) && mod[2]) && ~ps2_key[9])
					auto_pos <= 1;
			end
		end
		else begin
			div <= div + 1;
			if (div == 7000000) begin
				div <= 0;
				if (auto[(45 - auto_pos) * 9+:9])
					{input_strobe, release_btn, code} <= {1'b1, auto[(45 - auto_pos) * 9+:9]};
				auto_pos <= auto_pos + 1'd1;
			end
		end
	end
endmodule
