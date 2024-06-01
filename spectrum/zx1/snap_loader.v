module snap_loader (
	clk_sys,
	ioctl_download,
	ioctl_addr,
	ioctl_data,
	ioctl_wr,
	ioctl_wait,
	snap_sna,
	ram_ready,
	REG,
	REGSet,
	addr,
	dout,
	wr,
	reset,
	hwset,
	hw,
	hw_ack,
	border,
	reg_1ffd,
	reg_7ffd
);
	reg _sv2v_0;
	parameter ARCH_ZX48 = 0;
	parameter ARCH_ZX128 = 0;
	parameter ARCH_ZX3 = 0;
	parameter ARCH_P128 = 0;
	input clk_sys;
	input ioctl_download;
	input [24:0] ioctl_addr;
	input [7:0] ioctl_data;
	input ioctl_wr;
	output wire ioctl_wait;
	input snap_sna;
	input ram_ready;
	output wire [211:0] REG;
	output wire REGSet;
	output reg [24:0] addr;
	output wire [7:0] dout;
	output wire wr;
	output wire reset;
	output wire hwset;
	output wire [4:0] hw;
	input [4:0] hw_ack;
	output wire [2:0] border;
	output wire [7:0] reg_1ffd;
	output wire [7:0] reg_7ffd;
	reg [211:0] snap_REG;
	assign REG = snap_REG;
	reg snap_REGSet;
	assign REGSet = snap_REGSet;
	reg [7:0] snap_data;
	assign dout = snap_data;
	reg snap_wr;
	assign wr = snap_wr;
	reg snap_reset;
	assign reset = snap_reset;
	reg snap_hwset;
	assign hwset = snap_hwset;
	reg [4:0] snap_hw;
	assign hw = snap_hw;
	reg [2:0] snap_border;
	assign border = snap_border;
	reg [7:0] snap_1ffd;
	assign reg_1ffd = snap_1ffd;
	reg [7:0] snap_7ffd;
	assign reg_7ffd = snap_7ffd;
	reg snap_wait = 0;
	assign ioctl_wait = snap_wait;
	wire [24:0] snap_addr;
	reg [31:0] snap_status;
	reg [24:0] addr_pre;
	reg hdrv1;
	always @(*) begin
		if (_sv2v_0)
			;
		addr = addr_pre;
		if (hdrv1 || snap_sna)
			case (addr_pre[17:14])
				0: addr[16:14] = 5;
				1: addr[16:14] = 2;
				2: addr[16:14] = 0;
				default: addr[16:14] = 1;
			endcase
	end
	reg [7:0] snap_hdrlen;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_download;
		reg [7:0] snap61;
		reg [7:0] snap62;
		reg [2:0] comp_state;
		reg [24:0] addr;
		reg [15:0] sz;
		reg compr;
		reg wren;
		reg [7:0] cnt;
		reg finish;
		reg [1:0] hold = 0;
		hdrv1 <= snap_hdrlen == 30;
		snap_wr <= 0;
		old_download <= ioctl_download;
		if (~old_download && ioctl_download) begin
			snap_hdrlen <= (snap_sna ? 8'd27 : 8'd30);
			snap_reset <= 1;
			snap_hw <= 0;
		end
		if (old_download && ~ioctl_download) begin
			if (snap_hw) begin
				snap_REGSet <= 1;
				snap_hwset <= 1;
				hold <= 1'sb1;
			end
			else
				snap_reset <= 0;
		end
		if (snap_hwset && (snap_hw == hw_ack)) begin
			snap_hwset <= 0;
			snap_reset <= 0;
		end
		if (~snap_reset) begin
			if (hold)
				hold <= hold - 1'd1;
			else
				snap_REGSet <= 0;
		end
		if (ioctl_download & ioctl_wr) begin
			if (ioctl_addr < snap_hdrlen) begin
				if (!snap_sna)
					case (ioctl_addr[6:0])
						0: snap_REG[7:0] <= ioctl_data;
						1: snap_REG[15:8] <= ioctl_data;
						2: snap_REG[87:80] <= ioctl_data;
						3: snap_REG[95:88] <= ioctl_data;
						4: snap_REG[119:112] <= ioctl_data;
						5: snap_REG[127:120] <= ioctl_data;
						6: snap_REG[71:64] <= ioctl_data;
						7: snap_REG[79:72] <= ioctl_data;
						8: snap_REG[55:48] <= ioctl_data;
						9: snap_REG[63:56] <= ioctl_data;
						10: snap_REG[39:32] <= ioctl_data;
						11: snap_REG[47:40] <= ioctl_data;
						12: begin
							snap_REG[47] <= ioctl_data[0];
							snap_border <= (&ioctl_data ? 3'd0 : ioctl_data[3:1]);
							snap_1ffd <= 0;
							comp_state <= 0;
							finish <= 0;
							if (!snap_REG[79:64]) begin
								snap_hdrlen <= 87;
								snap_hw <= 0;
							end
							else begin
								snap_hw <= ARCH_ZX48;
								addr <= 0;
								sz <= 'hc000;
								compr <= 0;
								comp_state <= 3;
								wren <= 1;
								if (~&ioctl_data & ioctl_data[5]) begin
									sz <= 0;
									compr <= 1;
								end
							end
						end
						13: snap_REG[103:96] <= ioctl_data;
						14: snap_REG[111:104] <= ioctl_data;
						15: snap_REG[151:144] <= ioctl_data;
						16: snap_REG[159:152] <= ioctl_data;
						17: snap_REG[167:160] <= ioctl_data;
						18: snap_REG[175:168] <= ioctl_data;
						19: snap_REG[183:176] <= ioctl_data;
						20: snap_REG[191:184] <= ioctl_data;
						21: snap_REG[23:16] <= ioctl_data;
						22: snap_REG[31:24] <= ioctl_data;
						23: snap_REG[199:192] <= ioctl_data;
						24: snap_REG[207:200] <= ioctl_data;
						25: snap_REG[135:128] <= ioctl_data;
						26: snap_REG[143:136] <= ioctl_data;
						27: snap_REG[211:210] <= (ioctl_data ? 2'b11 : 2'b00);
						29: snap_REG[209:208] <= ioctl_data[1:0];
						30: snap_hdrlen <= 8'd32 + ioctl_data;
						32: snap_REG[71:64] <= ioctl_data;
						33: snap_REG[79:72] <= ioctl_data;
						34:
							case (ioctl_data)
								0, 1: snap_hw <= ARCH_ZX48;
								3: snap_hw <= (snap_hdrlen <= 55 ? ARCH_ZX128 : ARCH_ZX48);
								4, 5, 6, 12: snap_hw <= ARCH_ZX128;
								7, 8, 13: snap_hw <= ARCH_ZX3;
								9: snap_hw <= ARCH_P128;
							endcase
						35: snap_7ffd <= ioctl_data;
						86: snap_1ffd <= ioctl_data;
					endcase
				else
					case (ioctl_addr[6:0])
						0: begin
							snap_REG[39:32] <= ioctl_data;
							snap_REG[71:64] <= 8'h72;
							snap_REG[79:72] <= 8'h00;
							snap_1ffd <= 0;
							snap_hw <= ARCH_ZX48;
							finish <= 0;
							addr <= 0;
							sz <= 'hc000;
							compr <= 0;
							comp_state <= 3;
							wren <= 1;
						end
						1: snap_REG[183:176] <= ioctl_data;
						2: snap_REG[191:184] <= ioctl_data;
						3: snap_REG[167:160] <= ioctl_data;
						4: snap_REG[175:168] <= ioctl_data;
						5: snap_REG[151:144] <= ioctl_data;
						6: snap_REG[159:152] <= ioctl_data;
						7: snap_REG[23:16] <= ioctl_data;
						8: snap_REG[31:24] <= ioctl_data;
						9: snap_REG[119:112] <= ioctl_data;
						10: snap_REG[127:120] <= ioctl_data;
						11: snap_REG[103:96] <= ioctl_data;
						12: snap_REG[111:104] <= ioctl_data;
						13: snap_REG[87:80] <= ioctl_data;
						14: snap_REG[95:88] <= ioctl_data;
						15: snap_REG[199:192] <= ioctl_data;
						16: snap_REG[207:200] <= ioctl_data;
						17: snap_REG[135:128] <= ioctl_data;
						18: snap_REG[143:136] <= ioctl_data;
						19: snap_REG[211:210] <= {ioctl_data[2], 1'b0};
						20: snap_REG[47:40] <= ioctl_data;
						21: snap_REG[7:0] <= ioctl_data;
						22: snap_REG[15:8] <= ioctl_data;
						23: snap_REG[55:48] <= ioctl_data;
						24: snap_REG[63:56] <= ioctl_data;
						25: snap_REG[209:208] <= ioctl_data[1:0];
						26: snap_border <= ioctl_data[2:0];
					endcase
			end
			else if (snap_hw && !finish) begin
				case (comp_state)
					0: begin
						sz[7:0] <= ioctl_data;
						comp_state <= comp_state + 1'd1;
					end
					1: begin
						sz[15:8] <= ioctl_data;
						comp_state <= comp_state + 1'd1;
					end
					2: begin
						compr <= 1;
						if (&sz) begin
							sz <= 'h4000;
							compr <= 0;
						end
						wren <= 0;
						addr <= 0;
						if (snap_hw == ARCH_ZX48)
							case (ioctl_data)
								4: begin
									addr <= 18'h08000;
									wren <= 1;
								end
								5: begin
									addr <= 18'h00000;
									wren <= 1;
								end
								8: begin
									addr <= 18'h14000;
									wren <= 1;
								end
							endcase
						else if ((ioctl_data >= 3) && (ioctl_data <= 10)) begin
							addr <= {ioctl_data[3:0] - 3'd3, 14'd0};
							wren <= 1;
						end
						comp_state <= comp_state + 1'd1;
					end
					3:
						if (compr && (ioctl_data == 'hed))
							comp_state <= comp_state + 1'd1;
						else begin
							addr_pre <= addr;
							snap_data <= ioctl_data;
							snap_wr <= wren;
							addr <= addr + 1'd1;
						end
					4:
						if (ioctl_data == 'hed)
							comp_state <= comp_state + 1'd1;
						else begin
							snap_wait <= wren;
							addr_pre <= addr;
							addr <= addr + 1'd1;
							snap_data <= 'hed;
							snap_wr <= wren;
							comp_state <= 3;
							cnt <= 1;
						end
					5: begin
						cnt <= ioctl_data - 1'd1;
						comp_state <= comp_state + 1'd1;
						if (!ioctl_data)
							finish <= 1;
					end
					6: begin
						snap_wait <= wren;
						addr_pre <= addr;
						addr <= addr + 1'd1;
						snap_data <= ioctl_data;
						snap_wr <= wren;
						comp_state <= 3;
					end
				endcase
				if (comp_state >= 3) begin
					sz <= sz - 1'd1;
					if (sz == 1) begin
						if ((snap_hdrlen == 30) || snap_sna)
							finish <= 1;
						else
							comp_state <= 0;
					end
				end
			end
		end
		if ((~snap_wr & snap_wait) & ram_ready) begin
			if (cnt) begin
				addr_pre <= addr;
				addr <= addr + 1'd1;
				snap_data <= ioctl_data;
				snap_wr <= 1;
				cnt <= cnt - 1'd1;
			end
			else
				snap_wait <= 0;
		end
		if ((snap_wr && ((snap_hdrlen == 30) || snap_sna)) && (addr_pre == 'hbfff))
			wren <= 0;
	end
	initial _sv2v_0 = 0;
endmodule
