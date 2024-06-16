module smart_tape (
	reset,
	clk_sys,
	ce,
	mode48k,
	turbo,
	pause,
	prev,
	next,
	led,
	active,
	available,
	buff_rd_en,
	buff_rd,
	buff_addr,
	buff_din,
	ioctl_download,
	tape_mode,
	tape_size,
	req_hdr,
	audio_out,
	addr,
	m1,
	rom_en,
	dout_en,
	dout
);
	input reset;
	input clk_sys;
	input ce;
	input mode48k;
	output reg turbo;
	input pause;
	input prev;
	input next;
	output wire led;
	output wire active;
	output wire available;
	input buff_rd_en;
	output wire buff_rd;
	output wire [24:0] buff_addr;
	input [7:0] buff_din;
	input ioctl_download;
	input [1:0] tape_mode;
	input [24:0] tape_size;
	input req_hdr;
	output wire audio_out;
	input [15:0] addr;
	input m1;
	input rom_en;
	output wire dout_en;
	output wire [7:0] dout;
	wire tape_ld1 = (((addr >= 'h5ca) & (addr < 'h5d8)) & rom_en) & turbo;
	wire tape_ld2 = (((addr >= 'h56c) & (addr < 'h58f)) & rom_en) & turbo;
	assign dout_en = tape_ld1 | tape_ld2;
	reg [111:0] tape_stub = 112'h18fe2eff00000000000000000000;
	assign dout = (tape_ld2 ? 8'h00 : tape_stub[(1495 - addr) * 8+:8]);
	reg [24:0] act_cnt;
	assign led = (act_cnt[24] ? act_cnt[23:16] > act_cnt[7:0] : act_cnt[23:16] <= act_cnt[7:0]);
	always @(posedge clk_sys)
		if ((active || ~(available ^ act_cnt[24])) || act_cnt[23:0])
			act_cnt <= act_cnt + 1'd1;
	wire [7:0] tape_dout;
	reg [1:0] tape_mode_reg;
	wire byte_ready;
	reg byte_wait;
	reg stdload;
	reg stdhdr;
	reg tape_ready;
	tape tape(
		.clk_sys(clk_sys),
		.ce(ce),
		.mode48k(mode48k),
		.turbo(turbo),
		.byte_wait(byte_wait),
		.byte_ready(byte_ready),
		.pause(pause),
		.prev(prev),
		.next(next),
		.active(active),
		.available(available),
		.tape_ready(tape_ready),
		.tape_size(tape_size),
		.stdload(stdload),
		.audio_out(audio_out),
		.tape_mode(tape_mode_reg),
		.req_hdr(stdhdr),
		.addr(buff_addr),
		.din(buff_din),
		.dout(tape_dout),
		.rd_en(buff_rd_en),
		.rd(buff_rd)
	);
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_m1;
		reg old_download;
		reg allow_turbo;
		old_m1 <= m1;
		old_download <= ioctl_download;
		if (m1 & ~old_m1) begin
			if ((addr == 'h5ed) & rom_en)
				stdload <= 1;
			if ((addr == 'h562) & rom_en)
				{turbo, stdhdr} <= {allow_turbo & available, req_hdr};
			if (((addr >= 'h605) | (addr < 'h53f)) | ~rom_en)
				{turbo, stdhdr, stdload} <= 0;
			if (tape_ld1 & (addr < 'h5cc)) begin
				byte_wait <= 1;
				tape_stub[80+:8] <= tape_dout;
				if (byte_ready)
					tape_stub[96+:8] <= 0;
			end
			else
				byte_wait <= 0;
			if (!tape_ld1)
				tape_stub[96+:8] <= 'hfe;
		end
		if ((reset | (prev & next)) | ioctl_download)
			{tape_ready, allow_turbo} <= 0;
		if (old_download & ~ioctl_download)
			{tape_ready, allow_turbo, tape_mode_reg} <= {1'b1, ~stdload & !tape_mode, tape_mode};
	end
endmodule
