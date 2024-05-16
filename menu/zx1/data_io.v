module data_io (
	clk_sys,
	SPI_SCK,
	SPI_SS2,
	SPI_SS4,
	SPI_DI,
	SPI_DO,
	QCSn,
	QSCK,
	QDAT,
	clkref_n,
	ioctl_download,
	ioctl_upload,
	ioctl_index,
	ioctl_wr,
	ioctl_addr,
	ioctl_dout,
	ioctl_din,
	ioctl_fileext,
	ioctl_filesize,
	hdd_clk,
	hdd_cmd_req,
	hdd_cdda_req,
	hdd_dat_req,
	hdd_cdda_wr,
	hdd_status_wr,
	hdd_addr,
	hdd_wr,
	hdd_data_out,
	hdd_data_in,
	hdd_data_rd,
	hdd_data_wr,
	hdd0_ena,
	hdd1_ena
);
	input clk_sys;
	input SPI_SCK;
	input SPI_SS2;
	input SPI_SS4;
	input SPI_DI;
	inout SPI_DO;
	input QCSn;
	input QSCK;
	input [3:0] QDAT;
	input clkref_n;
	output reg ioctl_download = 0;
	output reg ioctl_upload = 0;
	output reg [7:0] ioctl_index;
	output reg ioctl_wr;
	output reg [26:0] ioctl_addr;
	parameter DOUT_16 = 1'b0;
	output reg [((DOUT_16 + 1) * 8) - 1:0] ioctl_dout;
	input [7:0] ioctl_din;
	output reg [23:0] ioctl_fileext;
	output reg [31:0] ioctl_filesize;
	input hdd_clk;
	input hdd_cmd_req;
	input hdd_cdda_req;
	input hdd_dat_req;
	output wire hdd_cdda_wr;
	output wire hdd_status_wr;
	output wire [2:0] hdd_addr;
	output wire hdd_wr;
	output wire [15:0] hdd_data_out;
	input [15:0] hdd_data_in;
	output wire hdd_data_rd;
	output wire hdd_data_wr;
	output wire [1:0] hdd0_ena;
	output wire [1:0] hdd1_ena;
	parameter START_ADDR = 27'd0;
	parameter ROM_DIRECT_UPLOAD = 1'b0;
	parameter USE_QSPI = 1'b0;
	parameter ENABLE_IDE = 1'b0;
	reg [14:0] sbuf;
	reg [15:0] data_w;
	reg [7:0] data_w2 = 0;
	reg [15:0] data_w3 = 0;
	reg [3:0] cnt;
	reg [7:0] cmd;
	reg [6:0] bytecnt;
	reg rclk = 0;
	reg rclk2 = 0;
	reg rclk3 = 0;
	reg addr_reset = 0;
	reg downloading_reg = 0;
	reg uploading_reg = 0;
	reg reg_do;
	localparam DIO_FILE_TX = 8'h53;
	localparam DIO_FILE_TX_DAT = 8'h54;
	localparam DIO_FILE_INDEX = 8'h55;
	localparam DIO_FILE_INFO = 8'h56;
	localparam DIO_FILE_RX = 8'h57;
	localparam DIO_FILE_RX_DAT = 8'h58;
	localparam QSPI_READ = 8'h40;
	localparam QSPI_WRITE = 8'h41;
	localparam CMD_IDE_REGS_RD = 8'h80;
	localparam CMD_IDE_REGS_WR = 8'h90;
	localparam CMD_IDE_DATA_WR = 8'ha0;
	localparam CMD_IDE_DATA_RD = 8'hb0;
	localparam CMD_IDE_CDDA_RD = 8'hc0;
	localparam CMD_IDE_CDDA_WR = 8'hd0;
	localparam CMD_IDE_STATUS_WR = 8'hf0;
	localparam CMD_IDE_CFG_WR = 8'hfa;
	assign SPI_DO = reg_do;
	wire [7:0] cmdcode = {4'h0, hdd_dat_req, hdd_cmd_req, 2'b00};
	always @(negedge SPI_SCK or posedge SPI_SS2) begin : SPI_TRANSMITTER
		reg [7:0] dout_r;
		reg oe;
		if (SPI_SS2) begin
			oe <= 0;
			reg_do <= 1'bz;
		end
		else begin
			if (cnt == 15) begin
				oe <= 1;
				case (cmd)
					CMD_IDE_REGS_RD, CMD_IDE_DATA_RD: dout_r <= (bytecnt[0] ? hdd_data_in[7:0] : hdd_data_in[15:8]);
					CMD_IDE_CDDA_RD: dout_r <= {7'd0, hdd_cdda_req};
					DIO_FILE_RX_DAT: dout_r <= ioctl_din;
					default: oe <= 0;
				endcase
			end
			reg_do <= (!cnt[3] & ENABLE_IDE ? cmdcode[~cnt[2:0]] : (oe ? dout_r[~cnt[2:0]] : 1'bz));
		end
	end
	always @(posedge SPI_SCK or posedge SPI_SS2) begin : SPI_RECEIVER
		if (SPI_SS2) begin
			bytecnt <= 0;
			cnt <= 0;
		end
		else begin
			sbuf <= {sbuf[13:0], SPI_DI};
			if (cnt != 15)
				cnt <= cnt + 1'd1;
			else
				cnt <= 8;
			if (cnt == 7)
				cmd <= {sbuf[6:0], SPI_DI};
			if (cnt == 15) begin
				if (~&bytecnt)
					bytecnt <= bytecnt + 1'd1;
				else
					bytecnt[0] <= ~bytecnt[0];
				case (cmd)
					DIO_FILE_TX:
						if (SPI_DI) begin
							addr_reset <= ~addr_reset;
							downloading_reg <= 1;
						end
						else
							downloading_reg <= 0;
					DIO_FILE_RX:
						if (SPI_DI) begin
							addr_reset <= ~addr_reset;
							uploading_reg <= 1;
						end
						else
							uploading_reg <= 0;
					DIO_FILE_RX_DAT: rclk <= ~rclk;
					DIO_FILE_TX_DAT:
						if (bytecnt[0] | !DOUT_16) begin
							data_w <= {sbuf, SPI_DI};
							rclk <= ~rclk;
						end
					DIO_FILE_INDEX: ioctl_index <= {sbuf[6:0], SPI_DI};
					DIO_FILE_INFO:
						case (bytecnt)
							8'h08: ioctl_fileext[23:16] <= {sbuf[6:0], SPI_DI};
							8'h09: ioctl_fileext[15:8] <= {sbuf[6:0], SPI_DI};
							8'h0a: ioctl_fileext[7:0] <= {sbuf[6:0], SPI_DI};
							8'h1c: ioctl_filesize[7:0] <= {sbuf[6:0], SPI_DI};
							8'h1d: ioctl_filesize[15:8] <= {sbuf[6:0], SPI_DI};
							8'h1e: ioctl_filesize[23:16] <= {sbuf[6:0], SPI_DI};
							8'h1f: ioctl_filesize[31:24] <= {sbuf[6:0], SPI_DI};
						endcase
				endcase
			end
		end
	end
	generate
		if (ROM_DIRECT_UPLOAD || ENABLE_IDE) begin : genblk1
			always @(posedge SPI_SCK or posedge SPI_SS4) begin : SPI_DIRECT_RECEIVER
				reg [6:0] sbuf2;
				reg [2:0] cnt2;
				reg [9:0] bytecnt;
				if (SPI_SS4) begin
					cnt2 <= 0;
					bytecnt <= 0;
				end
				else begin
					if (cnt2 != 7)
						sbuf2 <= {sbuf2[5:0], SPI_DO};
					cnt2 <= cnt2 + 1'd1;
					if (cnt2 == 7) begin
						bytecnt <= bytecnt + 1'd1;
						if (bytecnt == 513)
							bytecnt <= 0;
						if (~bytecnt[9]) begin
							data_w2 <= {sbuf2, SPI_DO};
							rclk2 <= ~rclk2;
						end
					end
				end
			end
		end
		if (USE_QSPI) begin : genblk2
			always @(negedge QSCK or posedge QCSn) begin : QSPI_RECEIVER
				reg [1:0] nibble;
				reg cmd_got;
				reg cmd_write;
				if (QCSn) begin
					cmd_got <= 0;
					cmd_write <= 0;
					nibble <= 0;
				end
				else begin
					nibble <= nibble + 1'd1;
					data_w3 <= {data_w3[11:0], QDAT};
					if (!cmd_got) begin
						if (nibble[0]) begin
							nibble <= 0;
							cmd_got <= 1;
							if ({data_w3[3:0], QDAT} == QSPI_WRITE)
								cmd_write <= 1;
						end
					end
					else if ((DOUT_16 && &nibble) || (!DOUT_16 & nibble[0])) begin
						if (cmd_write)
							rclk3 <= ~rclk3;
					end
				end
			end
		end
	endgenerate
	reg wr_int;
	reg wr_int_direct;
	reg wr_int_qspi;
	reg rd_int;
	wire [15:0] ioctl_dout_next = (wr_int ? data_w : data_w3);
	always @(posedge clk_sys) begin : DATA_OUT
		reg rclkD;
		reg rclkD2;
		reg rclk2D;
		reg rclk2D2;
		reg rclk3D;
		reg rclk3D2;
		reg addr_resetD;
		reg addr_resetD2;
		reg [26:0] addr;
		reg [31:0] filepos;
		reg [7:0] tmp;
		{rclkD, rclkD2} <= {rclk, rclkD};
		{rclk2D, rclk2D2} <= {rclk2, rclk2D};
		{rclk3D, rclk3D2} <= {rclk3, rclk3D};
		{addr_resetD, addr_resetD2} <= {addr_reset, addr_resetD};
		ioctl_wr <= 0;
		if (!downloading_reg) begin
			ioctl_download <= 0;
			wr_int <= 0;
			wr_int_direct <= 0;
		end
		if (!uploading_reg) begin
			ioctl_upload <= 0;
			rd_int <= 0;
		end
		if (~clkref_n) begin
			rd_int <= 0;
			wr_int <= 0;
			wr_int_direct <= 0;
			wr_int_qspi <= 0;
			if (wr_int_direct) begin
				if (DOUT_16) begin
					if (addr[0]) begin
						ioctl_dout <= {data_w2, tmp};
						ioctl_wr <= 1;
						ioctl_addr <= {addr[26:1], 1'b0};
					end
					else
						tmp <= data_w2;
				end
				else begin
					ioctl_dout <= data_w2;
					ioctl_wr <= 1;
					ioctl_addr <= addr;
				end
				addr <= addr + 1'd1;
			end
			if (wr_int | wr_int_qspi) begin
				ioctl_wr <= 1;
				ioctl_addr <= addr;
				if (DOUT_16) begin
					ioctl_dout <= {ioctl_dout_next[7:0], ioctl_dout_next[15:8]};
					addr <= addr + 2'd2;
				end
				else begin
					ioctl_dout <= ioctl_dout_next[7:0];
					addr <= addr + 1'd1;
				end
			end
			if (rd_int)
				ioctl_addr <= ioctl_addr + 1'd1;
		end
		if (addr_resetD ^ addr_resetD2) begin
			addr <= START_ADDR;
			ioctl_addr <= START_ADDR;
			filepos <= 0;
			ioctl_download <= downloading_reg;
			ioctl_upload <= uploading_reg;
		end
		if (rclkD ^ rclkD2) begin
			wr_int <= downloading_reg;
			rd_int <= uploading_reg;
		end
		if (((rclk2D ^ rclk2D2) && (filepos != ioctl_filesize)) && downloading_reg) begin
			filepos <= filepos + 1'd1;
			wr_int_direct <= 1;
		end
		if (rclk3D ^ rclk3D2)
			wr_int_qspi <= downloading_reg;
	end
	generate
		if (ENABLE_IDE) begin : genblk3
			reg [1:0] int_hdd0_ena;
			reg [1:0] int_hdd1_ena;
			reg int_hdd_cdda_wr;
			reg int_hdd_status_wr;
			reg [2:0] int_hdd_addr = 0;
			reg int_hdd_wr;
			reg [15:0] int_hdd_data_out;
			reg int_hdd_data_rd;
			reg int_hdd_data_wr;
			assign hdd0_ena = int_hdd0_ena;
			assign hdd1_ena = int_hdd1_ena;
			assign hdd_cdda_wr = int_hdd_cdda_wr;
			assign hdd_status_wr = int_hdd_status_wr;
			assign hdd_addr = int_hdd_addr;
			assign hdd_wr = int_hdd_wr;
			assign hdd_data_out = int_hdd_data_out;
			assign hdd_data_rd = int_hdd_data_rd;
			assign hdd_data_wr = int_hdd_data_wr;
			reg rst0 = 1;
			reg rst2 = 1;
			reg rclk_ide_stat = 0;
			reg rclk_ide_regs_rd = 0;
			reg rclk_ide_regs_wr = 0;
			reg rclk_ide_wr = 0;
			reg rclk_ide_rd = 0;
			reg rclk_cdda_wr = 0;
			reg [15:0] data_ide;
			always @(posedge SPI_SCK or posedge SPI_SS2) begin : SPI_RECEIVER_IDE
				if (SPI_SS2)
					rst0 <= 1;
				else begin
					rst0 <= 0;
					if (cnt == 15)
						case (cmd)
							CMD_IDE_CFG_WR:
								if (bytecnt == 0) begin
									int_hdd0_ena <= {sbuf[0], SPI_DI};
									int_hdd1_ena <= sbuf[2:1];
								end
							CMD_IDE_STATUS_WR:
								if (bytecnt == 0) begin
									data_ide[7:0] <= {sbuf[6:0], SPI_DI};
									rclk_ide_stat <= ~rclk_ide_stat;
								end
							CMD_IDE_REGS_WR:
								if (((bytecnt >= 8) && (bytecnt <= 18)) && !bytecnt[0]) begin
									data_ide[7:0] <= {sbuf[6:0], SPI_DI};
									rclk_ide_regs_wr <= ~rclk_ide_regs_wr;
								end
							CMD_IDE_REGS_RD:
								if ((bytecnt > 5) && !bytecnt[0])
									rclk_ide_regs_rd <= ~rclk_ide_regs_rd;
							CMD_IDE_DATA_WR:
								if ((bytecnt > 4) & !bytecnt[0]) begin
									data_ide <= {sbuf, SPI_DI};
									rclk_ide_wr <= ~rclk_ide_wr;
								end
							CMD_IDE_CDDA_WR:
								if ((bytecnt > 4) & !bytecnt[0]) begin
									data_ide <= {sbuf, SPI_DI};
									rclk_cdda_wr <= ~rclk_cdda_wr;
								end
							CMD_IDE_DATA_RD:
								if (bytecnt > 3)
									rclk_ide_rd <= ~rclk_ide_rd;
						endcase
				end
			end
			always @(posedge SPI_SCK or posedge SPI_SS4) begin : SPI_DIRECT_RECEIVER_IDE
				if (SPI_SS4)
					rst2 <= 1;
				else
					rst2 <= 0;
			end
			always @(posedge hdd_clk) begin : IDE_OUT
				reg loword;
				reg rclk2D;
				reg rclk2D2;
				reg rclk_ide_statD;
				reg rclk_ide_statD2;
				reg rclk_cdda_wrD;
				reg rclk_cdda_wrD2;
				reg rclk_ide_wrD;
				reg rclk_ide_wrD2;
				reg rclk_ide_rdD;
				reg rclk_ide_rdD2;
				reg rclk_ide_regs_wrD;
				reg rclk_ide_regs_wrD2;
				reg rclk_ide_regs_rdD;
				reg rclk_ide_regs_rdD2;
				reg rst0D;
				reg rst0D2;
				reg rst2D;
				reg rst2D2;
				{rclk2D, rclk2D2} <= {rclk2, rclk2D};
				{rclk_ide_statD, rclk_ide_statD2} <= {rclk_ide_stat, rclk_ide_statD};
				{rclk_ide_rdD, rclk_ide_rdD2} <= {rclk_ide_rd, rclk_ide_rdD};
				{rclk_ide_wrD, rclk_ide_wrD2} <= {rclk_ide_wr, rclk_ide_wrD};
				{rclk_cdda_wrD, rclk_cdda_wrD2} <= {rclk_cdda_wr, rclk_cdda_wrD};
				{rclk_ide_regs_rdD, rclk_ide_regs_rdD2} <= {rclk_ide_regs_rd, rclk_ide_regs_rdD};
				{rclk_ide_regs_wrD, rclk_ide_regs_wrD2} <= {rclk_ide_regs_wr, rclk_ide_regs_wrD};
				{rst0D, rst0D2} <= {rst0, rst0D};
				{rst2D, rst2D2} <= {rst2, rst2D};
				int_hdd_wr <= 0;
				int_hdd_status_wr <= 0;
				int_hdd_data_wr <= 0;
				int_hdd_data_rd <= 0;
				int_hdd_cdda_wr <= 0;
				if (rst0D2)
					int_hdd_addr <= 0;
				if (rst0D2 && rst2D2)
					loword <= 0;
				if (rclk_ide_statD ^ rclk_ide_statD2) begin
					int_hdd_status_wr <= 1;
					int_hdd_data_out <= {8'h00, data_ide[7:0]};
				end
				if (rclk_ide_rdD ^ rclk_ide_rdD2) begin
					loword <= ~loword;
					if (loword)
						int_hdd_data_rd <= 1;
				end
				if (rclk_ide_wrD ^ rclk_ide_wrD2) begin
					int_hdd_data_out <= data_ide;
					int_hdd_data_wr <= 1;
				end
				if (rclk_cdda_wrD ^ rclk_cdda_wrD2) begin
					int_hdd_data_out <= data_ide;
					int_hdd_cdda_wr <= 1;
				end
				if ((rclk2D ^ rclk2D2) && !downloading_reg) begin
					loword <= ~loword;
					if (!loword)
						int_hdd_data_out[15:8] <= data_w2;
					else begin
						int_hdd_data_wr <= 1;
						int_hdd_data_out[7:0] <= data_w2;
					end
				end
				if (rclk_ide_regs_wrD ^ rclk_ide_regs_wrD2) begin
					int_hdd_wr <= 1;
					int_hdd_data_out <= {8'h00, data_ide[7:0]};
					int_hdd_addr <= int_hdd_addr + 1'd1;
				end
				if (rclk_ide_regs_rdD ^ rclk_ide_regs_rdD2)
					int_hdd_addr <= int_hdd_addr + 1'd1;
			end
		end
		else begin : genblk3
			assign hdd0_ena = 0;
			assign hdd1_ena = 0;
			assign hdd_cdda_wr = 0;
			assign hdd_status_wr = 0;
			assign hdd_addr = 0;
			assign hdd_wr = 0;
			assign hdd_data_out = 0;
			assign hdd_data_rd = 0;
			assign hdd_data_wr = 0;
		end
	endgenerate
endmodule
