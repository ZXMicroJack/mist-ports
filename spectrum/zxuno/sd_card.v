module sd_card (
	clk_sys,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_ack_conf,
	sd_conf,
	sd_sdhc,
	img_mounted,
	img_size,
	sd_busy,
	sd_buff_dout,
	sd_buff_wr,
	sd_buff_din,
	sd_buff_addr,
	allow_sdhc,
	sd_cs,
	sd_sck,
	sd_sdi,
	sd_sdo
);
	input clk_sys;
	output reg [31:0] sd_lba;
	output reg sd_rd;
	output reg sd_wr;
	input sd_ack;
	input sd_ack_conf;
	output wire sd_conf;
	output wire sd_sdhc;
	input img_mounted;
	input [31:0] img_size;
	output reg sd_busy = 0;
	input [7:0] sd_buff_dout;
	input sd_buff_wr;
	output wire [7:0] sd_buff_din;
	input [8:0] sd_buff_addr;
	input allow_sdhc;
	input sd_cs;
	input sd_sck;
	input sd_sdi;
	output reg sd_sdo;
	wire [31:0] OCR = {1'b1, sd_sdhc, 30'h000f8000};
	wire [7:0] READ_DATA_TOKEN = 8'hfe;
	localparam NCR = 4;
	localparam RD_STATE_IDLE = 3'd0;
	localparam RD_STATE_WAIT_IO = 3'd1;
	localparam RD_STATE_SEND_TOKEN = 3'd2;
	localparam RD_STATE_SEND_DATA = 3'd3;
	localparam RD_STATE_DELAY = 3'd4;
	reg [2:0] read_state = RD_STATE_IDLE;
	localparam WR_STATE_IDLE = 3'd0;
	localparam WR_STATE_EXP_DTOKEN = 3'd1;
	localparam WR_STATE_RECV_DATA = 3'd2;
	localparam WR_STATE_RECV_CRC0 = 3'd3;
	localparam WR_STATE_RECV_CRC1 = 3'd4;
	localparam WR_STATE_SEND_DRESP = 3'd5;
	localparam WR_STATE_BUSY = 3'd6;
	reg [2:0] write_state = WR_STATE_IDLE;
	reg card_is_reset = 1'b0;
	reg [6:0] sbuf;
	reg cmd55;
	reg terminate_cmd = 1'b0;
	reg [7:0] cmd = 8'h00;
	reg [2:0] bit_cnt = 3'd0;
	reg [3:0] byte_cnt = 4'd15;
	reg [4:0] delay_cnt;
	reg [39:0] args;
	reg [7:0] reply;
	reg [7:0] reply0;
	reg [7:0] reply1;
	reg [7:0] reply2;
	reg [7:0] reply3;
	reg [3:0] reply_len;
	reg [9:0] buffer_ptr;
	wire [7:0] buffer_dout;
	reg [7:0] buffer_din;
	reg buffer_write_strobe;
	reg sd_buff_sel;
	sd_card_dpram #(
		.DATAWIDTH(8),
		.ADDRWIDTH(10)
	) buffer_dpram(
		.clock_a(clk_sys),
		.address_a({sd_buff_sel, sd_buff_addr}),
		.data_a(sd_buff_dout),
		.wren_a(sd_buff_wr & sd_ack),
		.q_a(sd_buff_din),
		.clock_b(clk_sys),
		.address_b(buffer_ptr),
		.data_b(buffer_din),
		.wren_b(buffer_write_strobe),
		.q_b(buffer_dout)
	);
	wire [7:0] WRITE_DATA_RESPONSE = 8'h05;
	reg [7:0] conf;
	reg sd_configuring = 1;
	assign sd_conf = sd_configuring;
	reg [4:0] conf_buff_ptr;
	reg [7:0] conf_byte;
	reg [255:0] csdcid;
	wire sd_has_sdhc = conf[0];
	assign sd_sdhc = allow_sdhc && sd_has_sdhc;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg old_mounted;
		if (sd_buff_wr & sd_ack_conf) begin
			if (sd_buff_addr == 32) begin
				conf <= sd_buff_dout;
				sd_configuring <= 0;
			end
			else
				csdcid[(31 - sd_buff_addr) << 3+:8] <= sd_buff_dout;
		end
		conf_byte <= csdcid[(31 - conf_buff_ptr) << 3+:8];
		old_mounted <= img_mounted;
		if (~old_mounted & img_mounted) begin
			if (sd_sdhc)
				csdcid[69:48] <= {9'd0, img_size[31:19]};
			else begin
				csdcid[49:47] <= 3'd7;
				csdcid[73:62] <= img_size[29:18];
			end
		end
	end
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg old_sd_sck;
		reg [5:0] ack;
		ack <= {ack[4:0], sd_ack};
		if (ack[5:4] == 'b1)
			{sd_rd, sd_wr} <= 2'b00;
		if (ack[5:4] == 'b10)
			sd_busy <= 0;
		buffer_write_strobe <= 0;
		if (buffer_write_strobe)
			buffer_ptr <= buffer_ptr + 1'd1;
		old_sd_sck <= sd_sck;
		if (((sd_cs == 0) && old_sd_sck) && ~sd_sck) begin
			sd_sdo <= 1'b1;
			if (byte_cnt == 9) begin
				sd_sdo <= reply[~bit_cnt];
				if (bit_cnt == 7) begin
					if ((cmd == 8'h49) || (cmd == 8'h4a))
						read_state <= RD_STATE_SEND_TOKEN;
					if (((cmd == 8'h51) || (cmd == 8'h52)) && !terminate_cmd) begin
						sd_lba <= (sd_sdhc ? args[39:8] : {9'd0, args[39:17]});
						read_state <= RD_STATE_WAIT_IO;
						sd_rd <= 1;
						sd_busy <= 1;
					end
				end
			end
			else if ((reply_len > 0) && (byte_cnt == 10))
				sd_sdo <= reply0[~bit_cnt];
			else if ((reply_len > 1) && (byte_cnt == 11))
				sd_sdo <= reply1[~bit_cnt];
			else if ((reply_len > 2) && (byte_cnt == 12))
				sd_sdo <= reply2[~bit_cnt];
			else if ((reply_len > 3) && (byte_cnt == 13))
				sd_sdo <= reply3[~bit_cnt];
			case (read_state)
				RD_STATE_IDLE:
					;
				RD_STATE_WAIT_IO: begin
					buffer_ptr <= 0;
					sd_buff_sel <= 0;
					if (~sd_busy) begin
						if (terminate_cmd) begin
							cmd <= 0;
							read_state <= RD_STATE_IDLE;
						end
						else if (bit_cnt == 7)
							read_state <= RD_STATE_SEND_TOKEN;
					end
				end
				RD_STATE_SEND_TOKEN:
					if (~sd_busy) begin
						sd_sdo <= READ_DATA_TOKEN[~bit_cnt];
						if (bit_cnt == 7) begin
							read_state <= RD_STATE_SEND_DATA;
							conf_buff_ptr <= (cmd == 8'h4a ? 5'h00 : 5'h10);
						end
					end
				RD_STATE_SEND_DATA: begin
					if ((cmd == 8'h51) || ((cmd == 8'h52) && !terminate_cmd))
						sd_sdo <= buffer_dout[~bit_cnt];
					else if ((cmd == 8'h49) || (cmd == 8'h4a))
						sd_sdo <= conf_byte[~bit_cnt];
					if (bit_cnt == 7) begin
						if ((cmd == 8'h51) && &buffer_ptr[8:0])
							read_state <= RD_STATE_IDLE;
						if (cmd == 8'h52) begin
							if (terminate_cmd) begin
								read_state <= RD_STATE_IDLE;
								cmd <= 0;
							end
							else if (buffer_ptr[8:0] == 10) begin
								sd_lba <= sd_lba + 1'd1;
								sd_rd <= 1;
								sd_busy <= 1;
								sd_buff_sel <= !sd_buff_sel;
							end
							else if (&buffer_ptr[8:0]) begin
								delay_cnt <= 20;
								read_state <= RD_STATE_DELAY;
							end
						end
						if (((cmd == 8'h49) || (cmd == 8'h4a)) && (conf_buff_ptr[3:0] == 4'hf))
							read_state <= RD_STATE_IDLE;
						buffer_ptr <= buffer_ptr + 1'd1;
						conf_buff_ptr <= conf_buff_ptr + 1'd1;
					end
				end
				RD_STATE_DELAY:
					if (bit_cnt == 7) begin
						if (delay_cnt == 0)
							read_state <= RD_STATE_SEND_TOKEN;
						else
							delay_cnt <= delay_cnt - 1'd1;
					end
			endcase
			if (write_state == WR_STATE_SEND_DRESP)
				sd_sdo <= WRITE_DATA_RESPONSE[~bit_cnt];
			if (write_state == WR_STATE_BUSY)
				sd_sdo <= 1'b0;
		end
		if (sd_cs == 1) begin
			bit_cnt <= 3'd0;
			terminate_cmd <= 0;
			cmd <= 0;
			read_state <= RD_STATE_IDLE;
		end
		else if (~old_sd_sck & sd_sck) begin
			bit_cnt <= bit_cnt + 3'd1;
			if (bit_cnt != 7)
				sbuf[6:0] <= {sbuf[5:0], sd_sdi};
			else begin
				if (byte_cnt != 15)
					byte_cnt <= byte_cnt + 4'd1;
				if ((((byte_cnt > 5) && (write_state == WR_STATE_IDLE)) && ((read_state == RD_STATE_IDLE) || ((read_state != RD_STATE_IDLE) && ({sbuf, sd_sdi} == 8'h4c)))) && (sbuf[6:5] == 2'b01)) begin
					byte_cnt <= 4'd0;
					terminate_cmd <= 0;
					if ({sbuf, sd_sdi} == 8'h4c)
						terminate_cmd <= 1;
					else
						cmd <= {sbuf, sd_sdi};
				end
				if (byte_cnt == 0)
					args[39:32] <= {sbuf, sd_sdi};
				if (byte_cnt == 1)
					args[31:24] <= {sbuf, sd_sdi};
				if (byte_cnt == 2)
					args[23:16] <= {sbuf, sd_sdi};
				if (byte_cnt == 3)
					args[15:8] <= {sbuf, sd_sdi};
				if (byte_cnt == 4)
					args[7:0] <= {sbuf, sd_sdi};
				if (byte_cnt == 5) begin
					reply <= 8'h04;
					reply_len <= 4'd0;
					cmd55 <= 0;
					if (cmd == 8'h40) begin
						card_is_reset <= 1'b1;
						reply <= 8'h01;
					end
					else if (card_is_reset) begin
						if (terminate_cmd)
							reply <= 8'h00;
						else
							case (cmd)
								8'h41: reply <= 8'h00;
								8'h48: begin
									reply <= 8'h01;
									reply0 <= 8'h00;
									reply1 <= 8'h00;
									reply2 <= {4'b0000, args[19:16]};
									reply3 <= args[15:8];
									reply_len <= 4'd4;
								end
								8'h49: reply <= 8'h00;
								8'h4a: reply <= 8'h00;
								8'h4d: begin
									reply <= 8'h00;
									reply0 <= 8'h00;
									reply_len <= 4'd1;
								end
								8'h50:
									if (args[39:8] == 32'd512)
										reply <= 8'h00;
									else
										reply <= 8'h40;
								8'h51: reply <= 8'h00;
								8'h52: reply <= 8'h00;
								8'h58: begin
									reply <= 8'h00;
									sd_lba <= (sd_sdhc ? args[39:8] : {9'd0, args[39:17]});
									write_state <= WR_STATE_EXP_DTOKEN;
								end
								8'h69:
									if (cmd55)
										reply <= 8'h00;
								8'h77: begin
									reply <= 8'h01;
									cmd55 <= 1;
								end
								8'h7a: begin
									reply <= 8'h00;
									reply0 <= OCR[31:24];
									reply1 <= OCR[23:16];
									reply2 <= OCR[15:8];
									reply3 <= OCR[7:0];
									reply_len <= 4'd4;
								end
								'h7b: reply <= 0;
							endcase
					end
				end
				case (write_state)
					WR_STATE_IDLE:
						;
					WR_STATE_EXP_DTOKEN:
						if ({sbuf, sd_sdi} == 8'hfe) begin
							write_state <= WR_STATE_RECV_DATA;
							buffer_ptr <= 0;
							sd_buff_sel <= 0;
						end
					WR_STATE_RECV_DATA: begin
						buffer_write_strobe <= 1'b1;
						buffer_din <= {sbuf, sd_sdi};
						if (&buffer_ptr[8:0])
							write_state <= WR_STATE_RECV_CRC0;
					end
					WR_STATE_RECV_CRC0: write_state <= WR_STATE_RECV_CRC1;
					WR_STATE_RECV_CRC1: write_state <= WR_STATE_SEND_DRESP;
					WR_STATE_SEND_DRESP: begin
						write_state <= WR_STATE_BUSY;
						sd_wr <= 1;
						sd_busy <= 1;
					end
					WR_STATE_BUSY:
						if (~sd_busy)
							write_state <= WR_STATE_IDLE;
					default:
						;
				endcase
			end
		end
	end
endmodule
