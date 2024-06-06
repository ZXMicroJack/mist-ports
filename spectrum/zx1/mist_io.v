`default_nettype none
module mist_io (
	conf_str,
	clk_sys,
	SPI_SCK,
	CONF_DATA0,
	SPI_SS2,
	SPI_DO,
	SPI_DI,
	joystick_0,
	joystick_1,
	joystick_analog_0,
	joystick_analog_1,
	buttons,
	switches,
	scandoubler_disable,
	ypbpr,
	status,
	sd_conf,
	sd_sdhc,
	img_mounted,
	img_size,
	sd_lba,
	sd_rd,
	sd_wr,
	sd_ack,
	sd_ack_conf,
	sd_buff_addr,
	sd_buff_dout,
	sd_buff_din,
	sd_buff_wr,
	ps2_kbd_clk,
	ps2_kbd_data,
	ps2_mouse_clk,
	ps2_mouse_data,
	ps2_key,
	ps2_mouse,
	ioctl_ce,
	ioctl_download,
	ioctl_index,
	ioctl_wr,
	ioctl_addr,
	ioctl_dout
);
	parameter STRLEN = 0;
	parameter PS2DIV = 100;
	input [(8 * STRLEN) - 1:0] conf_str;
	input clk_sys;
	input SPI_SCK;
	input CONF_DATA0;
	input SPI_SS2;
	output wire SPI_DO;
	input SPI_DI;
	output reg [7:0] joystick_0;
	output reg [7:0] joystick_1;
	output reg [15:0] joystick_analog_0;
	output reg [15:0] joystick_analog_1;
	output wire [1:0] buttons;
	output wire [1:0] switches;
	output wire scandoubler_disable;
	output wire ypbpr;
	output reg [31:0] status;
	input sd_conf;
	input sd_sdhc;
	output wire [1:0] img_mounted;
	output reg [31:0] img_size;
	input [31:0] sd_lba;
	input [1:0] sd_rd;
	input [1:0] sd_wr;
	output reg sd_ack;
	output reg sd_ack_conf;
	output reg [8:0] sd_buff_addr;
	output reg [7:0] sd_buff_dout;
	input [7:0] sd_buff_din;
	output reg sd_buff_wr;
	output wire ps2_kbd_clk;
	output reg ps2_kbd_data;
	output wire ps2_mouse_clk;
	output reg ps2_mouse_data;
	output reg [10:0] ps2_key = 0;
	output reg [24:0] ps2_mouse = 0;
	input ioctl_ce;
	output reg ioctl_download = 0;
	output reg [7:0] ioctl_index;
	output reg ioctl_wr = 0;
	output reg [24:0] ioctl_addr;
	output reg [7:0] ioctl_dout;
	reg [7:0] but_sw;
	reg [2:0] stick_idx;
	reg [1:0] mount_strobe = 0;
	assign img_mounted = mount_strobe;
	assign buttons = but_sw[1:0];
	assign switches = but_sw[3:2];
	assign scandoubler_disable = but_sw[4];
	assign ypbpr = but_sw[5];
	wire [7:0] core_type = 8'ha4;
	wire drive_sel = sd_rd[1] | sd_wr[1];
	wire [7:0] sd_cmd = {4'h6, sd_conf, sd_sdhc, sd_wr[drive_sel], sd_rd[drive_sel]};
	reg [7:0] cmd;
	reg [2:0] bit_cnt;
	reg [9:0] byte_cnt;
	reg spi_do;
	assign SPI_DO = (CONF_DATA0 ? 1'bz : spi_do);
	reg [7:0] spi_data_out;
	always @(negedge SPI_SCK) spi_do <= spi_data_out[~bit_cnt];
	reg [7:0] spi_data_in;
	reg spi_data_ready = 0;
	always @(posedge SPI_SCK or posedge CONF_DATA0) begin : sv2v_autoblock_1
		reg [6:0] sbuf;
		reg [31:0] sd_lba_r;
		reg drive_sel_r;
		if (CONF_DATA0) begin
			bit_cnt <= 0;
			byte_cnt <= 0;
			spi_data_out <= core_type;
		end
		else begin
			bit_cnt <= bit_cnt + 1'd1;
			sbuf <= {sbuf[5:0], SPI_DI};
			if (bit_cnt == 7) begin
				if (!byte_cnt)
					cmd <= {sbuf, SPI_DI};
				spi_data_in <= {sbuf, SPI_DI};
				spi_data_ready <= ~spi_data_ready;
				if (~&byte_cnt)
					byte_cnt <= byte_cnt + 8'd1;
				spi_data_out <= 0;
				case ({(!byte_cnt ? {sbuf, SPI_DI} : cmd)})
					8'h14:
						if (byte_cnt < STRLEN)
							spi_data_out <= conf_str[((STRLEN - byte_cnt) - 1) << 3+:8];
					8'h16:
						if (byte_cnt == 0) begin
							spi_data_out <= sd_cmd;
							sd_lba_r <= sd_lba;
							drive_sel_r <= drive_sel;
						end
						else if (byte_cnt == 1)
							spi_data_out <= drive_sel_r;
						else if (byte_cnt < 6)
							spi_data_out <= sd_lba_r[(5 - byte_cnt) << 3+:8];
					8'h18: spi_data_out <= sd_buff_din;
				endcase
			end
		end
	end
	reg [31:0] ps2_key_raw = 0;
	wire pressed = ps2_key_raw[15:8] != 8'hf0;
	wire extended = (~pressed ? ps2_key_raw[23:16] == 8'he0 : ps2_key_raw[15:8] == 8'he0);
	localparam PS2_FIFO_BITS = 3;
	reg [7:0] ps2_kbd_fifo [0:7];
	reg [2:0] ps2_kbd_wptr;
	reg [7:0] ps2_mouse_fifo [0:7];
	reg [2:0] ps2_mouse_wptr;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg old_ss1;
		reg old_ss2;
		reg old_ready1;
		reg old_ready2;
		reg [2:0] b_wr;
		reg got_ps2 = 0;
		old_ss1 <= CONF_DATA0;
		old_ss2 <= old_ss1;
		old_ready1 <= spi_data_ready;
		old_ready2 <= old_ready1;
		sd_buff_wr <= b_wr[0];
		if (b_wr[2] && ~&sd_buff_addr)
			sd_buff_addr <= sd_buff_addr + 1'b1;
		b_wr <= b_wr << 1;
		if (old_ss2) begin
			got_ps2 <= 0;
			sd_ack <= 0;
			sd_ack_conf <= 0;
			sd_buff_addr <= 0;
			if (got_ps2) begin
				if (cmd == 4)
					ps2_mouse[24] <= ~ps2_mouse[24];
				if (cmd == 5) begin
					ps2_key <= {~ps2_key[10], pressed, extended, ps2_key_raw[7:0]};
					if (ps2_key_raw == 'he012e07c)
						ps2_key[9:0] <= 'h37c;
					if (ps2_key_raw == 'h7ce0f012)
						ps2_key[9:0] <= 'h17c;
					if (ps2_key_raw == 'hf014f077)
						ps2_key[9:0] <= 'h377;
				end
			end
		end
		else if (old_ready2 ^ old_ready1) begin
			if ((cmd == 8'h18) && ~&sd_buff_addr)
				sd_buff_addr <= sd_buff_addr + 1'b1;
			if (byte_cnt < 2) begin
				if (cmd == 8'h19)
					sd_ack_conf <= 1;
				if ((cmd == 8'h17) || (cmd == 8'h18))
					sd_ack <= 1;
				mount_strobe <= 0;
				if (cmd == 5)
					ps2_key_raw <= 0;
			end
			else
				case (cmd)
					8'h01: but_sw <= spi_data_in;
					8'h02: joystick_0 <= spi_data_in;
					8'h03: joystick_1 <= spi_data_in;
					8'h04: begin
						got_ps2 <= 1;
						case (byte_cnt)
							2: ps2_mouse[7:0] <= spi_data_in;
							3: ps2_mouse[15:8] <= spi_data_in;
							4: ps2_mouse[23:16] <= spi_data_in;
						endcase
						ps2_mouse_fifo[ps2_mouse_wptr] <= spi_data_in;
						ps2_mouse_wptr <= ps2_mouse_wptr + 1'd1;
					end
					8'h05: begin
						got_ps2 <= 1;
						ps2_key_raw[31:0] <= {ps2_key_raw[23:0], spi_data_in};
						ps2_kbd_fifo[ps2_kbd_wptr] <= spi_data_in;
						ps2_kbd_wptr <= ps2_kbd_wptr + 1'd1;
					end
					8'h15: status[7:0] <= spi_data_in;
					8'h19, 8'h17: begin
						sd_buff_dout <= spi_data_in;
						b_wr <= 1;
					end
					8'h1a:
						if (byte_cnt == 2)
							stick_idx <= spi_data_in[2:0];
						else if (byte_cnt == 3) begin
							if (stick_idx == 0)
								joystick_analog_0[15:8] <= spi_data_in;
							else if (stick_idx == 1)
								joystick_analog_1[15:8] <= spi_data_in;
						end
						else if (byte_cnt == 4) begin
							if (stick_idx == 0)
								joystick_analog_0[7:0] <= spi_data_in;
							else if (stick_idx == 1)
								joystick_analog_1[7:0] <= spi_data_in;
						end
					8'h1c: mount_strobe[spi_data_in[0]] <= 1;
					8'h1d:
						if (byte_cnt < 6)
							img_size[(byte_cnt - 2) << 3+:8] <= spi_data_in;
					8'h1e:
						if (byte_cnt < 6)
							status[(byte_cnt - 2) << 3+:8] <= spi_data_in;
					default:
						;
				endcase
		end
	end
	reg clk_ps2;
	always @(negedge clk_sys) begin : sv2v_autoblock_3
		integer cnt;
		cnt <= cnt + 1'd1;
		if (cnt == PS2DIV) begin
			clk_ps2 <= ~clk_ps2;
			cnt <= 0;
		end
	end
	reg [2:0] ps2_kbd_rptr;
	reg [3:0] ps2_kbd_tx_state;
	reg [7:0] ps2_kbd_tx_byte;
	reg ps2_kbd_parity;
	assign ps2_kbd_clk = clk_ps2 || (ps2_kbd_tx_state == 0);
	reg ps2_kbd_r_inc;
	always @(posedge clk_sys) begin : sv2v_autoblock_4
		reg old_clk;
		old_clk <= clk_ps2;
		if (~old_clk & clk_ps2) begin
			ps2_kbd_r_inc <= 0;
			if (ps2_kbd_r_inc)
				ps2_kbd_rptr <= ps2_kbd_rptr + 1'd1;
			if (ps2_kbd_tx_state == 0) begin
				if (ps2_kbd_wptr != ps2_kbd_rptr) begin
					ps2_kbd_tx_byte <= ps2_kbd_fifo[ps2_kbd_rptr];
					ps2_kbd_r_inc <= 1;
					ps2_kbd_parity <= 1;
					ps2_kbd_tx_state <= 1;
					ps2_kbd_data <= 0;
				end
			end
			else begin
				if ((ps2_kbd_tx_state >= 1) && (ps2_kbd_tx_state < 9)) begin
					ps2_kbd_data <= ps2_kbd_tx_byte[0];
					ps2_kbd_tx_byte[6:0] <= ps2_kbd_tx_byte[7:1];
					if (ps2_kbd_tx_byte[0])
						ps2_kbd_parity <= !ps2_kbd_parity;
				end
				if (ps2_kbd_tx_state == 9)
					ps2_kbd_data <= ps2_kbd_parity;
				if (ps2_kbd_tx_state == 10)
					ps2_kbd_data <= 1;
				if (ps2_kbd_tx_state < 11)
					ps2_kbd_tx_state <= ps2_kbd_tx_state + 1'd1;
				else
					ps2_kbd_tx_state <= 0;
			end
		end
	end
	reg [2:0] ps2_mouse_rptr;
	reg [3:0] ps2_mouse_tx_state;
	reg [7:0] ps2_mouse_tx_byte;
	reg ps2_mouse_parity;
	assign ps2_mouse_clk = clk_ps2 || (ps2_mouse_tx_state == 0);
	reg ps2_mouse_r_inc;
	always @(posedge clk_sys) begin : sv2v_autoblock_5
		reg old_clk;
		old_clk <= clk_ps2;
		if (~old_clk & clk_ps2) begin
			ps2_mouse_r_inc <= 0;
			if (ps2_mouse_r_inc)
				ps2_mouse_rptr <= ps2_mouse_rptr + 1'd1;
			if (ps2_mouse_tx_state == 0) begin
				if (ps2_mouse_wptr != ps2_mouse_rptr) begin
					ps2_mouse_tx_byte <= ps2_mouse_fifo[ps2_mouse_rptr];
					ps2_mouse_r_inc <= 1;
					ps2_mouse_parity <= 1;
					ps2_mouse_tx_state <= 1;
					ps2_mouse_data <= 0;
				end
			end
			else begin
				if ((ps2_mouse_tx_state >= 1) && (ps2_mouse_tx_state < 9)) begin
					ps2_mouse_data <= ps2_mouse_tx_byte[0];
					ps2_mouse_tx_byte[6:0] <= ps2_mouse_tx_byte[7:1];
					if (ps2_mouse_tx_byte[0])
						ps2_mouse_parity <= !ps2_mouse_parity;
				end
				if (ps2_mouse_tx_state == 9)
					ps2_mouse_data <= ps2_mouse_parity;
				if (ps2_mouse_tx_state == 10)
					ps2_mouse_data <= 1;
				if (ps2_mouse_tx_state < 11)
					ps2_mouse_tx_state <= ps2_mouse_tx_state + 1'd1;
				else
					ps2_mouse_tx_state <= 0;
			end
		end
	end
	reg [7:0] data_w;
	reg [24:0] addr_w;
	reg rclk = 0;
	localparam UIO_FILE_TX = 8'h53;
	localparam UIO_FILE_TX_DAT = 8'h54;
	localparam UIO_FILE_INDEX = 8'h55;
	reg rdownload = 0;
	always @(posedge SPI_SCK or posedge SPI_SS2) begin : sv2v_autoblock_6
		reg [6:0] sbuf;
		reg [7:0] cmd;
		reg [4:0] cnt;
		reg [24:0] addr;
		if (SPI_SS2)
			cnt <= 0;
		else begin
			if (cnt != 15)
				sbuf <= {sbuf[5:0], SPI_DI};
			if (cnt < 15)
				cnt <= cnt + 1'd1;
			else
				cnt <= 8;
			if (cnt == 7)
				cmd <= {sbuf, SPI_DI};
			if ((cmd == UIO_FILE_TX) && (cnt == 15)) begin
				if (SPI_DI) begin
					addr <= 0;
					rdownload <= 1;
				end
				else begin
					addr_w <= addr;
					rdownload <= 0;
				end
			end
			if ((cmd == UIO_FILE_TX_DAT) && (cnt == 15)) begin
				addr_w <= addr;
				data_w <= {sbuf, SPI_DI};
				addr <= addr + 1'd1;
				rclk <= ~rclk;
			end
			if ((cmd == UIO_FILE_INDEX) && (cnt == 15))
				ioctl_index <= {sbuf, SPI_DI};
		end
	end
	always @(posedge clk_sys) begin : sv2v_autoblock_7
		reg rclkD;
		reg rclkD2;
		if (ioctl_ce) begin
			ioctl_download <= rdownload;
			rclkD <= rclk;
			rclkD2 <= rclkD;
			ioctl_wr <= 0;
			if (rclkD != rclkD2) begin
				ioctl_dout <= data_w;
				ioctl_addr <= addr_w;
				ioctl_wr <= 1;
			end
		end
	end
endmodule
