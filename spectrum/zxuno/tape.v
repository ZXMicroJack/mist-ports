module tape (
	clk_sys,
	ce,
	mode48k,
	turbo,
	byte_wait,
	byte_ready,
	dout,
	pause,
	prev,
	next,
	active,
	available,
	tape_ready,
	tape_mode,
	tape_size,
	stdload,
	req_hdr,
	audio_out,
	rd_en,
	rd,
	addr,
	din
);
	input clk_sys;
	input ce;
	input mode48k;
	input turbo;
	input byte_wait;
	output reg byte_ready;
	output wire [7:0] dout;
	input pause;
	input prev;
	input next;
	output reg active;
	output reg available;
	input tape_ready;
	input [1:0] tape_mode;
	input [24:0] tape_size;
	input stdload;
	input req_hdr;
	output reg audio_out;
	input rd_en;
	output wire rd;
	output reg [24:0] addr;
	input [7:0] din;
	localparam CLOCK = 32'd3500000;
	reg [7:0] din_r;
	reg play_pause;
	reg tzx_ack;
	wire tzx_audio;
	wire tzx_loop_next;
	wire tzx_loop_start;
	wire tzx_req;
	wire tzx_stop;
	wire tzx_stop48k;
	tzxplayer #(.TZX_MS(3500)) tzxplayer(
		.clk(clk_sys),
		.ce(ce),
		.tzx_req(tzx_req),
		.tzx_ack(tzx_ack),
		.loop_start(tzx_loop_start),
		.loop_next(tzx_loop_next),
		.stop(tzx_stop),
		.stop48k(tzx_stop48k),
		.restart_tape(~tape_ready || (tape_mode != 2'b10)),
		.host_tap_in(din_r),
		.cass_read(tzx_audio),
		.cass_motor(!play_pause && (tape_mode == 2'b10))
	);
	reg rd_req;
	assign rd = rd_req & rd_en;
	reg [7:0] data;
	assign dout = data;
	reg [24:0] read_cnt;
	reg read_done;
	reg [24:0] size;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_pause;
		reg old_prev;
		reg old_next;
		reg old_ready;
		reg old_rden;
		reg [799:0] blk_list;
		reg [15:0] blocksz;
		reg [5:0] hdrsz;
		reg [15:0] pilot;
		reg [12:0] tick;
		reg [7:0] state;
		reg [31:0] bitcnt;
		reg [31:0] timeout;
		reg [15:0] freq;
		reg [2:0] reload32;
		reg [31:0] clk_play_cnt;
		reg blk_type;
		reg skip;
		reg turboskip;
		reg auto_blk;
		reg [4:0] blk_num;
		reg old_stdload;
		reg old_read_done;
		reg [24:0] tzx_loop_addr;
		old_rden <= rd_en;
		if (~rd_en) begin
			if (rd_req) begin
				if (old_rden) begin
					if (~read_done) begin
						din_r <= din;
						read_done <= 1;
					end
					rd_req <= 0;
				end
			end
			else
				rd_req <= ~read_done;
		end
		active <= !play_pause && read_cnt;
		available <= |read_cnt;
		old_ready <= tape_ready;
		if (tape_ready & ~old_ready) begin
			read_cnt <= tape_size;
			addr <= 0;
			size <= tape_size;
			blk_list[775+:25] <= tape_size;
			if ((tape_mode == 2'b01) && tape_size) begin
				hdrsz <= 32;
				read_done <= 0;
			end
		end
		old_read_done <= read_done;
		if (tape_ready && (tape_mode == 2'b10)) begin
			audio_out <= tzx_audio;
			if (tzx_stop | (mode48k & tzx_stop48k))
				play_pause <= 1;
			if (tzx_loop_start)
				tzx_loop_addr <= addr;
			if (tzx_loop_next) begin
				addr <= tzx_loop_addr;
				read_cnt <= read_cnt + (addr - tzx_loop_addr);
			end
			if (~old_read_done & read_done) begin
				tzx_ack <= tzx_req;
				read_cnt <= read_cnt - 1'd1;
				addr <= addr + 1'b1;
			end
			else if ((read_cnt && read_done) && (tzx_req ^ tzx_ack))
				read_done <= 0;
		end
		if (~tape_ready) begin
			old_stdload <= 0;
			read_cnt <= 0;
			read_done <= 1;
			play_pause <= 1;
			hdrsz <= 0;
			state <= 0;
			reload32 <= 0;
			bitcnt <= 1;
			blk_type <= 0;
			skip <= 0;
			turboskip <= 0;
			auto_blk <= 0;
			blk_list <= {32 {25'd0}};
			blk_num <= 0;
			rd_req <= 0;
			audio_out <= 1;
		end
		else if (ce) begin
			old_stdload <= stdload;
			if ((stdload | turbo) & ~auto_blk)
				play_pause <= 0;
			old_pause <= pause;
			if ((pause & ~old_pause) & ~turbo) begin
				play_pause <= ~play_pause;
				auto_blk <= ~play_pause;
			end
			case (tape_mode)
				2'b00: begin
					if (hdrsz && read_done) begin
						read_done <= 0;
						if (hdrsz == 2)
							blocksz[7:0] <= din_r;
						else
							blocksz[15:8] <= din_r;
						hdrsz <= hdrsz - 1'b1;
						read_cnt <= read_cnt - 1'b1;
						addr <= addr + 1'b1;
					end
					if (!play_pause & (read_cnt || state)) begin
						if (tick) begin
							tick <= tick - 1'b1;
							if (tick == 1)
								audio_out <= ~audio_out;
						end
						else
							case (state)
								0: begin
									hdrsz <= 2;
									read_done <= 0;
									pilot <= (turbo ? 16'd20 : 16'd3220);
									timeout <= 3500000;
									state <= state + 1'b1;
								end
								1:
									if (skip) begin
										if (!hdrsz && read_done) begin
											blk_type <= din_r[7];
											state <= 4;
										end
									end
									else if (pilot) begin
										tick <= 2168;
										pilot <= pilot - 1'b1;
									end
									else begin
										blk_type <= din_r[7];
										if (~din_r[7] & ~turbo)
											pilot <= 4844;
										state <= state + 1'b1;
										if (req_hdr & (din_r != 0)) begin
											state <= 4;
											skip <= 1;
										end
									end
								2:
									if (pilot) begin
										tick <= 2168;
										pilot <= pilot - 1'b1;
									end
									else begin
										tick <= 667;
										state <= state + 1'b1;
									end
								3: begin
									tick <= 735;
									state <= state + 1'b1;
								end
								4:
									if (blocksz) begin
										if (read_done) begin
											read_done <= 0;
											data <= din_r;
											read_cnt <= read_cnt - 1'b1;
											addr <= addr + 1'b1;
											bitcnt <= 8;
											if (skip || turboskip) begin
												blocksz <= blocksz - 1'b1;
												timeout <= 0;
											end
											else begin
												state <= state + 1'b1;
												if (turbo)
													state <= 7;
											end
										end
									end
									else begin
										turboskip <= 0;
										if (!read_cnt || !timeout) begin
											if (blk_type && read_cnt) begin
												blk_num <= blk_num + 1'b1;
												blk_list[(31 - (blk_num + 1'b1)) * 25+:25] <= read_cnt;
												play_pause <= ~skip;
												auto_blk <= 0;
												skip <= 0;
											end
											blk_type <= 0;
											state <= 0;
										end
										else
											timeout <= timeout - 1'b1;
									end
								5:
									if (bitcnt) begin
										if (data[7])
											tick <= 1710;
										else
											tick <= 855;
										state <= state + 1'b1;
									end
									else begin
										blocksz <= blocksz - 1'b1;
										state <= state - 1'b1;
									end
								6: begin
									if (data[7])
										tick <= 1710;
									else
										tick <= 855;
									data <= {data[6:0], 1'b0};
									bitcnt <= bitcnt - 1'b1;
									state <= state - 1'b1;
								end
								7:
									if (byte_wait) begin
										byte_ready <= 1;
										state <= state + 1'b1;
									end
									else if (!turbo) begin
										turboskip <= 1;
										blocksz <= blocksz - 1'b1;
										state <= 4;
									end
								8:
									if (!byte_wait) begin
										byte_ready <= 0;
										blocksz <= blocksz - 1'b1;
										state <= 4;
									end
								default:
									;
							endcase
					end
					old_prev <= prev;
					if ((prev & ~old_prev) & ~turbo) begin
						play_pause <= 0;
						auto_blk <= 0;
						if ((state > 3) || !blk_num) begin
							read_cnt <= blk_list[(31 - blk_num) * 25+:25];
							addr <= size - blk_list[(31 - blk_num) * 25+:25];
						end
						else begin
							blk_num <= blk_num - 1'b1;
							read_cnt <= blk_list[(32 - blk_num) * 25+:25];
							addr <= size - blk_list[(32 - blk_num) * 25+:25];
						end
						state <= 0;
						tick <= 0;
					end
					old_next <= next;
					if ((next & ~old_next) & ~turbo) begin
						play_pause <= 0;
						auto_blk <= 0;
						skip <= 1;
						tick <= 0;
					end
				end
				2'b01: begin
					if (old_stdload & ~stdload)
						play_pause <= 1;
					if (hdrsz && read_done) begin
						if (hdrsz == 7)
							freq[7:0] <= din_r;
						if (hdrsz == 6)
							freq[15:8] <= din_r;
						read_done <= 0;
						read_cnt <= read_cnt - 1'd1;
						addr <= addr + 1'b1;
						hdrsz <= hdrsz - 1'd1;
					end
					if ((!hdrsz && read_cnt) && !play_pause) begin
						if ((bitcnt <= 1) || (reload32 != 0)) begin
							if (read_done) begin
								if (reload32 != 0) begin
									bitcnt <= {din_r, bitcnt[31:8]};
									reload32 <= reload32 - 1'd1;
								end
								else begin
									if (din_r != 0)
										bitcnt <= {24'd0, din_r};
									else
										reload32 <= 4;
									audio_out <= ~audio_out;
								end
								read_done <= 0;
								read_cnt <= read_cnt - 1'd1;
								addr <= addr + 1'b1;
							end
						end
						else begin
							clk_play_cnt <= clk_play_cnt + freq;
							if (clk_play_cnt > CLOCK) begin
								clk_play_cnt <= clk_play_cnt - CLOCK;
								bitcnt <= bitcnt - 1'd1;
							end
						end
					end
				end
				default:
					;
			endcase
		end
	end
endmodule
