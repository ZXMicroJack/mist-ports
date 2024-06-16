`default_nettype none
module zxspectrum (
	CLOCK_50,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_HS,
	VGA_VS,
	LED,
	AUDIO_L,
	AUDIO_R,
	EAR,
	SPI_SCK,
	SPI_DO,
	SPI_DI,
	SPI_SS2,
	SPI_SS3,
	SPI_SS4,
	CONF_DATA0,
	SRAM_ADDR,
	SRAM_DQ,
	SRAM_WE_N,

	SD_cs,
	SD_datain,
	SD_dataout,
	SD_clk,
	SD_cs1,
	SD_datain1,
	SD_dataout1,
	SD_clk1,
	PS2C,
	PS2D,
	PS2COUT,
	PS2DOUT,
	JUP,
	JDN,
	JLT,
	JRT,
	JF1,
	JSEL
);
	output wire SD_cs;
	output wire SD_datain;
	output wire SD_clk;
	input wire SD_dataout;
	input wire SD_cs1;
	input wire SD_datain1;
	input wire SD_clk1;
	output wire SD_dataout1;
	//reg _sv2v_0;
	input CLOCK_50;
	output wire [2:0] VGA_R;
	output wire [2:0] VGA_G;
	output wire [2:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire LED;
	output wire AUDIO_L;
	output wire AUDIO_R;
	//output wire UART_TX;
	input wire EAR;
	input wire SPI_SS4;
	//input UART_RX;
	input wire SPI_SCK;
	output wire SPI_DO;
	input wire SPI_DI;
	input wire SPI_SS2;
	input wire SPI_SS3;
	input wire CONF_DATA0;
	output wire [18:0] SRAM_ADDR;
	inout [7:0] SRAM_DQ;
	output wire SRAM_WE_N;
	input wire JUP;
	input wire JDN;
	input wire JLT;
	input wire JRT;
	input wire JF1;
	output wire JSEL;
	//output wire [12:0] SDRAM_A;
	//inout [15:0] SDRAM_DQ;
	//output wire SDRAM_DQML;
	//output wire SDRAM_DQMH;
	//output wire SDRAM_nWE;
	//output wire SDRAM_nCAS;
	//output wire SDRAM_nRAS;
	//output wire SDRAM_nCS;
	//output wire [1:0] SDRAM_BA;
	//output wire SDRAM_CLK;
	//output wire SDRAM_CKE;
	//output wire [15:0] AUDIO_LEFT;
	//output wire [15:0] AUDIO_RIGHT;

		input wire PS2C;
	input wire PS2D;
	output wire PS2COUT;
	output wire PS2DOUT;

	assign PS2COUT = PS2C;
	assign PS2DOUT = PS2D;

	assign SD_cs = SD_cs1;
	assign SD_datain = SD_datain1;
	assign SD_clk = SD_clk1;
	assign SD_dataout1 = SD_dataout;

	assign JSEL = 1'b1;

	wire [5:0] VGA_R_x;
	wire [5:0] VGA_G_x;
	wire [5:0] VGA_B_x;

	assign VGA_R[2:0] = VGA_R_x[5:3];
	assign VGA_G[2:0] = VGA_G_x[5:3];
	assign VGA_B[2:0] = VGA_B_x[5:3];

	//output wire clock50;
	wire ioctl_download;
	wire tape_led;
	assign LED = ~(ioctl_download | tape_led);
	localparam CONF_BDI = "(BDI)";
	localparam CONF_PLUSD = "(+D) ";
	localparam ROM_ADDR = 25'h0040000;
	//localparam ROM_ADDR = 25'h0150000;
	localparam TAPE_ADDR = 25'h0400000;
	localparam SNAP_ADDR = 25'h0600000;
	localparam ARCH_ZX48 = 5'b01100;
	localparam ARCH_ZX128 = 5'b00001;
	localparam ARCH_ZX3 = 5'b10001;
	localparam ARCH_P48 = 5'b01110;
	localparam ARCH_P128 = 5'b00010;
	localparam ARCH_P1024 = 5'b00110;
	localparam CONF_STR = {"SPECTRUM;;", "S1U,TRDIMGDSKMGT,Load Disk;", "F,TAPCSWTZX,Load Tape;", "F,Z80SNA,Load Snapshot;", "OMO,CPU frequency,3.5 MHz,7 MHz,14 MHz,28 MHz,56 MHz;", "O89,Video timings,ULA-48,ULA-128,Pentagon;", "OAC,Memory,Standard 128K,Pentagon 1024K,Profi 1024K,Standard 48K,+2A/+3;", "O12,Joystick 1,Sinclair I,Sinclair II,Kempston,Cursor;", "O34,Joystick 2,Sinclair I,Sinclair II,Kempston,Cursor;", "O6,Fast tape load,On,Off;", "OFG,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;", "ODE,Features,ULA+ & Timex,ULA+,Timex,None;", "OHI,MMC Card,Off,divMMC,ZXMMC,divMMC+ESXDOS;", "OKL,General Sound,512KB,1MB,2MB,Disabled;", "O5,Keyboard,Issue 3,Issue 2;", "O7,Snowing,Enabled,Unrained;", "T0,Reset;", "V,v3.40.", "231230"};
	wire [31:0] status;
	wire [2:0] st_cpu_freq = status[24:22];
	wire [1:0] st_ula_type = status[9:8];
	wire [2:0] st_memory_mode = status[12:10];
	wire st_fast_tape = status[6];
	wire [1:0] st_joy1 = status[2:1];
	wire [1:0] st_joy2 = status[4:3];
	wire [1:0] st_scanlines = status[16:15];
	wire [1:0] st_mmc = status[18:17];
	wire [1:0] st_gs_memory = status[21:20];
	wire issue2 = status[5];
	wire unrainer = status[7];
	wire clk_sys;
	wire locked;
	//wire SDRAM_CLK; // NOT USED
	//wire clock50; // NOT USED
	pll pll(
		.inclk0(CLOCK_50),
		.c0(clk_sys),
		//.c1(SDRAM_CLK),
		//.c2(clock50),
		.locked(locked)
	);
	reg ce_psg;
	reg ce_7mp;
	reg ce_7mn;
	reg ce_14m;
	reg pause;
	reg cpu_en = 1;
	reg ce_cpu_tp;
	reg ce_cpu_tn;
	reg [4:0] turbo = 5'b11111;
	wire cpu_p = (~&turbo ? ce_cpu_tp : ce_cpu_sp);
	wire ce_cpu_p = cpu_en & cpu_p;
	wire cpu_n = (~&turbo ? ce_cpu_tn : ce_cpu_sn);
	wire ce_cpu_n = cpu_en & cpu_n;
	wire ce_cpu = cpu_en & ce_cpu_tp;
	wire ce_wd1793 = ce_cpu;
	wire ce_u765 = ce_cpu;
	wire ce_tape = ce_cpu;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg [5:0] counter;
		//counter = 0;
		counter <= counter + 1;
		ce_14m <= !counter[2:0];
		ce_7mp <= !counter[3] & !counter[2:0];
		ce_7mn <= counter[3] & !counter[2:0];
		ce_psg <= !counter[5:0] & ~pause;
		ce_cpu_tp <= !(counter & turbo);
		ce_cpu_tn <= !(((counter & turbo) ^ turbo) ^ turbo[4:1]);
	end
	reg [4:0] turbo_conf = 5'b11111;
	reg [4:0] turbo_key = 5'b11111;
	reg turbo_key_active;
	wire [11:1] Fn;
	wire [2:0] mod;
	reg reset = 1'b0;
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg old_Fn9;
		old_Fn9 <= Fn[9];
		if (reset)
			pause <= 0;
		else if (!mod && (~old_Fn9 & Fn[9]))
			pause <= ~pause;
		turbo_key_active <= |Fn[8:4] && !mod;
		if (Fn[4])
			turbo_key <= 5'b11111;
		if (Fn[5])
			turbo_key <= 5'b01111;
		if (Fn[6])
			turbo_key <= 5'b00111;
		if (Fn[7])
			turbo_key <= 5'b00011;
		if (Fn[8])
			turbo_key <= 5'b00001;
		case (st_cpu_freq)
			3'd0: turbo_conf <= 5'b11111;
			3'd1: turbo_conf <= 5'b01111;
			3'd2: turbo_conf <= 5'b00111;
			3'd3: turbo_conf <= 5'b00011;
			3'd4: turbo_conf <= 5'b00001;
			default: turbo_conf <= 5'b11111;
		endcase
	end
	wire tape_active;
	wire [4:0] turbo_req = (tape_active & ~st_fast_tape ? 5'b00001 : (turbo_key_active ? turbo_key : turbo_conf));
	wire ram_ready;
	//assign cpu_en = ~pause;
	//always @(posedge clk_sys) begin : sv2v_autoblock_3
		//reg [1:0] timeout;
		//if (cpu_n) begin
			//if (timeout)
				//timeout <= timeout + 1'd1;
			//if (turbo != turbo_req) begin
				//cpu_en <= 0;
				//timeout <= 1;
				//turbo <= turbo_req;
			//end
			//else if ((!cpu_en & !timeout) & ram_ready)
				//cpu_en <= ~pause;
			//else if (!turbo[4:3] & !ram_ready)
				//cpu_en <= 0;
			//else if (cpu_en & pause)
				//cpu_en <= 0;
		//end
	//end
	wire [10:0] ps2_key;
	wire [24:0] ps2_mouse;
	wire [7:0] joystick_0;
	wire [7:0] joystick_1;
	wire [1:0] buttons;
	wire [1:0] switches;
	wire scandoubler_disable;
	wire ypbpr;
	wire sd_rd_plus3;
	wire sd_wr_plus3;
	wire [31:0] sd_lba_plus3;
	wire [7:0] sd_buff_din_plus3;
	wire sd_rd_wd;
	wire sd_wr_wd;
	wire [31:0] sd_lba_wd;
	wire [7:0] sd_buff_din_wd;
	wire sd_busy_mmc;
	wire sd_rd_mmc;
	wire sd_wr_mmc;
	wire [31:0] sd_lba_mmc;
	wire [7:0] sd_buff_din_mmc;
	reg plus3_fdd_ready;
	wire [31:0] sd_lba = (sd_busy_mmc ? sd_lba_mmc : (plus3_fdd_ready ? sd_lba_plus3 : sd_lba_wd));
	wire [1:0] sd_rd = {sd_rd_plus3 | sd_rd_wd, sd_rd_mmc};
	wire [1:0] sd_wr = {sd_wr_plus3 | sd_wr_wd, sd_wr_mmc};
	wire sd_ack;
	wire [8:0] sd_buff_addr;
	wire [7:0] sd_buff_dout;
	wire [7:0] sd_buff_din = (sd_busy_mmc ? sd_buff_din_mmc : (plus3_fdd_ready ? sd_buff_din_plus3 : sd_buff_din_wd));
	wire sd_buff_wr;
	wire [1:0] img_mounted;
	wire [31:0] img_size;
	wire sd_ack_conf;
	wire sd_conf;
	wire sd_sdhc;
	wire ioctl_wr;
	wire [24:0] ioctl_addr;
	wire [7:0] ioctl_dout;
	wire [5:0] ioctl_index;
	wire [1:0] ioctl_ext_index;
	reg plusd_mounted;
	wire plusd_en = plusd_mounted & ~plus3;
	mist_io #(.STRLEN(638)) mist_io(
		.clk_sys(clk_sys),
		.SPI_SCK(SPI_SCK),
		.CONF_DATA0(CONF_DATA0),
		.SPI_SS2(SPI_SS2),
		.SPI_DO(SPI_DO),
		.SPI_DI(SPI_DI),
		.joystick_0(joystick_0),
		.joystick_1(joystick_1),
		.buttons(buttons),
		.switches(switches),
		.scandoubler_disable(scandoubler_disable),
		.ypbpr(ypbpr),
		.status(status),
		.sd_conf(sd_conf),
		.sd_sdhc(sd_sdhc),
		.img_mounted(img_mounted),
		.img_size(img_size),
		.sd_lba(sd_lba),
		.sd_rd(sd_rd),
		.sd_wr(sd_wr),
		.sd_ack(sd_ack),
		.sd_ack_conf(sd_ack_conf),
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din(sd_buff_din),
		.sd_buff_wr(sd_buff_wr),
		.ps2_key(ps2_key),
		.ps2_mouse(ps2_mouse),
		.ioctl_download(ioctl_download),
		.ioctl_wr(ioctl_wr),
		.ioctl_addr(ioctl_addr),
		.ioctl_dout(ioctl_dout),
		.ioctl_ce(1),
		.ioctl_index({ioctl_ext_index, ioctl_index}),
		.conf_str({CONF_STR, (plusd_en ? CONF_PLUSD : CONF_BDI)}),
		.ps2_kbd_clk(),
		.ps2_kbd_data(),
		.ps2_mouse_clk(),
		.ps2_mouse_data(),
		.joystick_analog_0(),
		.joystick_analog_1()
	);
	wire [15:0] addr;
	reg [7:0] cpu_din;
	wire [7:0] cpu_dout;
	wire nM1;
	wire nMREQ;
	wire nIORQ;
	wire nRD;
	wire nWR;
	wire nRFSH;
	wire nBUSACK;
	wire nINT;
	wire nBUSRQ = ~ioctl_download;
	wire io_wr = (~nIORQ & ~nWR) & nM1;
	wire io_rd = (~nIORQ & ~nRD) & nM1;
	wire m1 = ~nM1 & ~nMREQ;
	reg old_wr;
	reg old_rd;
	reg old_m1;
	wire [211:0] cpu_reg;
	wire [15:0] reg_DE = cpu_reg[111:96];
	wire [7:0] reg_A = cpu_reg[7:0];
	reg NMI;
	wire [211:0] snap_REG;
	wire snap_REGSet;
	T80pa cpu(
		.RESET_n(~reset),
		.CLK(clk_sys),
		.CEN_p(ce_cpu_p),
		.CEN_n(ce_cpu_n),
		.WAIT_n(1'b1),
		.INT_n(nINT),
		.NMI_n(~NMI),
		.BUSRQ_n(nBUSRQ),
		.M1_n(nM1),
		.MREQ_n(nMREQ),
		.IORQ_n(nIORQ),
		.RD_n(nRD),
		.WR_n(nWR),
		.RFSH_n(nRFSH),
		.HALT_n(),
		.BUSAK_n(nBUSACK),
		.A(addr),
		.DO(cpu_dout),
		.DI(cpu_din),
		.REG(cpu_reg),
		.DIR(snap_REG),
		.DIRSet(snap_REGSet)
	);
	reg [7:0] page_reg;
	reg [7:0] page_reg_p1024;
	wire page_disable = (zx48 | (~p1024 & page_reg[5])) | ((p1024 & page_reg_p1024[2]) & page_reg[5]);
	wire plus3_fdd = ((((~addr[1] & addr[13]) & ~addr[14]) & ~addr[15]) & plus3) & ~page_disable;
	wire [7:0] u765_dout;
	wire fdd_drq;
	wire fdd_intrq;
	wire [7:0] wd_dout;
	wire [7:0] wdc_dout = (addr[7] & ~plusd_en ? {fdd_intrq, fdd_drq, 6'h3f} : wd_dout);
	wire [7:0] fdd_dout = (plus3_fdd ? u765_dout : wdc_dout);
	reg trdos_en;
	wire fdd_sel = (trdos_en & addr[2]) & addr[1];
	reg plusd_mem;
	wire plusd_stealth = 1;
	wire plusd_ena = (plusd_stealth ? plusd_mem : plusd_en);
	wire fdd_sel2 = ((plusd_ena & (&addr[7:5])) & ~addr[2]) & (&addr[1:0]);
	//wire [7:0] gs_dout;
	//wire gs_sel = ((addr[7:0] | 'b1000) == 'b10111011) & ~&st_gs_memory;
	wire gs_sel = 1'b0;
	reg [4:0] joy_cursor;
	reg [4:0] joy_sinclair1;
	reg [4:0] joy_sinclair2;
	wire [4:0] joy_kbd = ({5 {addr[12]}} | ~({joy_sinclair1[1:0], joy_sinclair1[2], joy_sinclair1[3], joy_sinclair1[4]} | {joy_cursor[2], joy_cursor[3], joy_cursor[0], 1'b0, joy_cursor[4]})) & ({5 {addr[11]}} | ~({joy_sinclair2[4:2], joy_sinclair2[0], joy_sinclair2[1]} | {joy_cursor[1], 4'b0000}));
	reg [5:0] joy_kempston;
	wire [4:0] key_data;
	reg mf128_en;
	wire mf128_port = ((~addr[6] & addr[5]) & addr[4]) & addr[1];
	wire mf3_port = (((mf128_port & ~addr[7]) & (addr[12:8] == 'h1f)) & plus3) & mf128_en;
	wire [7:0] mmc_dout;
	wire mmc_sel;
	wire [7:0] mouse_data;
	reg mouse_sel;
	reg [7:0] page_reg_plus3;
	reg page_scr_copy;
	reg mf128_mem;
	wire portBF = (mf128_port & addr[7]) & (mf128_mem | plusd_mem);
	wire [7:0] port_ff;
	wire psg_enable = (addr[0] & addr[15]) & ~addr[1];
	wire [7:0] ram_dout;
	wire [7:0] sound_data;
	wire [7:0] tape_dout;
	wire tape_dout_en;
	wire ula_tape_in;
	wire [7:0] ulap_dout;
	wire ulap_sel;
	always @(*) begin
		//if (_sv2v_0)
			;
		casex ({nMREQ, tape_dout_en, (~nM1 | nIORQ) | nRD, (fdd_sel | fdd_sel2) | plus3_fdd, mf3_port, mmc_sel, addr[5:0] == 6'h1f, portBF, gs_sel, psg_enable, ulap_sel, addr[0]})
			'b1xxxxxxxxxx: cpu_din = tape_dout;
			'b00xxxxxxxxxx: cpu_din = ram_dout;
			'b1x01xxxxxxxx: cpu_din = fdd_dout;
			'b1x001xxxxxxx: cpu_din = (addr[14:13] == 2'b11 ? page_reg : page_reg_plus3);
			'b1x0001xxxxxx: cpu_din = mmc_dout;
			'b1x00001xxxxx: cpu_din = (mouse_sel ? mouse_data : {2'b00, joy_kempston});
			'b1x000001xxxx: cpu_din = {page_scr_copy, 7'b1111111};
			//'b1x0000001xxx: cpu_din = gs_dout;
			'b1x00000001xx: cpu_din = (addr[14] ? sound_data : 8'hff);
			'b1x000000001x: cpu_din = ulap_dout;
			'b1x0000000000: cpu_din = {1'b1, ula_tape_in, 1'b1, key_data[4:0] & joy_kbd};
			default: cpu_din = port_ff;
		endcase
	end
	reg init_reset = 1;
	reg old_download;
	always @(posedge clk_sys) begin
		old_download <= ioctl_download;
		if (old_download & ~ioctl_download)
			init_reset <= 0;
	end
	reg NMI_old;
	reg NMI_pending;
	reg cold_reset_btn;
	reg warm_reset_btn;
	reg auto_reset_btn;
	wire cold_reset = cold_reset_btn | init_reset;
	wire warm_reset = warm_reset_btn;
	wire auto_reset = auto_reset_btn;
	wire snap_reset;
	always @(posedge clk_sys) begin : sv2v_autoblock_4
		reg old_F10;
		old_F10 <= Fn[10];
		reset <= ((((buttons[1] | status[0]) | cold_reset) | warm_reset) | snap_reset) | auto_reset;
		if (reset | ~Fn[10])
			NMI <= 0;
		else if ((~old_F10 & Fn[10]) & (mod[2:1] == 0))
			NMI <= 1;
		warm_reset_btn <= (mod[2:1] == 0) & Fn[11];
		cold_reset_btn <= (mod[2:1] == 1) & Fn[11];
		auto_reset_btn <= (mod[2:1] == 2) & Fn[11];
	end
	always @(posedge clk_sys) begin
		old_rd <= io_rd;
		old_wr <= io_wr;
		old_m1 <= m1;
		NMI_old <= NMI;
	end
	always @(posedge clk_sys)
		if (reset)
			NMI_pending <= 0;
		else if (~NMI_old & NMI)
			NMI_pending <= 1;
		else if ((~m1 && old_m1) && (addr == 'h66))
			NMI_pending <= 0;
	wire dma = (reset | ~nBUSACK) & ~nBUSRQ;
	reg [23:0] ram_addr;
	reg [7:0] ram_din;
	reg ram_we;
	reg ram_rd;
	wire [3:0] mmc_ram_bank;
	wire mmc_ram_en;
	reg [2:0] page_128k;
	wire [5:0] page_ram = {page_128k, page_reg[2:0]};
	reg [3:0] page_rom;
	wire page_special = page_reg_plus3[0];
	wire [24:0] snap_addr;
	wire [7:0] snap_data;
	reg snap_dl = 0;
	reg [24:0] snap_dl_addr;
	reg snap_rd = 0;
	wire snap_wr;
	wire tape_req;
	always @(*) begin
		//if (_sv2v_0)
			;
		casex ({snap_dl | snap_reset, mmc_ram_en, page_special, addr[15:14]})
			'b1xxxx: ram_addr = (snap_rd ? SNAP_ADDR + snap_dl_addr : snap_addr);
			'b1000: ram_addr = {4'b1000, mmc_ram_bank, addr[12:0]};
			//'b0: ram_addr = {3'b101, page_rom, addr[13:0]};
			'b0: ram_addr = {3'b001, page_rom, addr[13:0]};
			'b0x001: ram_addr = {7'h05, addr[13:0]};
			'b0x010: ram_addr = {7'h02, addr[13:0]};
			'b0x011: ram_addr = {1'b0, page_ram, addr[13:0]};
			'b0x100: ram_addr = {4'd0, |page_reg_plus3[2:1], 2'b00, addr[13:0]};
			'b0x101: ram_addr = {4'd0, |page_reg_plus3[2:1], &page_reg_plus3[2:1], 1'b1, addr[13:0]};
			'b0x110: ram_addr = {4'd0, |page_reg_plus3[2:1], 2'b10, addr[13:0]};
			'b0x111: ram_addr = {4'd0, ~page_reg_plus3[2] & page_reg_plus3[1], 2'b11, addr[13:0]};
		endcase
		casex ({snap_dl | snap_reset, dma, tape_req})
			'b1xx: ram_din = snap_data;
			'b1x: ram_din = ioctl_dout;
			'b1: ram_din = 0;
			'b0: ram_din = cpu_dout;
		endcase
		casex ({snap_dl | snap_reset, dma, tape_req})
			'b1xx: ram_rd = snap_rd;
			'b1x: ram_rd = 0;
			'b1: ram_rd = ~nMREQ;
			'b0: ram_rd = ~nMREQ & ~nRD;
		endcase
		casex ({snap_dl | snap_reset, dma, tape_req})
			'b1xx: ram_we = snap_wr;
			'b1x: ram_we = ioctl_wr;
			'b1: ram_we = 0;
			'b0: ram_we = (((((mmc_ram_en | page_special) | addr[15]) | addr[14]) | ((plusd_mem | mf128_mem) & addr[13])) & ~nMREQ) & ~nWR;
		endcase
	end
	//wire gs_sdram_ack;
	//reg [24:0] gs_sdram_addr;
	//reg [7:0] gs_sdram_din;
	//wire [15:0] gs_sdram_dout;
	//reg gs_sdram_req;
	//reg gs_sdram_we;
	wire sdram_ack;
	reg [24:0] sdram_addr;
	reg [7:0] sdram_din;
	wire [15:0] sdram_dout;
	reg sdram_req;
	reg sdram_we;
	//sdram ram(
		//.SDRAM_DQ(SDRAM_DQ),
		//.SDRAM_A(SDRAM_A),
		//.SDRAM_DQML(SDRAM_DQML),
		//.SDRAM_DQMH(SDRAM_DQMH),
		//.SDRAM_BA(SDRAM_BA),
		//.SDRAM_nCS(SDRAM_nCS),
		//.SDRAM_nWE(SDRAM_nWE),
		//.SDRAM_nRAS(SDRAM_nRAS),
		//.SDRAM_nCAS(SDRAM_nCAS),
		//.init_n(locked),
		//.clk(clk_sys),
		//.clkref(ce_14m),
		//.port1_req(sdram_req),
		//.port1_a(sdram_addr[23:1]),
		//.port1_ds((sdram_we ? {sdram_addr[0], ~sdram_addr[0]} : 2'b11)),
		//.port1_d({sdram_din, sdram_din}),
		//.port1_q(sdram_dout),
		//.port1_we(sdram_we),
		//.port1_ack(sdram_ack),
		//.port2_req(gs_sdram_req),
		//.port2_a(gs_sdram_addr[23:1]),
		//.port2_ds((gs_sdram_we ? {gs_sdram_addr[0], ~gs_sdram_addr[0]} : 2'b11)),
		//.port2_q(gs_sdram_dout),
		//.port2_d({gs_sdram_din, gs_sdram_din}),
		//.port2_we(gs_sdram_we),
		//.port2_ack(gs_sdram_ack)
	//);

	//dpSRAM_5128 sram0
	//(
		//.clk_i         (clk_sys),
		//.porta0_addr_i (sdram_addr[23:1]),
		//.porta0_we_i   (sdram_we    ),
		//.porta0_ce_i (sdram_req),
		//.porta0_oe_i   (sdram_req && !sdram_we),
		//.porta0_data_i ({sdram_din, sdram_din}),
		//.porta0_data_o (sdram_dout),

		//.porta1_addr_i (gs_sdram_addr),
		//.porta1_we_i   (gs_rom_we | gs_mem_wr),
		//.porta1_ce_i   (gs_mem_rd),
		//.porta1_oe_i   (gs_mem_rd),
		//.porta1_data_i (gs_mem_dout),
		//.porta1_data_o (gs_mem_din),

		//.sram_addr_o  (SRAM_ADDR),
		//.sram_data_io (SRAM_DQ),
		//.sram_ce_n_o  (       ),
		//.sram_oe_n_o  (       ),
		//.sram_we_n_o  (SRAM_WE_N)
		//);


	assign SRAM_ADDR = sdram_addr[18:0];
	assign SRAM_DQ = sdram_we ? sdram_din : 8'hzz;
	assign ram_dout = SRAM_DQ;
	assign SRAM_WE_N = !sdram_we;




	//assign SDRAM_CKE = 1;
	reg ram_rd_old;
	reg ram_rd_old2;
	reg ram_we_old;
	wire new_ram_req = (~ram_rd_old2 & ram_rd_old) || (~ram_we_old & ram_we);
	wire [24:0] tape_addr;
	always @(posedge clk_sys) begin
		ram_rd_old <= ram_rd;
		ram_rd_old2 <= ram_rd_old;
		ram_we_old <= ram_we;
		if (new_ram_req) begin
			sdram_req <= ~sdram_req;
			sdram_we <= ram_we;
			sdram_din <= ram_din;
			casex ({dma, tape_req})
				'b1x: sdram_addr <= ioctl_addr + (ioctl_index == 0 ? ROM_ADDR : (ioctl_index == 2 ? TAPE_ADDR : SNAP_ADDR));
				'b1: sdram_addr <= tape_addr + TAPE_ADDR;
				'b0: sdram_addr <= ram_addr;
			endcase
		end
	end
	//assign ram_dout = (sdram_addr[0] ? sdram_dout[15:8] : sdram_dout[7:0]);
	//assign ram_ready = (sdram_ack == sdram_req) & ~new_ram_req;
	assign ram_ready = 1'b1;
	//wire [20:0] gs_mem_addr;
	//wire [7:0] gs_mem_dout;
	//wire [7:0] gs_mem_din;
	//wire gs_mem_rd;
	//wire gs_mem_wr;
	//wire gs_mem_ready;
	//reg [7:0] gs_mem_mask;
	//always @(*) begin
		////if (_sv2v_0)
			//;
		//gs_mem_mask = 0;
		//case (st_gs_memory)
			//0:
				//if (gs_mem_addr[20:19])
					//gs_mem_mask = 8'hff;
			//1:
				//if (gs_mem_addr[20])
					//gs_mem_mask = 8'hff;
			//2, 3: gs_mem_mask = 0;
		//endcase
	//end
	//wire gs_rom_we = ioctl_wr && (ioctl_index == 0);
	//reg gs_mem_rd_old;
	//reg gs_mem_wr_old;
	//wire new_gs_mem_req = ((~gs_mem_rd_old & gs_mem_rd) || (~gs_mem_wr_old & gs_mem_wr)) || gs_rom_we;
	//always @(posedge clk_sys) begin
		//gs_mem_rd_old <= gs_mem_rd;
		//gs_mem_wr_old <= gs_mem_wr;
		//if (new_gs_mem_req) begin
			//if (((gs_sdram_we | gs_rom_we) | gs_mem_wr) | (gs_sdram_addr[20:1] != gs_mem_addr[20:1])) begin
				//gs_sdram_req <= ~gs_sdram_req;
				//gs_sdram_we <= gs_rom_we | gs_mem_wr;
				//gs_sdram_din <= (gs_rom_we ? ioctl_dout : gs_mem_din);
			//end
			//gs_sdram_addr <= (gs_rom_we ? ioctl_addr - 24'h030000 : gs_mem_addr);
		//end
	//end
	//assign gs_mem_dout = (gs_sdram_addr[0] ? gs_sdram_dout[15:8] : gs_sdram_dout[7:0]);
	//assign gs_mem_ready = (gs_sdram_ack == gs_sdram_req) & ~new_gs_mem_req;
	//assign gs_mem_ready = 1'b1;

	wire vram_sel = (((ram_addr[20:16] == 1) & ram_addr[14]) & ~dma) & ~tape_req;
	wire [14:0] vram_addr;
	wire [7:0] vram_dout;
	vram vram(
		.clock(clk_sys),
		.wraddress({ram_addr[15], ram_addr[13:0]}),
		.data(ram_din),
		.wren(ram_we & vram_sel),
		.rdaddress(vram_addr),
		.q(vram_dout)
	);
	(* maxfan = 10 *) reg zx48;
	(* maxfan = 10 *) reg p1024;
	(* maxfan = 10 *) reg pf1024;
	(* maxfan = 10 *) reg plus3;
	wire page_scr = page_reg[3];
	wire page_write = ((~addr[15] & ~addr[1]) & (addr[14] | ~plus3)) & ~page_disable;
	wire page_write_plus3 = (((((~addr[1] & addr[12]) & ~addr[13]) & ~addr[14]) & ~addr[15]) & plus3) & ~page_disable;
	wire motor_plus3 = page_reg_plus3[3];
	wire page_p1024 = (((addr[15] & addr[14]) & addr[13]) & ~addr[12]) & ~addr[3];
	wire active_48_rom = (zx48 | (page_reg[4] & ~plus3)) | (((plus3 & page_reg[4]) & page_reg_plus3[2]) & ~page_special);
	reg [1:0] ula_type;
	reg [2:0] memory_mode;
	wire [4:0] snap_hw;
	wire snap_hwset;
	always @(posedge clk_sys) begin : sv2v_autoblock_5
		reg [1:0] st_ula_type_old;
		reg [2:0] st_memory_mode_old;
		st_ula_type_old <= st_ula_type;
		st_memory_mode_old <= st_memory_mode;
		if (reset) begin
			ula_type <= st_ula_type;
			memory_mode <= st_memory_mode;
		end
		else begin
			if (st_ula_type_old != st_ula_type)
				ula_type <= st_ula_type;
			if (st_memory_mode_old != st_memory_mode)
				memory_mode <= st_memory_mode;
		end
		if (snap_hwset)
			{memory_mode, ula_type} <= snap_hw;
	end
	wire mmc_rom_en;
	always @(*) begin
		//if (_sv2v_0)
			;
		casex ({mmc_rom_en, trdos_en, plusd_mem, mf128_mem, plus3})
			'b1xxxx: page_rom <= 4'b0100;
			'b1xxx: page_rom <= 4'b0101;
			'b1xx: page_rom <= 4'b1100;
			'b1x: page_rom <= {2'b11, plus3, ~plus3};
			'b1: page_rom <= {2'b10, page_reg_plus3[2], page_reg[4]};
			'b0: page_rom <= {zx48, 2'b11, zx48 | page_reg[4]};
		endcase
	end
	reg auto_reset_r;
	wire [7:0] snap_1ffd;
	wire [7:0] snap_7ffd;
	always @(posedge clk_sys) begin : sv2v_autoblock_6
		reg old_reset;
		reg [2:0] rmod;
		auto_reset_r <= auto_reset;
		old_reset <= reset;
		if (~old_reset & reset)
			rmod <= mod;
		if (reset) begin
			page_scr_copy <= 0;
			page_reg <= 0;
			page_reg_plus3 <= 0;
			page_reg_p1024 <= 0;
			page_128k <= 0;
			page_reg[4] <= auto_reset_r;
			page_reg_plus3[2] <= auto_reset_r;
			if (auto_reset_r && (rmod == 1)) begin
				p1024 <= 0;
				pf1024 <= 0;
				zx48 <= ~plus3;
			end
			else begin
				p1024 <= memory_mode == 1;
				pf1024 <= memory_mode == 2;
				zx48 <= memory_mode == 3;
				plus3 <= memory_mode == 4;
			end
		end
		else if (snap_REGSet) begin
			if (((snap_hw == ARCH_ZX128) || (snap_hw == ARCH_P128)) || (snap_hw == ARCH_ZX3))
				page_reg <= snap_7ffd;
			if (snap_hw == ARCH_ZX3)
				page_reg_plus3 <= snap_1ffd;
		end
		else if (io_wr & ~old_wr) begin
			if (page_write) begin
				page_reg <= cpu_dout;
				if (p1024 & ~page_reg_p1024[2])
					page_128k[2:0] <= {cpu_dout[5], cpu_dout[7:6]};
				if (~plusd_mem)
					page_scr_copy <= cpu_dout[3];
			end
			else if (page_write_plus3)
				page_reg_plus3 <= cpu_dout;
			if (pf1024 & (addr == 'hdffd))
				page_128k <= cpu_dout[2:0];
			if (p1024 & page_p1024)
				page_reg_p1024 <= cpu_dout;
		end
	end
	reg [2:0] border_color;
	reg ear_out;
	reg mic_out;
	wire [2:0] snap_border;
	wire ula_nWR;
	always @(posedge clk_sys) begin
		if (reset)
			{ear_out, mic_out} <= 2'b00;
		else if (~ula_nWR) begin
			border_color <= cpu_dout[2:0];
			ear_out <= cpu_dout[4];
			mic_out <= cpu_dout[3];
		end
		if (snap_REGSet)
			border_color <= snap_border;
	end
	wire [10:0] psg_left;
	wire [10:0] psg_right;
	wire psg_we = ((psg_enable & ~nIORQ) & ~nWR) & nM1;
	reg psg_reset;
	turbosound turbosound(
		.CLK(clk_sys),
		.CE(ce_psg),
		.RESET(reset | psg_reset),
		.BDIR(psg_we),
		.BC(addr[14]),
		.DI(cpu_dout),
		.DO(sound_data),
		.AUDIO_L(psg_left),
		.AUDIO_R(psg_right),
		.IOA_in(0),
		.IOB_in(0)
	);
	//wire [14:0] gs_l;
	//wire [14:0] gs_r;
	//reg [3:0] gs_ce_count;
	//wire gs_ce_p = gs_ce_count == 0;
	//always @(posedge clk_sys) begin : sv2v_autoblock_7
		//reg gs_no_wait;
		//if (reset) begin
			//gs_ce_count <= 0;
			//gs_no_wait <= 1;
		//end
		//else begin
			//if (gs_ce_p)
				//gs_no_wait <= 0;
			//if (gs_mem_ready)
				//gs_no_wait <= 1;
			//if (gs_ce_count == 4'd7) begin
				//if (gs_mem_ready | gs_no_wait)
					//gs_ce_count <= 0;
			//end
			//else
				//gs_ce_count <= gs_ce_count + 1'd1;
		//end
	//end
	//wire gs_ce_n = gs_ce_count == 4;
	//gs #(.INT_DIV(373)) gs(
		//.RESET(reset),
		//.CLK(clk_sys),
		//.CE_N(gs_ce_n),
		//.CE_P(gs_ce_p),
		//.A(addr[3]),
		//.DI(cpu_dout),
		//.DO(gs_dout),
		//.CS_n((~nM1 | nIORQ) | ~gs_sel),
		//.WR_n(nWR),
		//.RD_n(nRD),
		//.MEM_ADDR(gs_mem_addr),
		//.MEM_DI(gs_mem_din),
		//.MEM_DO(gs_mem_dout | gs_mem_mask),
		//.MEM_RD(gs_mem_rd),
		//.MEM_WR(gs_mem_wr),
		//.MEM_WAIT(~gs_mem_ready),
		//.OUTL(gs_l),
		//.OUTR(gs_r)
	//);
	reg [7:0] sd_l0;
	reg [7:0] sd_l1;
	reg [7:0] sd_r0;
	reg [7:0] sd_r1;
	wire covox_cs = ((~nIORQ & ~nWR) & nM1) && ((addr[7:0] == 8'hfb) & ~trdos_en);
	wire soundrive_a_cs = ((~nIORQ & ~nWR) & nM1) && ((addr[7:0] == 8'h0f) & ~trdos_en);
	wire soundrive_b_cs = ((~nIORQ & ~nWR) & nM1) && ((addr[7:0] == 8'h1f) & ~trdos_en);
	wire soundrive_c_cs = ((~nIORQ & ~nWR) & nM1) && ((addr[7:0] == 8'h4f) & ~trdos_en);
	wire soundrive_d_cs = ((~nIORQ & ~nWR) & nM1) && ((addr[7:0] == 8'h5f) & ~trdos_en);
	always @(posedge clk_sys)
		if (reset) begin
			sd_l0 <= 8'h00;
			sd_l1 <= 8'h00;
			sd_r0 <= 8'h00;
			sd_r1 <= 8'h00;
		end
		else begin
			if (covox_cs || soundrive_a_cs)
				sd_l0 <= cpu_dout;
			if (covox_cs || soundrive_b_cs)
				sd_l1 <= cpu_dout;
			if (covox_cs || soundrive_c_cs)
				sd_r0 <= cpu_dout;
			if (covox_cs || soundrive_d_cs)
				sd_r1 <= cpu_dout;
		end
	reg [15:0] audio_left;
	reg [15:0] audio_right;
	//assign AUDIO_LEFT[15:0] = audio_left;
	//assign AUDIO_RIGHT[15:0] = audio_right;
	wire tape_in;
	always @(posedge clk_sys) begin
		//audio_left <= ((({~gs_l[14], gs_l[13:0], 1'b0} + {1'd0, psg_left, 4'd0}) + {2'd0, sd_l0, 5'd0}) + {2'd0, sd_l1, 5'd0}) + {2'd0, ear_out, mic_out, tape_in, 11'd0};
		audio_left <= ((({1'd0, psg_left, 4'd0}) + {2'd0, sd_l0, 5'd0}) + {2'd0, sd_l1, 5'd0}) + {2'd0, ear_out, mic_out, tape_in, 11'd0};
		//audio_right <= ((({~gs_r[14], gs_r[13:0], 1'b0} + {1'd0, psg_right, 4'd0}) + {2'd0, sd_r0, 5'd0}) + {2'd0, sd_r1, 5'd0}) + {2'd0, ear_out, mic_out, tape_in, 11'd0};
		audio_right <= ((({1'd0, psg_right, 4'd0}) + {2'd0, sd_r0, 5'd0}) + {2'd0, sd_r1, 5'd0}) + {2'd0, ear_out, mic_out, tape_in, 11'd0};
	end
	//assign AUDIO_LEFT[15:0] = audio_left;
	//assign AUDIO_RIGHT[15:0] = audio_right;
	sigma_delta_dac #(.MSBI(14)) dac_l(
		.CLK(clk_sys),
		.RESET(reset),
		//.DACin(((({~gs_l[14], gs_l[13:0]} + {1'd0, psg_left, 3'd0}) + {2'd0, sd_l0, 4'd0}) + {2'd0, sd_l1, 4'd0}) + {2'd0, ear_out, mic_out, tape_in, 10'd0}),
		.DACin(((({1'd0, psg_left, 3'd0}) + {2'd0, sd_l0, 4'd0}) + {2'd0, sd_l1, 4'd0}) + {2'd0, ear_out, mic_out, tape_in, 10'd0}),
		.DACout(AUDIO_L)
	);
	sigma_delta_dac #(.MSBI(14)) dac_r(
		.CLK(clk_sys),
		.RESET(reset),
		//.DACin(((({~gs_r[14], gs_r[13:0]} + {1'd0, psg_right, 3'd0}) + {2'd0, sd_r0, 4'd0}) + {2'd0, sd_r1, 4'd0}) + {2'd0, ear_out, mic_out, tape_in, 10'd0}),
		.DACin(((({1'd0, psg_right, 3'd0}) + {2'd0, sd_r0, 4'd0}) + {2'd0, sd_r1, 4'd0}) + {2'd0, ear_out, mic_out, tape_in, 10'd0}),
		.DACout(AUDIO_R)
	);
	(* maxfan = 10 *) wire ce_cpu_sn;
	(* maxfan = 10 *) wire ce_cpu_sp;
	reg mZX;
	reg m128;
	always @(*) begin
		//if (_sv2v_0)
			;
		case (ula_type)
			0: {mZX, m128} <= 2'b10;
			1: {mZX, m128} <= 2'b11;
			default: {mZX, m128} <= 2'b00;
		endcase
	end
	wire [1:0] scale = st_scanlines;
	wire [5:0] Rx;
	wire [5:0] Gx;
	wire [5:0] Bx;
	wire HSync;
	wire VSync;
	wire HBlank;
	wire ulap_ena;
	wire ulap_mono;
	wire mode512;
	wire ulap_avail = ~status[14] & ~trdos_en;
	wire tmx_avail = ~status[13] & ~trdos_en;
	wire snow_ena = (&turbo & ~plus3) & ~unrainer;
	ULA ULA(
		//.reset(reset),
		.reset(1'b0),
		.clk_sys(clk_sys),
		.ce_7mp(ce_7mp),
		.ce_7mn(ce_7mn),
		.ce_cpu_sp(ce_cpu_sp),
		.ce_cpu_sn(ce_cpu_sn),
		.addr(addr),
		.nMREQ(nMREQ),
		.nIORQ(nIORQ),
		.nRD(nRD),
		.nWR(nWR),
		.nINT(nINT),
		.vram_addr(vram_addr),
		.vram_dout(vram_dout),
		.port_ff(port_ff),
		.ulap_avail(ulap_avail),
		.ulap_sel(ulap_sel),
		.ulap_dout(ulap_dout),
		.ulap_ena(ulap_ena),
		.ulap_mono(ulap_mono),
		.tmx_avail(tmx_avail),
		.mode512(mode512),
		.snow_ena(snow_ena),
		.mZX(mZX),
		.m128(m128),
		.page_scr(page_scr),
		.border_color(border_color),
		.HSync(HSync),
		.VSync(VSync),
		.HBlank(HBlank),
		.Rx(Rx),
		.Gx(Gx),
		.Bx(Bx),
		.nPortRD(),
		.nPortWR(ula_nWR),
		.din(cpu_dout),
		.page_ram(page_ram[2:0])
	);
	video_mixer #(
		.LINE_LENGTH(896),
		.HALF_DEPTH(0)
	) video_mixer(
		.clk_sys(clk_sys),
		.SPI_SCK(SPI_SCK),
		.SPI_SS3(SPI_SS3),
		.SPI_DI(SPI_DI),
		.scandoubler_disable(scandoubler_disable),
		.ypbpr(ypbpr),
		.HSync(HSync),
		.VSync(VSync),
		.VGA_R(VGA_R_x),
		.VGA_G(VGA_G_x),
		.VGA_B(VGA_B_x),
		.VGA_VS(VGA_VS),
		.VGA_HS(VGA_HS),
		.ce_pix(ce_7mp | ce_7mn),
		.ce_pix_actual(ce_7mp | (mode512 & ce_7mn)),
		.hq2x(scale == 1),
		.scanlines((scandoubler_disable ? 2'b00 : {scale == 3, scale == 2})),
		.line_start(0),
		.ypbpr_full(1),
		.R(Rx),
		.G(Gx),
		.B(Bx),
		.mono(ulap_ena & ulap_mono)
	);
	keyboard kbd(
		.reset(reset),
		.clk_sys(clk_sys),
		.ps2_key(ps2_key),
		.addr(addr),
		.key_data(key_data),
		.Fn(Fn),
		.mod(mod)
	);
	always @(*) begin
		joy_kempston = 6'h00;
		joy_sinclair1 = 5'h00;
		joy_sinclair2 = 5'h00;
		joy_cursor = 5'h00;
		case (st_joy1)
			2'b00: joy_sinclair1 = joy_sinclair1 | joystick_0[4:0];
			2'b01: joy_sinclair2 = joy_sinclair2 | joystick_0[4:0];
			2'b10: joy_kempston = joy_kempston | joystick_0[5:0];
			2'b11: joy_cursor = joy_cursor | joystick_0[4:0];
			default:
				;
		endcase
		case (st_joy2)
			2'b00: joy_sinclair1 = joy_sinclair1 | joystick_1[4:0];
			2'b01: joy_sinclair2 = joy_sinclair2 | joystick_1[4:0];
			2'b10: joy_kempston = joy_kempston | joystick_1[5:0];
			2'b11: joy_cursor = joy_cursor | joystick_1[4:0];
			default:
				;
		endcase
	end
	mouse mouse(
		.clk_sys(clk_sys),
		.ps2_mouse(ps2_mouse),
		.reset(cold_reset),
		.addr(addr[10:8]),
		.sel(),
		.dout(mouse_data)
	);
	always @(posedge clk_sys) begin : sv2v_autoblock_8
		reg old_status = 0;
		old_status <= ps2_mouse[24];
		if (joy_kempston[5:0])
			mouse_sel <= 0;
		if (old_status != ps2_mouse[24])
			mouse_sel <= 1;
	end
	always @(posedge clk_sys) begin
		if (reset)
			{mf128_mem, mf128_en} <= 0;
		else if (~old_rd & io_rd) begin
			if (mf128_port)
				mf128_mem <= (addr[7] ^ plus3) & mf128_en;
		end
		else if (~old_wr & io_wr) begin
			if (mf128_port)
				mf128_en <= addr[7] & mf128_en;
		end
		if (((((~old_m1 & m1) & (mod[0] | ~plusd_en)) & (st_mmc != 2'b11)) & NMI_pending) & (addr == 'h66))
			{mf128_mem, mf128_en} <= 2'b11;
	end
	wire mmc_mem_en;
	wire spi_ss;
	wire spi_clk;
	wire spi_di;
	wire spi_do;
	wire tape_loaded;
	divmmc divmmc(
		.clk_sys(clk_sys),
		.nWR(nWR),
		.nRD(nRD),
		.nMREQ(nMREQ),
		.nRFSH(nRFSH),
		.nIORQ(nIORQ),
		.nM1(nM1),
		.addr(addr),
		.spi_ss(spi_ss),
		.spi_clk(spi_clk),
		.spi_di(spi_di),
		.spi_do(spi_do),
		.enable(1),
		.disable_pagein(tape_loaded),
		.mode(st_mmc),
		.din(cpu_dout),
		.dout(mmc_dout),
		.active_io(mmc_sel),
		.rom_active(mmc_rom_en),
		.ram_active(mmc_ram_en),
		.ram_bank(mmc_ram_bank)
	);
	sd_card sd_card(
		.clk_sys(clk_sys),
		.sd_ack(sd_ack),
		.sd_ack_conf(sd_ack_conf),
		.sd_conf(sd_conf),
		.sd_sdhc(sd_sdhc),
		.img_size(img_size),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_wr(sd_buff_wr),
		.sd_buff_addr(sd_buff_addr),
		.img_mounted(img_mounted[0]),
		.sd_busy(sd_busy_mmc),
		.sd_rd(sd_rd_mmc),
		.sd_wr(sd_wr_mmc),
		.sd_lba(sd_lba_mmc),
		.sd_buff_din(sd_buff_din_mmc),
		.allow_sdhc(1),
		.sd_cs(spi_ss),
		.sd_sck(spi_clk),
		.sd_sdi(spi_do),
		.sd_sdo(spi_di)
	);
	reg trd_mounted;
	wire fdd_rd;
	wire fdd_ready = (plusd_mounted & ~plus3) | trd_mounted;
	reg fdd_drive1;
	reg fdd_side;
	reg fdd_reset;
	always @(posedge clk_sys) begin : sv2v_autoblock_9
		reg old_mounted;
		if (reset)
			{plusd_mem, trdos_en} <= 0;
		old_mounted <= img_mounted[1];
		if (~old_mounted & img_mounted[1]) begin
			plus3_fdd_ready <= (ioctl_ext_index == 2) & |img_size;
			trd_mounted <= (ioctl_ext_index == 0) & |img_size;
			plusd_mounted <= ((ioctl_ext_index == 1) | (ioctl_ext_index == 3)) & |img_size;
		end
		psg_reset <= 0;
		if (plusd_en) begin
			trdos_en <= 0;
			if (((~old_wr & io_wr) & (addr[7:0] == 'hef)) & plusd_ena)
				{fdd_side, fdd_drive1} <= {cpu_dout[7], cpu_dout[1:0] != 2};
			if ((~old_wr & io_wr) & (addr[7:0] == 'he7))
				plusd_mem <= 0;
			if (((~old_rd & io_rd) & (addr[7:0] == 'he7)) & ~plusd_stealth)
				plusd_mem <= 1;
			if ((~old_m1 & m1) & (((addr == 'h8) | (addr == 'h3a)) | (((~mod[0] & NMI_pending) & (st_mmc != 2'b11)) & (addr == 'h66))))
				{psg_reset, plusd_mem} <= {addr == 'h66, 1'b1};
		end
		else begin
			plusd_mem <= 0;
			if (((~old_wr & io_wr) & fdd_sel) & addr[7])
				{fdd_side, fdd_reset, fdd_drive1} <= {~cpu_dout[4], ~cpu_dout[2], !cpu_dout[1:0]};
			if (m1 && ~old_m1) begin
				if (addr[15:14])
					trdos_en <= 0;
				else if (((addr[13:8] == 'h3d) & active_48_rom) & (st_mmc != 2'b11))
					trdos_en <= 1;
			end
		end
	end
`ifdef WD
	wd1793 #(
		.RWMODE(1),
		.EDSK(0)
	) fdd(
		.clk_sys(clk_sys),
		.ce(ce_wd1793),
		.reset((fdd_reset & ~plusd_en) | reset),
		.io_en(((fdd_sel2 | (fdd_sel & ~addr[7])) & ~nIORQ) & nM1),
		.rd(~nRD),
		.wr(~nWR),
		.addr((plusd_en ? addr[4:3] : addr[6:5])),
		.din(cpu_dout),
		.dout(wd_dout),
		.drq(fdd_drq),
		.intrq(fdd_intrq),
		.img_mounted(img_mounted[1]),
		.img_size(img_size),
		.sd_lba(sd_lba_wd),
		.sd_rd(sd_rd_wd),
		.sd_wr(sd_wr_wd),
		.sd_ack(sd_ack),
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din(sd_buff_din_wd),
		.sd_buff_wr(sd_buff_wr),
		.wp(0),
		.size_code((plusd_en ? 3'd4 : 3'd1)),
		.layout(ioctl_ext_index == 1),
		.side(fdd_side),
		.ready(fdd_drive1 & fdd_ready),
		.input_active(0),
		.input_addr(0),
		.input_data(0),
		.input_wr(0),
		.buff_din(0)
	);
