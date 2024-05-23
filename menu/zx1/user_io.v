module user_io (
	conf_str,
	conf_addr,
	conf_chr,
	clk_sys,
	clk_sd,
	SPI_CLK,
	SPI_SS_IO,
	SPI_MISO,
	SPI_MOSI,
	joystick_0,
	joystick_1,
	joystick_2,
	joystick_3,
	joystick_4,
	joystick_analog_0,
	joystick_analog_1,
	buttons,
	switches,
	scandoubler_disable,
	ypbpr,
	no_csync,
	status,
	core_mod,
	rtc,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_ack_conf,
	sd_ack_x,
	sd_conf,
	sd_sdhc,
	sd_dout,
	sd_dout_strobe,
	sd_din,
	sd_din_strobe,
	sd_buff_addr,
	img_mounted,
	img_size,
	ps2_kbd_clk,
	ps2_kbd_data,
	ps2_kbd_clk_i,
	ps2_kbd_data_i,
	ps2_mouse_clk,
	ps2_mouse_data,
	ps2_mouse_clk_i,
	ps2_mouse_data_i,
	key_pressed,
	key_extended,
	key_code,
	key_strobe,
	kbd_out_data,
	kbd_out_strobe,
	mouse_x,
	mouse_y,
	mouse_z,
	mouse_flags,
	mouse_strobe,
	mouse_idx,
	i2c_start,
	i2c_read,
	i2c_addr,
	i2c_subaddr,
	i2c_dout,
	i2c_din,
	i2c_ack,
	i2c_end,
	serial_data,
	serial_strobe
);
	parameter STRLEN = 0;
	input [(8 * STRLEN) - 1:0] conf_str;
	output wire [9:0] conf_addr;
	input [7:0] conf_chr;
	input clk_sys;
	input clk_sd;
	input SPI_CLK;
	input SPI_SS_IO;
	output reg SPI_MISO;
	input SPI_MOSI;
	output reg [31:0] joystick_0;
	output reg [31:0] joystick_1;
	output reg [31:0] joystick_2;
	output reg [31:0] joystick_3;
	output reg [31:0] joystick_4;
	output reg [31:0] joystick_analog_0;
	output reg [31:0] joystick_analog_1;
	output wire [1:0] buttons;
	output wire [1:0] switches;
	output wire scandoubler_disable;
	output wire ypbpr;
	output wire no_csync;
	output reg [63:0] status;
	output reg [6:0] core_mod;
	output reg [63:0] rtc;
	input [31:0] sd_lba;
	parameter SD_IMAGES = 2;
	input [SD_IMAGES - 1:0] sd_rd;
	input [SD_IMAGES - 1:0] sd_wr;
	output reg sd_ack = 0;
	output reg sd_ack_conf = 0;
	output reg [SD_IMAGES - 1:0] sd_ack_x = 0;
	input sd_conf;
	input sd_sdhc;
	output reg [7:0] sd_dout;
	output reg sd_dout_strobe = 0;
	input [7:0] sd_din;
	output reg sd_din_strobe = 0;
	output reg [8:0] sd_buff_addr;
	output reg [SD_IMAGES - 1:0] img_mounted;
	output reg [63:0] img_size;
	output wire ps2_kbd_clk;
	output wire ps2_kbd_data;
	input ps2_kbd_clk_i;
	input ps2_kbd_data_i;
	output wire ps2_mouse_clk;
	output wire ps2_mouse_data;
	input ps2_mouse_clk_i;
	input ps2_mouse_data_i;
	output reg key_pressed;
	output reg key_extended;
	output reg [7:0] key_code;
	output reg key_strobe;
	input [7:0] kbd_out_data;
	input kbd_out_strobe;
	output reg [8:0] mouse_x;
	output reg [8:0] mouse_y;
	output reg [3:0] mouse_z;
	output reg [7:0] mouse_flags;
	output reg mouse_strobe;
	output reg mouse_idx;
	output reg i2c_start;
	output reg i2c_read;
	output reg [6:0] i2c_addr;
	output reg [7:0] i2c_subaddr;
	output reg [7:0] i2c_dout;
	input [7:0] i2c_din;
	input i2c_ack;
	input i2c_end;
	input [7:0] serial_data;
	input serial_strobe;
	parameter PS2DIV = 100;
	parameter ROM_DIRECT_UPLOAD = 0;
	parameter PS2BIDIR = 0;
	parameter FEATURES = 0;
	parameter ARCHIE = 0;
	localparam W = 1; //$clog2(SD_IMAGES);
	reg [6:0] sbuf;
	reg [7:0] cmd;
	reg [2:0] bit_cnt;
	reg [9:0] byte_cnt;
	reg [7:0] but_sw;
	reg [2:0] stick_idx;
	assign buttons = but_sw[1:0];
	assign switches = but_sw[3:2];
	assign scandoubler_disable = but_sw[4];
	assign ypbpr = but_sw[5];
	assign no_csync = but_sw[6];
	assign conf_addr = byte_cnt;
	wire [7:0] core_type = (ARCHIE ? 8'ha6 : (ROM_DIRECT_UPLOAD ? 8'hb4 : 8'ha4));
	reg [W:0] drive_sel;
	always begin : sv2v_autoblock_1
		integer i;
		drive_sel = 0;
		for (i = 0; i < SD_IMAGES; i = i + 1)
			if (sd_rd[i] | sd_wr[i])
				drive_sel = i[W:0];
	end
	wire [7:0] sd_cmd = {4'h6, sd_conf, sd_sdhc, sd_wr[drive_sel], sd_rd[drive_sel]};
	wire spi_sck = SPI_CLK;
	reg ps2_clk;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		integer cnt;
		cnt <= cnt + 1'd1;
		if (cnt == PS2DIV) begin
			ps2_clk <= ~ps2_clk;
			cnt <= 0;
		end
	end
	reg ps2_kbd_tx_strobe;
	wire [7:0] ps2_kbd_rx_byte;
	wire ps2_kbd_rx_strobe;
	wire ps2_kbd_fifo_ok;
	reg [7:0] spi_byte_in;
	user_io_ps2 #(
		.PS2_BIDIR(PS2BIDIR),
		.PS2_FIFO_BITS(4)
	) ps2_kbd(
		.clk_sys(clk_sys),
		.ps2_clk(ps2_clk),
		.ps2_clk_i(ps2_kbd_clk_i),
		.ps2_clk_o(ps2_kbd_clk),
		.ps2_data_i(ps2_kbd_data_i),
		.ps2_data_o(ps2_kbd_data),
		.ps2_tx_strobe(ps2_kbd_tx_strobe),
		.ps2_tx_byte(spi_byte_in),
		.ps2_rx_strobe(ps2_kbd_rx_strobe),
		.ps2_rx_byte(ps2_kbd_rx_byte),
		.ps2_fifo_ready(ps2_kbd_fifo_ok)
	);
	reg ps2_mouse_tx_strobe;
	wire [7:0] ps2_mouse_rx_byte;
	wire ps2_mouse_rx_strobe;
	wire ps2_mouse_fifo_ok;
	user_io_ps2 #(
		.PS2_BIDIR(PS2BIDIR),
		.PS2_FIFO_BITS(3)
	) ps2_mouse(
		.clk_sys(clk_sys),
		.ps2_clk(ps2_clk),
		.ps2_clk_i(ps2_mouse_clk_i),
		.ps2_clk_o(ps2_mouse_clk),
		.ps2_data_i(ps2_mouse_data_i),
		.ps2_data_o(ps2_mouse_data),
		.ps2_tx_strobe(ps2_mouse_tx_strobe),
		.ps2_tx_byte(spi_byte_in),
		.ps2_rx_strobe(ps2_mouse_rx_strobe),
		.ps2_rx_byte(ps2_mouse_rx_byte),
		.ps2_fifo_ready(ps2_mouse_fifo_ok)
	);
	localparam SERIAL_OUT_FIFO_BITS = 6;
	reg [7:0] serial_out_fifo [63:0];
	reg [5:0] serial_out_wptr;
	reg [5:0] serial_out_rptr;
	wire serial_out_data_available = serial_out_wptr != serial_out_rptr;
	wire [7:0] serial_out_byte = serial_out_fifo[serial_out_rptr];
	wire [7:0] serial_out_status = {7'b1000000, serial_out_data_available};
	always @(posedge serial_strobe or posedge status[0]) begin : serial_out
		if (status[0] == 1)
			serial_out_wptr <= 0;
		else begin
			serial_out_fifo[serial_out_wptr] <= serial_data;
			serial_out_wptr <= serial_out_wptr + 1'd1;
		end
	end
	always @(negedge spi_sck or posedge status[0]) begin : serial_in
		if (status[0] == 1)
			serial_out_rptr <= 0;
		else if ((byte_cnt != 0) && (cmd == 8'h1b)) begin
			if (((bit_cnt == 7) && !byte_cnt[0]) && serial_out_data_available)
				serial_out_rptr <= serial_out_rptr + 1'd1;
		end
	end
	always @(posedge spi_sck or posedge SPI_SS_IO) begin : spi_counter
		if (SPI_SS_IO == 1) begin
			bit_cnt <= 0;
			byte_cnt <= 0;
		end
		else begin
			if ((bit_cnt == 7) && ~&byte_cnt)
				byte_cnt <= byte_cnt + 8'd1;
			bit_cnt <= bit_cnt + 1'd1;
		end
	end
	reg [7:0] spi_byte_out;
	always @(negedge spi_sck or posedge SPI_SS_IO) begin : spi_byteout
		if (SPI_SS_IO == 1)
			SPI_MISO <= 1'bz;
		else
			SPI_MISO <= spi_byte_out[~bit_cnt];
	end
	reg [7:0] kbd_out_status = 0;
	reg [7:0] kbd_out_data_r = 0;
	reg kbd_out_data_available = 0;
	generate
		if (ARCHIE) begin : genblk1
			always @(negedge spi_sck or posedge SPI_SS_IO) begin : archie_kbd_out
				if (SPI_SS_IO == 1) begin
					kbd_out_data_r <= 0;
					kbd_out_status <= 0;
				end
				else begin
					kbd_out_status <= {7'h50, kbd_out_data_available};
					kbd_out_data_r <= kbd_out_data;
				end
			end
		end
	endgenerate
	always @(posedge spi_sck or posedge SPI_SS_IO) begin : spi_transmitter
		reg [31:0] sd_lba_r;
		reg [W:0] drive_sel_r;
		reg ps2_kbd_rx_strobeD;
		reg ps2_mouse_rx_strobeD;
		if (SPI_SS_IO == 1)
			spi_byte_out <= core_type;
		else if (bit_cnt == 7) begin
			if (!byte_cnt)
				cmd <= {sbuf, SPI_MOSI};
			spi_byte_out <= 0;
			case ({(!byte_cnt ? {sbuf, SPI_MOSI} : cmd)})
				8'h04:
					if (ARCHIE) begin
						if (byte_cnt == 0)
							spi_byte_out <= kbd_out_status;
						else
							spi_byte_out <= kbd_out_data_r;
					end
				8'h0e:
					if (byte_cnt == 0) begin
						ps2_kbd_rx_strobeD <= ps2_kbd_rx_strobe;
						spi_byte_out <= (ps2_kbd_rx_strobe ^ ps2_kbd_rx_strobeD ? 8'h0e : 8'h00);
					end
					else
						spi_byte_out <= ps2_kbd_rx_byte;
				8'h0f:
					if (byte_cnt == 0) begin
						ps2_mouse_rx_strobeD <= ps2_mouse_rx_strobe;
						spi_byte_out <= (ps2_mouse_rx_strobe ^ ps2_mouse_rx_strobeD ? 8'h0f : 8'h00);
					end
					else
						spi_byte_out <= ps2_mouse_rx_byte;
				8'h14:
					if (STRLEN == 0)
						spi_byte_out <= conf_chr;
					else if (byte_cnt < STRLEN)
						spi_byte_out <= conf_str[((STRLEN - byte_cnt) - 1) << 3+:8];
				8'h16:
					if (byte_cnt == 0) begin
						spi_byte_out <= sd_cmd;
						sd_lba_r <= sd_lba;
						drive_sel_r <= drive_sel;
					end
					else if (byte_cnt == 1)
						spi_byte_out <= drive_sel_r;
					else if (byte_cnt < 6)
						spi_byte_out <= sd_lba_r[(5 - byte_cnt) << 3+:8];
				8'h18: spi_byte_out <= sd_din;
				8'h1b:
					if (byte_cnt[0])
						spi_byte_out <= serial_out_status;
					else
						spi_byte_out <= serial_out_byte;
				8'h80:
					if (byte_cnt == 0)
						spi_byte_out <= 8'h80;
					else
						spi_byte_out <= FEATURES[(4 - byte_cnt) << 3+:8];
				8'h31:
					if (byte_cnt == 0)
						spi_byte_out <= {6'd0, i2c_ack, i2c_end};
					else
						spi_byte_out <= i2c_din;
				//default:
					//spi_byte_out <= cmd;
			endcase
		end
	end
	reg spi_receiver_strobe_r = 0;
	reg spi_transfer_end_r = 1;
	always @(posedge spi_sck or posedge SPI_SS_IO) begin : spi_receiver
		if (SPI_SS_IO == 1)
			spi_transfer_end_r <= 1;
		else begin
			spi_transfer_end_r <= 0;
			if (bit_cnt != 7)
				sbuf[6:0] <= {sbuf[5:0], SPI_MOSI};
			if (bit_cnt == 7) begin
				spi_byte_in <= {sbuf, SPI_MOSI};
				spi_receiver_strobe_r <= ~spi_receiver_strobe_r;
			end
		end
	end
	always @(posedge clk_sys) begin : cmd_block
		reg spi_receiver_strobe;
		reg spi_transfer_end;
		reg spi_receiver_strobeD;
		reg spi_transfer_endD;
		reg [7:0] acmd;
		reg [3:0] abyte_cnt;
		reg [7:0] mouse_flags_r;
		reg [7:0] mouse_x_r;
		reg [7:0] mouse_y_r;
		reg mouse_fifo_ok;
		reg kbd_fifo_ok;
		reg key_pressed_r;
		reg key_extended_r;
		spi_receiver_strobeD <= spi_receiver_strobe_r;
		spi_receiver_strobe <= spi_receiver_strobeD;
		spi_transfer_endD <= spi_transfer_end_r;
		spi_transfer_end <= spi_transfer_endD;
		key_strobe <= 0;
		mouse_strobe <= 0;
		ps2_kbd_tx_strobe <= 0;
		ps2_mouse_tx_strobe <= 0;
		i2c_start <= 0;
		if (ARCHIE) begin
			if (kbd_out_strobe)
				kbd_out_data_available <= 1;
			key_pressed <= 0;
			key_extended <= 0;
			mouse_x <= 0;
			mouse_y <= 0;
			mouse_z <= 0;
			mouse_flags <= 0;
			mouse_idx <= 0;
		end
		if (spi_transfer_end) begin
			abyte_cnt <= 0;
			mouse_fifo_ok <= 0;
			kbd_fifo_ok <= 0;
		end
		else if (spi_receiver_strobeD ^ spi_receiver_strobe) begin
			if (~&abyte_cnt)
				abyte_cnt <= abyte_cnt + 1'd1;
			if (abyte_cnt == 0) begin
				acmd <= spi_byte_in;
				if ((spi_byte_in == 8'h70) || (spi_byte_in == 8'h71))
					mouse_fifo_ok <= ps2_mouse_fifo_ok;
				if (spi_byte_in == 8'h05)
					kbd_fifo_ok <= ps2_kbd_fifo_ok;
			end
			else begin
				if (ARCHIE) begin
					if (acmd == 8'h04)
						kbd_out_data_available <= 0;
					if (acmd == 8'h05) begin
						key_strobe <= 1;
						key_code <= spi_byte_in;
					end
				end
				case (acmd)
					8'h01: but_sw <= spi_byte_in;
					8'h60:
						if (abyte_cnt < 5)
							joystick_0[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h61:
						if (abyte_cnt < 5)
							joystick_1[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h62:
						if (abyte_cnt < 5)
							joystick_2[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h63:
						if (abyte_cnt < 5)
							joystick_3[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h64:
						if (abyte_cnt < 5)
							joystick_4[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h70, 8'h71:
						if (!ARCHIE) begin
							if ((abyte_cnt < 4) && mouse_fifo_ok)
								ps2_mouse_tx_strobe <= 1;
							if (abyte_cnt == 1)
								mouse_flags_r <= spi_byte_in;
							else if (abyte_cnt == 2)
								mouse_x_r <= spi_byte_in;
							else if (abyte_cnt == 3)
								mouse_y_r <= spi_byte_in;
							else if (abyte_cnt == 4) begin
								mouse_flags <= mouse_flags_r;
								mouse_x <= {mouse_flags_r[4], mouse_x_r};
								mouse_y <= {mouse_flags_r[5], mouse_y_r};
								mouse_z <= spi_byte_in[3:0];
								mouse_idx <= acmd[0];
								mouse_strobe <= 1;
							end
						end
					8'h05:
						if (!ARCHIE) begin
							if (kbd_fifo_ok)
								ps2_kbd_tx_strobe <= 1;
							if (abyte_cnt == 1) begin
								key_extended_r <= 0;
								key_pressed_r <= 1;
							end
							if (spi_byte_in == 8'he0)
								key_extended_r <= 1'b1;
							else if (spi_byte_in == 8'hf0)
								key_pressed_r <= 1'b0;
							else begin
								key_extended <= key_extended_r && (abyte_cnt != 1);
								key_pressed <= key_pressed_r || (abyte_cnt == 1);
								key_code <= spi_byte_in;
								key_strobe <= 1'b1;
							end
						end
					8'h1a:
						if (abyte_cnt == 1)
							stick_idx <= spi_byte_in[2:0];
						else if (abyte_cnt == 2) begin
							if (stick_idx == 0)
								joystick_analog_0[15:8] <= spi_byte_in;
							else if (stick_idx == 1)
								joystick_analog_1[15:8] <= spi_byte_in;
						end
						else if (abyte_cnt == 3) begin
							if (stick_idx == 0)
								joystick_analog_0[7:0] <= spi_byte_in;
							else if (stick_idx == 1)
								joystick_analog_1[7:0] <= spi_byte_in;
						end
						else if (abyte_cnt == 4) begin
							if (stick_idx == 0)
								joystick_analog_0[31:24] <= spi_byte_in;
							else if (stick_idx == 1)
								joystick_analog_1[31:24] <= spi_byte_in;
						end
						else if (abyte_cnt == 5) begin
							if (stick_idx == 0)
								joystick_analog_0[23:16] <= spi_byte_in;
							else if (stick_idx == 1)
								joystick_analog_1[23:16] <= spi_byte_in;
						end
					8'h15: status <= spi_byte_in;
					8'h1e:
						if (abyte_cnt < 9)
							status[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h21: core_mod <= spi_byte_in[6:0];
					8'h22:
						if (abyte_cnt < 9)
							rtc[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h30:
						if (abyte_cnt == 1)
							{i2c_addr, i2c_read} <= spi_byte_in;
						else if (abyte_cnt == 2)
							i2c_subaddr <= spi_byte_in;
						else if (abyte_cnt == 3) begin
							i2c_dout <= spi_byte_in;
							i2c_start <= 1;
						end
				endcase
			end
		end
	end
	always @(posedge clk_sd) begin : sd_block
		reg spi_receiver_strobe;
		reg spi_transfer_end;
		reg spi_receiver_strobeD;
		reg spi_transfer_endD;
		reg [SD_IMAGES - 1:0] sd_wrD;
		reg [7:0] acmd;
		reg [7:0] abyte_cnt;
		spi_receiver_strobeD <= spi_receiver_strobe_r;
		spi_receiver_strobe <= spi_receiver_strobeD;
		spi_transfer_endD <= spi_transfer_end_r;
		spi_transfer_end <= spi_transfer_endD;
		if (sd_dout_strobe) begin
			sd_dout_strobe <= 0;
			if (~&sd_buff_addr)
				sd_buff_addr <= sd_buff_addr + 1'b1;
		end
		sd_din_strobe <= 0;
		sd_wrD <= sd_wr;
		if (|(~sd_wrD & sd_wr)) begin
			sd_buff_addr <= 0;
			sd_din_strobe <= 1;
		end
		img_mounted <= 0;
		if (spi_transfer_end) begin
			abyte_cnt <= 8'd0;
			sd_ack <= 1'b0;
			sd_ack_conf <= 1'b0;
			sd_buff_addr <= 0;
			if ((acmd == 8'h17) || (acmd == 8'h18))
				sd_ack_x <= 0;
		end
		else if (spi_receiver_strobeD ^ spi_receiver_strobe) begin
			if (~&abyte_cnt)
				abyte_cnt <= abyte_cnt + 8'd1;
			if (abyte_cnt == 0) begin
				acmd <= spi_byte_in;
				if (spi_byte_in == 8'h18) begin
					sd_din_strobe <= 1'b1;
					if (~&sd_buff_addr)
						sd_buff_addr <= sd_buff_addr + 1'b1;
				end
				if (spi_byte_in == 8'h19)
					sd_ack_conf <= 1'b1;
				if ((spi_byte_in == 8'h17) || (spi_byte_in == 8'h18))
					sd_ack <= 1'b1;
			end
			else
				case (acmd)
					8'h17, 8'h19: begin
						sd_dout_strobe <= 1'b1;
						sd_dout <= spi_byte_in;
					end
					8'h18:
						if (~&sd_buff_addr) begin
							sd_din_strobe <= 1'b1;
							sd_buff_addr <= sd_buff_addr + 1'b1;
						end
					8'h1c: img_mounted[spi_byte_in[W:0]] <= 1;
					8'h1d:
						if (abyte_cnt < 9)
							img_size[(abyte_cnt - 1) << 3+:8] <= spi_byte_in;
					8'h23: sd_ack_x <= 1'b1 << spi_byte_in;
				endcase
		end
	end
endmodule
