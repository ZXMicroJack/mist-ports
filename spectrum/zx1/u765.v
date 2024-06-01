module u765 (
	clk_sys,
	ce,
	reset,
	ready,
	motor,
	available,
	fast,
	a0,
	nRD,
	nWR,
	din,
	dout,
	img_mounted,
	img_wp,
	img_size,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr
);
	parameter CYCLES = 20'd4000;
	parameter SPECCY_SPEEDLOCK_HACK = 0;
	input clk_sys;
	input ce;
	input reset;
	input [1:0] ready;
	input [1:0] motor;
	input [1:0] available;
	input fast;
	input a0;
	input nRD;
	input nWR;
	input [7:0] din;
	output wire [7:0] dout;
	input [1:0] img_mounted;
	input img_wp;
	input [31:0] img_size;
	output reg [31:0] sd_lba;
	output reg [1:0] sd_rd;
	output reg [1:0] sd_wr;
	input sd_ack;
	input [8:0] sd_buff_addr;
	input [7:0] sd_buff_dout;
	output wire [7:0] sd_buff_din;
	input sd_buff_wr;
	localparam OVERRUN_TIMEOUT = CYCLES * 8'd10;
	localparam [19:0] TRACK_TIME = CYCLES * 8'd200;
	localparam UPD765_MAIN_D0B = 0;
	localparam UPD765_MAIN_D1B = 1;
	localparam UPD765_MAIN_D2B = 2;
	localparam UPD765_MAIN_D3B = 3;
	localparam UPD765_MAIN_CB = 4;
	localparam UPD765_MAIN_EXM = 5;
	localparam UPD765_MAIN_DIO = 6;
	localparam UPD765_MAIN_RQM = 7;
	localparam UPD765_SD_BUFF_TRACKINFO = 1'd0;
	localparam UPD765_SD_BUFF_SECTOR = 1'd1;
	reg [7:0] buff_data_in;
	reg [7:0] buff_data_out;
	reg [8:0] buff_addr;
	reg buff_wr;
	reg buff_wait;
	reg sd_buff_type;
	reg hds;
	reg ds0;
	wire [8:1] sv2v_tmp_sbuf_q_b;
	always @(*) buff_data_in = sv2v_tmp_sbuf_q_b;
	u765_dpram sbuf(
		.clock(clk_sys),
		.address_a({ds0, sd_buff_type, hds, sd_buff_addr}),
		.data_a(sd_buff_dout),
		.wren_a(sd_buff_wr & sd_ack),
		.q_a(sd_buff_din),
		.address_b({ds0, sd_buff_type, hds, buff_addr}),
		.data_b(buff_data_out),
		.wren_b(buff_wr),
		.q_b(sv2v_tmp_sbuf_q_b)
	);
	reg [15:0] image_track_offsets [0:1023];
	reg [8:0] image_track_offsets_addr = 0;
	reg image_track_offsets_wr;
	reg [15:0] image_track_offsets_out;
	reg [15:0] image_track_offsets_in;
	always @(posedge clk_sys)
		if (image_track_offsets_wr) begin
			image_track_offsets[{ds0, image_track_offsets_addr}] <= image_track_offsets_out;
			image_track_offsets_in <= image_track_offsets_out;
		end
		else
			image_track_offsets_in <= image_track_offsets[{ds0, image_track_offsets_addr}];
	wire rd = nWR & ~nRD;
	wire wr = ~nWR & nRD;
	reg [7:0] i_total_sectors;
	reg [7:0] m_status;
	reg [7:0] m_data;
	assign dout = (a0 ? m_data : m_status);
		reg [3:0] image_scan_state = 4'h0;
		reg [0:1] image_ready = 2'h0;
		reg [79:0] i_rpm_time = {CYCLES, CYCLES, CYCLES, CYCLES};
		reg [31:0] status = 32'h00000000;
		reg i_scan_lock = 0;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg [31:0] image_size [0:1];
		reg [7:0] image_tracks [0:1];
		reg image_sides [0:1];
		reg [1:0] image_wp;
		reg [0:1] image_trackinfo_dirty;
		reg image_edsk [0:1];
		reg [7:0] i_current_track_sectors [0:1][0:1];
		reg [15:0] i_current_sector_pos [0:1];
		reg [19:0] i_steptimer [0:1];
		reg [39:0] i_rpm_timer [0:1];
		reg [3:0] i_step_state [0:1];
		reg [15:0] ncn;
		reg [15:0] pcn;
		reg [2:0] next_weak_sector [0:1];
		reg [3:0] seek_state;
		reg [0:1] int_state;
		reg old_wr;
		reg old_rd;
		reg [7:0] i_track_size;
		reg [31:0] i_seek_pos;
		reg [7:0] i_sector_c;
		reg [7:0] i_sector_h;
		reg [7:0] i_sector_r;
		reg [7:0] i_sector_n;
		reg [7:0] i_sector_st1;
		reg [7:0] i_sector_st2;
		reg [15:0] i_sector_size;
		reg [7:0] i_current_sector;
		reg [2:0] i_weak_sector;
		reg [15:0] i_bytes_to_read;
		reg [2:0] i_substate;
		reg [1:0] old_mounted;
		reg [15:0] i_track_offset;
		reg [5:0] ack;
		reg sd_busy;
		reg [19:0] i_timeout;
		reg [7:0] i_head_timer;
		reg i_rtrack;
		reg i_write;
		reg i_rw_deleted;
		reg [31:0] state;
		reg [31:0] i_command;
		reg i_current_drive;
		reg [3:0] i_srt;
		reg [7:0] i_c;
		reg [7:0] i_h;
		reg [7:0] i_r;
		reg [7:0] i_n;
		reg [7:0] i_eot;
		reg [7:0] i_dtl;
		reg [7:0] i_sc;
		reg i_bc;
		reg old_hds;
		reg i_mt;
		reg i_sk;
		buff_wait <= 0;
		i_total_sectors = i_current_track_sectors[ds0][hds];
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 2; i = i + 1)
				begin
					old_mounted[i] <= img_mounted[i];
					if (old_mounted[i] & ~img_mounted[i]) begin
						image_wp[i] <= img_wp;
						image_size[i] <= img_size;
						image_scan_state[(1 - i) * 2+:2] <= |img_size;
						image_ready[i] <= 0;
						int_state[i] <= 0;
						seek_state[(1 - i) * 2+:2] <= 0;
						next_weak_sector[i] <= 0;
						i_current_sector_pos[i] <= 16'h0000;
					end
				end
		end
		if (ce)
			i_current_drive <= ~i_current_drive;
		if (ce)
			case (image_scan_state[(1 - i_current_drive) * 2+:2])
				0:
					;
				1:
					if ((~sd_busy & ~i_scan_lock) & (state == 32'd0)) begin
						sd_buff_type <= UPD765_SD_BUFF_SECTOR;
						i_scan_lock <= 1;
						ds0 <= i_current_drive;
						sd_rd[i_current_drive] <= 1;
						sd_lba <= 0;
						sd_busy <= 1;
						i_track_offset <= 16'h0001;
						image_track_offsets_addr <= 0;
						buff_addr <= 0;
						buff_wait <= 1;
						image_scan_state[(1 - i_current_drive) * 2+:2] <= 2;
					end
				2:
					if (~sd_busy & ~buff_wait) begin
						if (buff_addr == 0) begin
							if (buff_data_in == "E")
								image_edsk[i_current_drive] <= 1;
							else if (buff_data_in == "M")
								image_edsk[i_current_drive] <= 0;
							else begin
								image_ready[i_current_drive] <= 0;
								image_scan_state[(1 - i_current_drive) * 2+:2] <= 0;
								i_scan_lock <= 0;
							end
						end
						else if (buff_addr == 9'h030)
							image_tracks[i_current_drive] <= buff_data_in;
						else if (buff_addr == 9'h031)
							image_sides[i_current_drive] <= buff_data_in[1];
						else if (buff_addr == 9'h033)
							i_track_size <= buff_data_in;
						else if (buff_addr >= 9'h034) begin
							if (image_track_offsets_addr[8:1] != image_tracks[i_current_drive]) begin
								image_track_offsets_wr <= 1;
								if (image_edsk[i_current_drive]) begin
									image_track_offsets_out <= (buff_data_in ? i_track_offset : 16'd0);
									i_track_offset <= i_track_offset + buff_data_in;
								end
								else begin
									image_track_offsets_out <= i_track_offset;
									i_track_offset <= i_track_offset + i_track_size;
								end
								image_scan_state[(1 - i_current_drive) * 2+:2] <= 3;
							end
							else begin
								image_ready[i_current_drive] <= 1;
								image_scan_state[(1 - i_current_drive) * 2+:2] <= 0;
								image_trackinfo_dirty[i_current_drive] <= 1;
								i_scan_lock <= 0;
							end
						end
						buff_addr <= buff_addr + 1'd1;
						buff_wait <= 1;
					end
				3: begin
					image_track_offsets_wr <= 0;
					image_track_offsets_addr <= image_track_offsets_addr + {~image_sides[i_current_drive], image_sides[i_current_drive]};
					image_scan_state[(1 - i_current_drive) * 2+:2] <= 2;
				end
			endcase
		if (reset) begin
			m_status <= 8'h80;
			state <= 32'd0;
			status[24+:8] <= 0;
			status[16+:8] <= 0;
			status[8+:8] <= 0;
			ncn <= 16'h0000;
			pcn <= 16'h0000;
			int_state <= 2'h0;
			seek_state <= 4'h0;
			image_trackinfo_dirty <= 2'h3;
			{ack, sd_busy} <= 0;
			sd_rd <= 0;
			sd_wr <= 0;
			image_track_offsets_wr <= 0;
			if (image_scan_state[2+:2])
				image_scan_state[2+:2] <= 1;
			if (image_scan_state[0+:2])
				image_scan_state[0+:2] <= 1;
			i_scan_lock <= 0;
			i_srt <= 4;
		end
		else if (ce) begin
			ack <= {ack[4:0], sd_ack};
			if (ack[5:4] == 'b1) begin
				sd_rd <= 0;
				sd_wr <= 0;
			end
			if (ack[5:4] == 'b10)
				sd_busy <= 0;
			old_wr <= wr;
			old_rd <= rd;
			case (seek_state[(1 - i_current_drive) * 2+:2])
				0:
					;
				1:
					if (pcn[(1 - i_current_drive) * 8+:8] == ncn[(1 - i_current_drive) * 8+:8]) begin
						int_state[i_current_drive] <= 1;
						seek_state[(1 - i_current_drive) * 2+:2] <= 0;
					end
					else begin
						image_trackinfo_dirty[i_current_drive] <= 1;
						if (fast)
							pcn[(1 - i_current_drive) * 8+:8] <= ncn[(1 - i_current_drive) * 8+:8];
						else begin
							if (pcn[(1 - i_current_drive) * 8+:8] > ncn[(1 - i_current_drive) * 8+:8])
								pcn[(1 - i_current_drive) * 8+:8] <= pcn[(1 - i_current_drive) * 8+:8] - 1'd1;
							if (pcn[(1 - i_current_drive) * 8+:8] < ncn[(1 - i_current_drive) * 8+:8])
								pcn[(1 - i_current_drive) * 8+:8] <= pcn[(1 - i_current_drive) * 8+:8] + 1'd1;
							i_step_state[i_current_drive] <= i_srt;
							i_steptimer[i_current_drive] <= CYCLES;
							seek_state[(1 - i_current_drive) * 2+:2] <= 2;
						end
					end
				2:
					if (i_steptimer[i_current_drive])
						i_steptimer[i_current_drive] <= i_steptimer[i_current_drive] - 1'd1;
					else if (~&i_step_state[i_current_drive]) begin
						i_step_state[i_current_drive] <= i_step_state[i_current_drive] + 1'd1;
						i_steptimer[i_current_drive] <= CYCLES;
					end
					else
						seek_state[(1 - i_current_drive) * 2+:2] <= 1;
			endcase
			if (motor[i_current_drive] & ~image_trackinfo_dirty[i_current_drive]) begin : sv2v_autoblock_3
				reg signed [31:0] i;
				for (i = 0; i < 2; i = i + 1)
					if (i_rpm_timer[i_current_drive][(1 - i) * 20+:20] >= i_rpm_time[(((1 - i_current_drive) * 2) + (1 - i)) * 20+:20]) begin
						i_current_sector_pos[i_current_drive][(1 - i) * 8+:8] <= (i_current_sector_pos[i_current_drive][(1 - i) * 8+:8] == (i_current_track_sectors[i_current_drive][i] - 1'd1) ? 8'd0 : i_current_sector_pos[i_current_drive][(1 - i) * 8+:8] + 1'd1);
						i_rpm_timer[i_current_drive][(1 - i) * 20+:20] <= 0;
					end
					else
						i_rpm_timer[i_current_drive][(1 - i) * 20+:20] <= i_rpm_timer[i_current_drive][(1 - i) * 20+:20] + 1'd1;
			end
			m_status[UPD765_MAIN_D0B] <= |seek_state[2+:2];
			m_status[UPD765_MAIN_D1B] <= |seek_state[0+:2];
			m_status[UPD765_MAIN_CB] <= state != 32'd0;
			case (state)
				32'd0: begin
					m_status[UPD765_MAIN_DIO] <= 0;
					m_status[UPD765_MAIN_RQM] <= !image_scan_state[2+:2] & !image_scan_state[0+:2];
					if ((((~old_wr & wr) & a0) & !image_scan_state[2+:2]) & !image_scan_state[0+:2]) begin
						i_mt <= din[7];
						i_sk <= din[5];
						i_substate <= 0;
						casex (din[7:0])
							8'bxxx00110: state <= 32'd5;
							8'bxxx01100: state <= 32'd4;
							8'bxx000101: state <= 32'd3;
							8'bxx001001: state <= 32'd2;
							8'b0xx00010: state <= 32'd1;
							8'b0x001010: state <= 32'd17;
							8'b0x001101: state <= 32'd23;
							8'bxxx10001: state <= 32'd32;
							8'bxxx11001: state <= 32'd33;
							8'bxxx11101: state <= 32'd34;
							8'b00000111: state <= 32'd35;
							8'b00001000: state <= 32'd36;
							8'b00000011: state <= 32'd39;
							8'b00000100: state <= 32'd41;
							8'b00001111: state <= 32'd43;
							default: state <= 32'd47;
						endcase
					end
					else if ((~old_rd & rd) & a0)
						m_data <= 8'hff;
				end
				32'd36: begin
					m_status[UPD765_MAIN_DIO] <= 1;
					state <= 32'd37;
				end
				32'd37:
					if ((~old_rd & rd) & a0) begin
						if (int_state[0]) begin
							m_data <= (((ncn[8+:8] == pcn[8+:8]) && ready[0]) && image_ready[0] ? 8'h20 : 8'he8);
							state <= 32'd38;
						end
						else if (int_state[1]) begin
							m_data <= (((ncn[0+:8] == pcn[0+:8]) && ready[1]) && image_ready[1] ? 8'h21 : 8'he9);
							state <= 32'd38;
						end
						else begin
							m_data <= 8'h80;
							state <= 32'd0;
						end
					end
				32'd38:
					if ((~old_rd & rd) & a0) begin
						m_data <= (int_state[0] ? pcn[8+:8] : pcn[0+:8]);
						int_state[(int_state[0] ? 0 : 1)] <= 0;
						state <= 32'd0;
					end
				32'd41: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						state <= 32'd42;
						m_status[UPD765_MAIN_DIO] <= 1;
						ds0 <= din[0];
					end
				end
				32'd42:
					if ((~old_rd & rd) & a0) begin
						m_data <= {1'b0, ready[ds0] & image_wp[ds0], available[ds0], image_ready[ds0] & !pcn[(1 - ds0) * 8+:8], image_ready[ds0] & image_sides[ds0], image_ready[ds0] & hds, 1'b0, ds0};
						state <= 32'd0;
					end
				32'd39: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						i_srt <= din[7:4];
						state <= 32'd40;
					end
				end
				32'd40:
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				32'd35:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						int_state[din[0]] <= 0;
						ncn[(1 - din[0]) * 8+:8] <= 0;
						seek_state[(1 - din[0]) * 2+:2] <= 1;
						state <= 32'd0;
					end
				32'd43:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						int_state[din[0]] <= 0;
						state <= 32'd44;
					end
				32'd44:
					if ((~old_wr & wr) & a0) begin
						ncn[(1 - ds0) * 8+:8] <= din;
						if ((((motor[ds0] && ready[ds0]) && image_ready[ds0]) && (din < image_tracks[ds0])) || !din)
							seek_state[(1 - ds0) * 2+:2] <= 1;
						else
							int_state[ds0] <= 1;
						state <= 32'd0;
					end
				32'd17: begin
					int_state <= 2'h0;
					state <= 32'd18;
				end
				32'd18:
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						if ((~motor[din[0]] | ~ready[din[0]]) | ~image_ready[din[0]]) begin
							status[24+:8] <= 8'h40;
							status[16+:8] <= 8'b00000101;
							status[8+:8] <= 0;
							state <= 32'd46;
						end
						else if (din[2] & ~image_sides[din[0]]) begin
							status[24+:8] <= 8'h48;
							status[16+:8] <= 0;
							status[8+:8] <= 0;
							state <= 32'd46;
						end
						else begin
							hds <= din[2];
							m_status[UPD765_MAIN_RQM] <= 0;
							i_command <= 32'd19;
							state <= 32'd49;
						end
					end
				32'd19: begin
					image_track_offsets_addr <= {pcn[(1 - ds0) * 8+:8], hds};
					buff_wait <= 1;
					state <= 32'd20;
				end
				32'd20:
					if (~sd_busy & ~buff_wait) begin
						if (image_track_offsets_in)
							state <= 32'd21;
						else begin
							status[24+:8] <= 8'h40;
							status[16+:8] <= 8'b00000101;
							status[8+:8] <= 0;
							state <= 32'd46;
						end
					end
				32'd21:
					if ((~sd_busy & ~buff_wait) & (!i_rpm_timer[ds0][(1 - hds) * 20+:20] | fast)) begin
						sd_buff_type <= UPD765_SD_BUFF_TRACKINFO;
						buff_addr <= {image_track_offsets_in[0], 8'h18 + (i_current_sector_pos[ds0][(1 - hds) * 8+:8] << 3)};
						buff_wait <= 1;
						state <= 32'd22;
					end
				32'd22:
					if (~buff_wait) begin
						if (buff_addr[2:0] == 8'h00)
							i_sector_c <= buff_data_in;
						else if (buff_addr[2:0] == 8'h01)
							i_sector_h <= buff_data_in;
						else if (buff_addr[2:0] == 8'h02)
							i_sector_r <= buff_data_in;
						else if (buff_addr[2:0] == 8'h03) begin
							i_sector_n <= buff_data_in;
							status[24+:8] <= 0;
							status[16+:8] <= 0;
							status[8+:8] <= 0;
							state <= 32'd46;
						end
						buff_addr <= buff_addr + 1'd1;
						buff_wait <= 1;
					end
				32'd1: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd45;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b100;
				end
				32'd3: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd45;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b010;
				end
				32'd2: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd45;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b011;
				end
				32'd5: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd45;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b000;
				end
				32'd4: begin
					int_state <= 2'h0;
					i_command <= 32'd6;
					state <= 32'd45;
					{i_rtrack, i_write, i_rw_deleted} <= 3'b001;
				end
				32'd6:
					if (i_write & image_wp[ds0]) begin
						status[24+:8] <= 8'h40;
						status[16+:8] <= 8'h02;
						status[8+:8] <= 0;
						state <= 32'd46;
					end
					else begin
						m_status[UPD765_MAIN_RQM] <= 0;
						i_command <= 32'd7;
						state <= 32'd49;
					end
				32'd7: begin
					m_status[UPD765_MAIN_DIO] <= ~i_write;
					if (i_rtrack)
						i_r <= 1;
					i_bc <= 1;
					image_track_offsets_addr <= {pcn[(1 - ds0) * 8+:8], hds};
					buff_wait <= 1;
					state <= 32'd8;
				end
				32'd8:
					if (~sd_busy & ~buff_wait) begin
						i_current_sector <= 1'd1;
						sd_buff_type <= UPD765_SD_BUFF_TRACKINFO;
						i_seek_pos <= {image_track_offsets_in + 1'd1, 8'd0};
						buff_addr <= {image_track_offsets_in[0], 8'h14};
						buff_wait <= 1;
						state <= 32'd9;
					end
				32'd9:
					if (~sd_busy & ~buff_wait) begin
						if (buff_addr[7:0] == 8'h14) begin
							if (!image_edsk[ds0])
								i_sector_size <= 8'h80 << buff_data_in[2:0];
							buff_addr[7:0] <= 8'h18;
							buff_wait <= 1;
						end
						else if (i_current_sector > i_total_sectors) begin
							m_status[UPD765_MAIN_EXM] <= 0;
							status[24+:8] <= (i_rtrack ? 8'h00 : 8'h40);
							status[16+:8] <= (i_rtrack ? 8'h00 : 8'h04);
							status[8+:8] <= (i_rtrack | ~i_bc ? 8'h00 : (i_sector_c == 8'hff ? 8'h02 : 8'h10));
							state <= 32'd46;
						end
						else begin
							case (buff_addr[2:0])
								0: i_sector_c <= buff_data_in;
								1: i_sector_h <= buff_data_in;
								2: i_sector_r <= buff_data_in;
								3: i_sector_n <= buff_data_in;
								4: i_sector_st1 <= buff_data_in;
								5: i_sector_st2 <= buff_data_in;
								6:
									if (image_edsk[ds0])
										i_sector_size[7:0] <= buff_data_in;
								7: begin
									if (image_edsk[ds0])
										i_sector_size[15:8] <= buff_data_in;
									state <= 32'd10;
								end
							endcase
							buff_addr <= buff_addr + 1'd1;
							buff_wait <= 1;
						end
					end
				32'd10:
					if ((i_rtrack && (i_current_sector == i_r)) || ((((~i_rtrack && (i_sector_c == i_c)) && (i_sector_r == i_r)) && (i_sector_h == i_h)) && ((i_sector_n == i_n) || !i_n))) begin
						if ((i_sk & ~i_rtrack) & (i_rw_deleted ^ i_sector_st2[6]))
							state <= 32'd16;
						else begin
							i_bytes_to_read <= (i_n ? 8'h80 << (i_n[3] ? 4'h8 : i_n[2:0]) : i_dtl);
							i_timeout <= OVERRUN_TIMEOUT;
							i_weak_sector <= 0;
							state <= 32'd12;
						end
					end
					else begin
						if (i_sector_c == i_c)
							i_bc <= 0;
						i_current_sector <= i_current_sector + 1'd1;
						i_seek_pos <= i_seek_pos + i_sector_size;
						state <= 32'd9;
					end
				32'd12:
					if (fast || ((i_current_sector_pos[ds0][(1 - hds) * 8+:8] == (i_current_sector - 1'd1)) && (i_rpm_timer[ds0][(1 - hds) * 20+:20] == (i_rpm_time[(((1 - ds0) * 2) + (1 - hds)) * 20+:20] >> 2)))) begin
						m_status[UPD765_MAIN_EXM] <= 1;
						state <= 32'd13;
					end
				32'd13:
					if (image_edsk[ds0] && (((i_sector_size == {i_bytes_to_read, 1'b0}) || (i_sector_size == ({i_bytes_to_read, 1'b0} + i_bytes_to_read))) || (i_sector_size == {i_bytes_to_read, 2'b00}))) begin
						if (i_weak_sector != next_weak_sector[ds0]) begin
							i_seek_pos <= i_seek_pos + i_bytes_to_read;
							i_sector_size <= i_sector_size - i_bytes_to_read;
							i_weak_sector <= i_weak_sector + 1'd1;
						end
						else begin
							next_weak_sector[ds0] <= next_weak_sector[ds0] + 1'd1;
							state <= 32'd11;
						end
					end
					else begin
						if (((((SPECCY_SPEEDLOCK_HACK & (i_current_sector == 2)) & !pcn[(1 - ds0) * 8+:8]) & ~hds) & i_sector_st1[5]) & i_sector_st2[5])
							next_weak_sector[ds0] <= next_weak_sector[ds0] + 1'd1;
						else
							next_weak_sector[ds0] <= 0;
						state <= 32'd11;
					end
				32'd11:
					if (~sd_busy) begin
						sd_buff_type <= UPD765_SD_BUFF_SECTOR;
						sd_rd[ds0] <= 1;
						sd_lba <= i_seek_pos[31:9];
						sd_busy <= 1;
						buff_addr <= i_seek_pos[8:0];
						buff_wait <= 1;
						state <= 32'd14;
					end
				32'd14:
					if (~sd_busy & ~buff_wait) begin
						if (!i_bytes_to_read) begin
							if ((i_write && buff_addr) && (i_seek_pos < image_size[ds0])) begin
								sd_lba <= i_seek_pos[31:9];
								sd_wr[ds0] <= 1;
								sd_busy <= 1;
							end
							state <= 32'd16;
						end
						else if (!i_timeout) begin
							m_status[UPD765_MAIN_EXM] <= 0;
							status[24+:8] <= 8'h40;
							status[16+:8] <= 8'h10;
							status[8+:8] <= i_sector_st2 | (i_rw_deleted ? 8'h40 : 8'h00);
							state <= 32'd46;
						end
						else if (~m_status[UPD765_MAIN_RQM])
							m_status[UPD765_MAIN_RQM] <= 1;
						else if (((~i_write & ~old_rd) & rd) & a0) begin
							if (&buff_addr)
								state <= 32'd11;
							m_data <= ((((((SPECCY_SPEEDLOCK_HACK & (i_current_sector == 2)) & !pcn[(1 - ds0) * 8+:8]) & ~hds) & i_sector_st1[5]) & i_sector_st2[5]) & !i_bytes_to_read[14:4] ? buff_data_in << next_weak_sector[ds0] : buff_data_in);
							m_status[UPD765_MAIN_RQM] <= 0;
							if (i_sector_size) begin
								i_sector_size <= i_sector_size - 1'd1;
								buff_addr <= buff_addr + 1'd1;
								buff_wait <= 1;
								i_seek_pos <= i_seek_pos + 1'd1;
							end
							i_bytes_to_read <= i_bytes_to_read - 1'd1;
							i_timeout <= OVERRUN_TIMEOUT;
						end
						else if (((i_write & ~old_wr) & wr) & a0) begin
							buff_wr <= 1;
							buff_data_out <= din;
							i_timeout <= OVERRUN_TIMEOUT;
							m_status[UPD765_MAIN_RQM] <= 0;
							state <= 32'd15;
						end
						else
							i_timeout <= i_timeout - 1'd1;
					end
				32'd15: begin
					buff_wr <= 0;
					if (i_sector_size) begin
						i_sector_size <= i_sector_size - 1'd1;
						buff_addr <= buff_addr + 1'd1;
						buff_wait <= 1;
						i_seek_pos <= i_seek_pos + 1'd1;
					end
					i_bytes_to_read <= i_bytes_to_read - 1'd1;
					if (&buff_addr) begin
						if (i_seek_pos < image_size[ds0]) begin
							sd_lba <= i_seek_pos[31:9];
							sd_wr[ds0] <= 1;
							sd_busy <= 1;
						end
						state <= 32'd11;
					end
					else
						state <= 32'd14;
				end
				32'd16:
					if (~sd_busy) begin
						if ((~i_rtrack & ~(i_sk & (i_rw_deleted ^ i_sector_st2[6]))) & ((i_sector_st1[5] & i_sector_st2[5]) | (i_rw_deleted ^ i_sector_st2[6]))) begin
							m_status[UPD765_MAIN_EXM] <= 0;
							status[24+:8] <= 8'h40;
							status[16+:8] <= i_sector_st1;
							status[8+:8] <= i_sector_st2 | (i_rw_deleted ? 8'h40 : 8'h00);
							state <= 32'd46;
						end
						else if ((i_rtrack ? i_current_sector : i_sector_r) == i_eot) begin
							m_status[UPD765_MAIN_EXM] <= 0;
							status[24+:8] <= (i_rtrack ? 8'h00 : 8'h40);
							status[16+:8] <= 8'h80;
							status[8+:8] <= (i_rw_deleted ^ i_sector_st2[6] ? 8'h40 : 8'h00);
							state <= 32'd46;
						end
						else begin
							if (i_mt & image_sides[ds0]) begin
								hds <= ~hds;
								i_h <= ~i_h;
								image_track_offsets_addr <= {pcn[(1 - ds0) * 8+:8], ~hds};
								buff_wait <= 1;
							end
							if ((~i_mt | hds) | ~image_sides[ds0])
								i_r <= i_r + 1'd1;
							state <= 32'd8;
						end
					end
				32'd23: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0) begin
						ds0 <= din[0];
						state <= 32'd24;
					end
				end
				32'd24:
					if ((~old_wr & wr) & a0) begin
						i_n <= din;
						state <= 32'd25;
					end
				32'd25:
					if ((~old_wr & wr) & a0) begin
						i_sc <= din;
						state <= 32'd26;
					end
				32'd26:
					if ((~old_wr & wr) & a0)
						state <= 32'd27;
				32'd27:
					if ((~old_wr & wr) & a0) begin
						m_status[UPD765_MAIN_EXM] <= 1;
						state <= 32'd28;
					end
				32'd28:
					if (!i_sc) begin
						m_status[UPD765_MAIN_EXM] <= 0;
						status[24+:8] <= 0;
						status[16+:8] <= 0;
						status[8+:8] <= 0;
						state <= 32'd46;
					end
					else if ((~old_wr & wr) & a0) begin
						i_c <= din;
						state <= 32'd29;
					end
				32'd29:
					if ((~old_wr & wr) & a0) begin
						i_h <= din;
						state <= 32'd30;
					end
				32'd30:
					if ((~old_wr & wr) & a0) begin
						i_r <= din;
						state <= 32'd31;
					end
				32'd31:
					if ((~old_wr & wr) & a0) begin
						i_n <= din;
						i_sc <= i_sc - 1'd1;
						i_r <= i_r + 1'd1;
						state <= 32'd28;
					end
				32'd32: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd34: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd33: begin
					int_state <= 2'h0;
					if ((~old_wr & wr) & a0)
						state <= 32'd0;
				end
				32'd45:
					if ((!old_wr & wr) & a0)
						case (i_substate)
							0: begin
								ds0 <= din[0];
								hds <= din[2];
								i_substate <= 1;
							end
							1: begin
								i_c <= din;
								i_substate <= 2;
							end
							2: begin
								i_h <= din;
								i_substate <= 3;
							end
							3: begin
								i_r <= din;
								i_substate <= 4;
							end
							4: begin
								i_n <= din;
								i_substate <= 5;
							end
							5: begin
								i_eot <= din;
								i_substate <= 6;
							end
							6: i_substate <= 7;
							7: begin
								i_dtl <= din;
								i_substate <= 0;
								if ((~motor[ds0] | ~ready[ds0]) | ~image_ready[ds0]) begin
									status[24+:8] <= 8'h40;
									status[16+:8] <= 8'b00000101;
									status[8+:8] <= 0;
									state <= 32'd46;
								end
								else if (hds & ~image_sides[ds0]) begin
									hds <= 0;
									status[24+:8] <= 8'h48;
									status[16+:8] <= 0;
									status[8+:8] <= 0;
									state <= 32'd46;
								end
								else
									state <= i_command;
							end
						endcase
				32'd46: begin
					m_status[UPD765_MAIN_RQM] <= 1;
					m_status[UPD765_MAIN_DIO] <= 1;
					if ((~old_rd & rd) & a0)
						case (i_substate)
							0: begin
								m_data <= {status[31-:5], hds, 1'b0, ds0};
								i_substate <= 1;
							end
							1: begin
								m_data <= status[16+:8];
								i_substate <= 2;
							end
							2: begin
								m_data <= status[8+:8];
								i_substate <= 3;
							end
							3: begin
								m_data <= i_sector_c;
								i_substate <= 4;
							end
							4: begin
								m_data <= i_sector_h;
								i_substate <= 5;
							end
							5: begin
								m_data <= i_sector_r;
								i_substate <= 6;
							end
							6: begin
								m_data <= i_sector_n;
								state <= 32'd0;
							end
							7:
								;
						endcase
				end
				32'd47: begin
					int_state <= 2'h0;
					m_status[UPD765_MAIN_DIO] <= 1;
					status[24+:8] <= 8'h80;
					state <= 32'd48;
				end
				32'd48:
					if ((~old_rd & rd) & a0) begin
						state <= 32'd0;
						m_data <= status[24+:8];
					end
				32'd49:
					if (image_ready[ds0] & image_trackinfo_dirty[ds0]) begin
						i_rpm_timer[ds0] <= 40'h0000000000;
						next_weak_sector[ds0] <= 0;
						image_track_offsets_addr <= {pcn[(1 - ds0) * 8+:8], 1'b0};
						old_hds <= hds;
						hds <= 0;
						buff_wait <= 1;
						state <= 32'd50;
					end
					else
						state <= i_command;
				32'd50:
					if (~buff_wait & ~sd_busy) begin
						if (image_ready[ds0] && image_track_offsets_in) begin
							sd_buff_type <= UPD765_SD_BUFF_TRACKINFO;
							sd_rd[ds0] <= 1;
							sd_lba <= image_track_offsets_in[15:1];
							sd_busy <= 1;
							state <= 32'd51;
						end
						else begin
							image_trackinfo_dirty[ds0] <= 0;
							hds <= old_hds;
							state <= i_command;
						end
					end
				32'd51:
					if (~sd_busy) begin
						buff_addr <= {image_track_offsets_in[0], 8'h15};
						buff_wait <= 1;
						state <= 32'd52;
					end
				32'd52:
					if (~sd_busy & ~buff_wait) begin
						i_current_track_sectors[ds0][hds] <= buff_data_in;
						i_rpm_time[(((1 - ds0) * 2) + (1 - hds)) * 20+:20] <= (buff_data_in ? TRACK_TIME / buff_data_in : CYCLES);
						i_current_sector_pos[ds0][(1 - hds) * 8+:8] <= buff_data_in[7:1];
						if (hds == image_sides[ds0]) begin
							image_trackinfo_dirty[ds0] <= 0;
							hds <= old_hds;
							state <= i_command;
						end
						else begin
							image_track_offsets_addr <= {pcn[(1 - ds0) * 8+:8], 1'b1};
							hds <= 1;
							buff_wait <= 1;
							state <= 32'd50;
						end
					end
			endcase
		end
	end
endmodule