`endif
`ifdef ZXP3
	u765 #(
		.CYCLES(20'd1800),
		.SPECCY_SPEEDLOCK_HACK(1)
	) u765(
		.clk_sys(clk_sys),
		.ce(ce_u765),
		.reset(reset),
		.a0(addr[12]),
		.ready(plus3_fdd_ready),
		.motor(motor_plus3),
		.available(2'b01),
		.fast(1),
		.nRD(((~plus3_fdd | nIORQ) | ~nM1) | nRD),
		.nWR(((~plus3_fdd | nIORQ) | ~nM1) | nWR),
		.din(cpu_dout),
		.dout(u765_dout),
		.img_mounted(img_mounted[1]),
		.img_size(img_size),
		.img_wp(0),
		.sd_lba(sd_lba_plus3),
		.sd_rd(sd_rd_plus3),
		.sd_wr(sd_wr_plus3),
		.sd_ack(sd_ack),
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din(sd_buff_din_plus3),
		.sd_buff_wr(sd_buff_wr)
	);
`endif
`ifdef TAPE
	wire tape_turbo;
	wire tape_vin;
	smart_tape tape(
		.clk_sys(clk_sys),
		.addr(addr),
		.reset(reset & ~auto_reset_r),
		.ce(ce_tape),
		.turbo(tape_turbo),
		.mode48k(page_disable),
		.pause(Fn[1]),
		.prev(Fn[2]),
		.next(Fn[3]),
		.audio_out(tape_vin),
		.led(tape_led),
		.active(tape_active),
		.available(tape_loaded),
		.req_hdr((reg_DE == 'h11) & !reg_A),
		.buff_rd_en(~nRFSH),
		.buff_rd(tape_req),
		.buff_addr(tape_addr),
		.buff_din(ram_dout),
		.ioctl_download(ioctl_download & (ioctl_index == 2)),
		.tape_size(ioctl_addr + 1'b1),
		.tape_mode(ioctl_ext_index),
		.m1(~nM1 & ~nMREQ),
		.rom_en(active_48_rom),
		.dout_en(tape_dout_en),
		.dout(tape_dout)
	);
	reg tape_loaded_reg = 0;
	always @(posedge clk_sys) begin : sv2v_autoblock_10
		reg signed [31:0] timeout = 0;
		if (tape_loaded) begin
			tape_loaded_reg <= 1;
			timeout <= 100000000;
		end
		else if (timeout)
			timeout <= timeout - 1;
		else
			tape_loaded_reg <= 0;
	end
	//assign UART_TX = 1;
	assign tape_in = ~(tape_loaded_reg ? tape_vin : EAR);
	assign ula_tape_in = (tape_in | ear_out) | ((issue2 & !tape_active) & mic_out);
`else
	assign tape_in = EAR;
	assign ula_tape_in = (tape_in | ear_out) | ((issue2 & !tape_active) & mic_out);
`endif

`ifdef SNAP
	reg [7:0] snap_dl_data;
	reg snap_dl_wr;
	wire snap_dl_wait;
	reg snap_rd_old;
	reg snap_rd_state;
	always @(posedge clk_sys) begin
		snap_rd_old <= snap_rd;
		if (((ioctl_index == 3) && old_download) && ~ioctl_download) begin
			snap_dl <= 1;
			snap_dl_addr <= 0;
			snap_rd_state <= 0;
			snap_dl_wr <= 0;
		end
		snap_dl_wr <= 0;
		if (snap_dl)
			case (snap_rd_state)
				0:
					if (snap_dl_addr == (ioctl_addr + 2'd2))
						snap_dl <= 0;
					else begin
						if (snap_dl_wr)
							snap_dl_addr <= snap_dl_addr + 1'd1;
						if (((ram_ready & ~snap_wr) & ~snap_dl_wr) & ~snap_dl_wait) begin
							if (~snap_rd | ~snap_rd_old)
								snap_rd <= 1;
							else begin
								snap_rd <= 0;
								snap_rd_state <= 1;
							end
						end
					end
				1: begin
					snap_dl_wr <= 1;
					snap_dl_data <= ram_dout;
					snap_rd_state <= 0;
				end
				default:
					;
			endcase
	end
	wire [31:0] snap_status;
	snap_loader #(
		.ARCH_ZX48(ARCH_ZX48),
		.ARCH_ZX128(ARCH_ZX128),
		.ARCH_ZX3(ARCH_ZX3),
		.ARCH_P128(ARCH_P128)
	) snap_loader(
		.clk_sys(clk_sys),
		.ioctl_download(snap_dl),
		.ioctl_addr(snap_dl_addr),
		.ioctl_data(snap_dl_data),
		.ioctl_wr(snap_dl_wr),
		.ioctl_wait(snap_dl_wait),
		.snap_sna(ioctl_ext_index[0]),
		.ram_ready(ram_ready),
		.REG(snap_REG),
		.REGSet(snap_REGSet),
		.addr(snap_addr),
		.dout(snap_data),
		.wr(snap_wr),
		.reset(snap_reset),
		.hwset(snap_hwset),
		.hw(snap_hw),
		.hw_ack({memory_mode, ula_type}),
		.border(snap_border),
		.reg_1ffd(snap_1ffd),
		.reg_7ffd(snap_7ffd)
	);
`endif
	//initial _sv2v_0 = 0;
endmodule
