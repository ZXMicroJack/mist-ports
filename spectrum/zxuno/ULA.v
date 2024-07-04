module ULA (
	reset,
	clk_sys,
	ce_7mp,
	ce_7mn,
	ce_cpu_sp,
	ce_cpu_sn,
	addr,
	din,
	nMREQ,
	nIORQ,
	nRD,
	nWR,
	nINT,
	nPortRD,
	nPortWR,
	vram_addr,
	vram_dout,
	port_ff,
	ulap_avail,
	ulap_sel,
	ulap_dout,
	ulap_ena,
	ulap_mono,
	tmx_avail,
	mode512,
	snow_ena,
	mZX,
	m128,
	page_scr,
	page_ram,
	border_color,
	HSync,
	VSync,
	HBlank,
	Rx,
	Gx,
	Bx
);
	reg _sv2v_0;
	input reset;
	input clk_sys;
	input ce_7mp;
	input ce_7mn;
	output wire ce_cpu_sp;
	output wire ce_cpu_sn;
	input [15:0] addr;
	input [7:0] din;
	input nMREQ;
	input nIORQ;
	input nRD;
	input nWR;
	output wire nINT;
	output wire nPortRD;
	output wire nPortWR;
	output wire [14:0] vram_addr;
	input [7:0] vram_dout;
	output wire [7:0] port_ff;
	input ulap_avail;
	output wire ulap_sel;
	output wire [7:0] ulap_dout;
	output reg ulap_ena;
	output reg ulap_mono;
	input tmx_avail;
	output reg mode512;
	input snow_ena;
	input mZX;
	input m128;
	input page_scr;
	input [2:0] page_ram;
	input [2:0] border_color;
	output reg HSync;
	output reg VSync;
	output reg HBlank;
	output reg [2:0] Rx;
	output reg [2:0] Gx;
	output reg [2:0] Bx;
	reg [14:0] vaddr;
	assign vram_addr = vaddr;
	reg INT = 0;
	assign nINT = ~INT;
	reg [7:0] ff_data;
	reg [5:0] tmx_cfg;
	reg tmx_using_ff;
	assign port_ff = (tmx_using_ff ? {2'b00, tmx_cfg} : (mZX ? ff_data : 8'hff));
	reg ioreqtw3;
	assign nPortRD = ((addr[0] | nIORQ) | (mZX & ioreqtw3)) | nRD;
	assign nPortWR = ((addr[0] | nIORQ) | (mZX & ioreqtw3)) | nWR;
	reg [8:0] hc = 0;
	reg [8:0] vc_next;
	reg [8:0] vc = 0;
	reg [8:0] hc_next;
	wire Border_next = ((vc_next[7] & vc_next[6]) | vc_next[8]) | hc_next[8];
	reg Border;
	reg [4:0] FlashCnt_next;
	reg [4:0] FlashCnt;
	always @(*) begin
		vc_next = vc;
		FlashCnt_next = FlashCnt;
		if (hc == (mZX && m128 ? 455 : 447)) begin
			hc_next = 0;
			if (vc == (!mZX ? 319 : (m128 ? 310 : 311))) begin
				vc_next = 0;
				FlashCnt_next = FlashCnt + 5'd1;
			end
			else
				vc_next = vc + 9'd1;
		end
		else
			hc_next = hc + 9'd1;
	end
	reg [7:0] AttrOut;
	reg [6:0] INTCnt = 1;
	reg [7:0] SRegister;
	reg VidEN = 0;
	reg [7:0] attr;
	reg [7:0] bits;
	wire contendAddr = (addr[15:14] == 2'b01) | ((m128 & (addr[15:14] == 2'b11)) & page_ram[0]);
	reg [15:0] hiSRegister;
	wire [63:0] hipalette;
	wire [7:0] hiattr = hipalette[(7 - tmx_cfg[5:3]) * 8+:8];
	reg tmx_ena;
	wire stdpage = tmx_using_ff | ~tmx_ena;
	wire tmx_hi = &{tmx_ena, tmx_cfg[2:1]};
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg m512;
		if (ce_7mp)
			hiSRegister <= {hiSRegister[14:0], 1'b0};
		if (ce_7mn) begin
			vc <= vc_next;
			hc <= hc_next;
			Border <= Border_next;
			FlashCnt <= FlashCnt_next;
			if ((vc_next < 192) || (hc_next < 256))
				m512 <= m512 | tmx_hi;
			if (hc_next == 0) begin
				if ((mZX ? vc_next == 240 : vc_next == 248)) begin
					mode512 <= m512;
					m512 <= 0;
				end
			end
			if (!mZX) begin
				if (hc_next == 312)
					HBlank <= 1;
				else if (hc_next == 420)
					HBlank <= 0;
				if (hc_next == 338)
					HSync <= 1;
				else if (hc_next == 370)
					HSync <= 0;
			end
			else if (m128) begin
				if (hc_next == 312)
					HBlank <= 1;
				else if (hc_next == 424)
					HBlank <= 0;
				if (hc_next == 340)
					HSync <= 1;
				else if (hc_next == 372)
					HSync <= 0;
			end
			else begin
				if (hc_next == 312)
					HBlank <= 1;
				else if (hc_next == 416)
					HBlank <= 0;
				if (hc_next == 336)
					HSync <= 1;
				else if (hc_next == 368)
					HSync <= 0;
			end
			if (mZX) begin
				if (vc_next == 240)
					VSync <= 1;
				else if (vc_next == 244)
					VSync <= 0;
			end
			else if (vc_next == 248)
				VSync <= 1;
			else if (vc_next == 256)
				VSync <= 0;
			if ((mZX && (vc_next == 248)) && (hc_next == (m128 ? 8 : 4)))
				INT <= 1;
			if ((!mZX && (vc_next == 239)) && (hc_next == 326))
				INT <= 1;
			if (INT)
				INTCnt <= ((m128 && (INTCnt == 71)) || (~m128 && (INTCnt == 63)) ? 7'd0 : INTCnt + 7'd1);
			if (INTCnt == 0)
				INT <= 0;
			if ((hc_next[3:0] == 4) || (hc_next[3:0] == 12)) begin
				SRegister <= (VidEN ? bits : 8'd0);
				hiSRegister <= (VidEN ? {bits, attr} : 16'd0);
				AttrOut <= (tmx_hi ? hiattr : (VidEN ? attr : {2'b00, border_color, border_color}));
			end
			else begin
				SRegister <= {SRegister[6:0], 1'b0};
				hiSRegister <= {hiSRegister[14:0], 1'b0};
			end
			if ((!mZX & !hc_next[0]) & (((hc_next < 12) | (hc_next > 267)) | (vc >= 192)))
				AttrOut <= (tmx_hi ? hiattr : {2'b00, border_color, border_color});
			if (hc_next[3])
				VidEN <= ~Border;
			if (!Border_next) begin
				casez ({tmx_cfg[1], hc_next[3:0]})
					5'b01000, 5'b01100: vaddr <= {(stdpage ? page_scr : tmx_cfg[2]), tmx_cfg[0], vc[7:6], vc[2:0], vc[5:3], hc_next[7:4], hc_next[2]};
					5'b11000, 5'b11100: vaddr <= {(stdpage ? page_scr : tmx_cfg[0]), 1'b0, vc[7:6], vc[2:0], vc[5:3], hc_next[7:4], hc_next[2]};
					5'bz1001, 5'bz1101: begin
						bits <= vram_dout;
						ff_data <= vram_dout;
					end
					5'b01010, 5'b01110: vaddr <= {(stdpage ? page_scr : tmx_cfg[2]), tmx_cfg[0], 3'b110, vc[7:3], hc_next[7:4], hc_next[2]};
					5'b11010, 5'b11110: vaddr <= {(stdpage ? page_scr : tmx_cfg[0]), 1'b1, vc[7:6], vc[2:0], vc[5:3], hc_next[7:4], hc_next[2]};
					5'bz1011, 5'bz1111: begin
						attr <= vram_dout;
						ff_data <= vram_dout;
					end
					default:
						;
				endcase
				if (((mZX & ~nMREQ) & contendAddr) & snow_ena)
					vaddr[6:0] <= addr[6:0];
			end
			if (hc_next[3:0] == 1)
				ff_data <= 255;
		end
	end
	assign hipalette = 64'b0111100001110001011010100110001101011100010101010100111001000111;
	reg [15:0] hibits;
	wire I;
	wire G;
	wire R;
	wire B;
	wire Pixel = (tmx_hi ? hiSRegister[15] : SRegister[7] ^ (AttrOut[7] & FlashCnt[4]));
	assign {I, G, R, B} = (Pixel ? {AttrOut[6], AttrOut[2:0]} : {AttrOut[6], AttrOut[5:3]});
	reg [511:0] palette;
	wire [7:0] color = palette[(63 - ((tmx_hi ? hiSRegister[15] : SRegister[7]) ? {AttrOut[7:6], 1'b0, AttrOut[2:0]} : {AttrOut[7:6], 1'b1, AttrOut[5:3]})) * 8+:8];
	always @(*) begin
		if (_sv2v_0)
			;
		casez ({HBlank | VSync, ulap_ena})
			'b1z: {Gx, Rx, Bx} = 0;
			'b0: {Gx, Rx, Bx} = {G, I & G, G, R, I & R, R, B, I & B, B};
			'b1: {Gx, Rx, Bx} = {color, color[1]};
		endcase
	end
	reg CPUClk;
	reg mreqt23;
	wire ulap_acc = {addr[15], 1'b0, addr[13:0]} == 'hbf3b;
	wire ioreq_n = (addr[0] & ~(ulap_acc & ulap_avail)) | nIORQ;
	wire clkwait_next = hc_next[2] | hc_next[3];
	wire ulaContend = ((clkwait_next & ~Border_next) & CPUClk) & ioreqtw3;
	wire memContend = (ioreq_n & mreqt23) & contendAddr;
	wire ioContend = ~ioreq_n;
	wire next_clk = hc_next[0] | ((mZX & ulaContend) & (memContend | ioContend));
	reg next_clk_r;
	assign ce_cpu_sp = ce_7mn & (~CPUClk & next_clk_r);
	assign ce_cpu_sn = ce_7mn & (CPUClk & ~next_clk_r);
	always @(posedge clk_sys) begin
		if (ce_7mn)
			CPUClk <= next_clk;
		if (ce_7mp)
			next_clk_r <= next_clk;
		if (~CPUClk) begin
			ioreqtw3 <= ioreq_n;
			mreqt23 <= nMREQ;
		end
	end
	reg [7:0] palette_q;
	reg ulap_group;
	assign ulap_dout = (ulap_group ? {6'd0, ulap_mono, ulap_ena} : palette_q);
	assign ulap_sel = (ulap_acc & addr[14]) & ulap_avail;
	wire io_wr = ~nIORQ & ~nWR;
	reg [5:0] pal_addr;
	always @(posedge clk_sys) palette_q <= palette[(63 - pal_addr) * 8+:8];
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg old_wr;
		old_wr <= io_wr;
		if (reset) begin
			{ulap_ena, tmx_ena, tmx_using_ff, tmx_cfg} <= 0;
			palette <= {64 {8'd0}};
		end
		else if (~old_wr & io_wr) begin
			if (ulap_acc & ulap_avail) begin
				if (addr[14]) begin
					if (ulap_group)
						{ulap_mono, ulap_ena} <= din[1:0];
					else
						palette[(63 - pal_addr) * 8+:8] <= din;
				end
				else
					case (din[7:6])
						0: {ulap_group, pal_addr} <= {1'b0, din[5:0]};
						1: begin
							ulap_group <= 1;
							if (!tmx_using_ff)
								{tmx_ena, tmx_cfg} <= {|din[2:0], din[5:0]};
						end
						default:
							;
					endcase
			end
			if ((addr[7:0] == 'hff) & tmx_avail)
				{tmx_using_ff, tmx_ena, tmx_cfg} <= {1'b1, |din[2:0], din[5:0]};
		end
	end
	initial _sv2v_0 = 0;
endmodule
