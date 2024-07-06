module MENU (
	CLOCK_50,
	LED,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_HS,
	VGA_VS,
	SPI_SCK,
	SPI_DO,
	SPI_DI,
	SPI_SS2,
	SPI_SS3,
	CONF_DATA0,
	SPI_SS4,
	SRAM_ADDR,
	SRAM_DQ,
	SRAM_WE_N,
	//SDRAM_A,
	//SDRAM_DQ,
	//SDRAM_DQML,
	//SDRAM_DQMH,
	//SDRAM_nWE,
	//SDRAM_nCAS,
	//SDRAM_nRAS,
	//SDRAM_nCS,
	//SDRAM_BA,
	//SDRAM_CLK,
	//SDRAM_CKE,
	AUDIO_L,
	AUDIO_R,
	UART_RX,
	UART_TX,
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
	JSEL,
	SDA,
	SCL
);
	output wire SD_cs;
	output wire SD_datain;
	output wire SD_clk;
	input wire SD_dataout;
	input wire SD_cs1;
	input wire SD_datain1;
	input wire SD_clk1;
	output wire SD_dataout1;
	input wire CLOCK_50;
	output wire LED;
	localparam VGA_BITS = 6;
	output wire [2:0] VGA_R;
	output wire [2:0] VGA_G;
	output wire [2:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	input wire SPI_SCK;
	inout wire SPI_DO;
	input wire SPI_DI;
	input wire SPI_SS2;
	input wire SPI_SS3;
	input wire CONF_DATA0;
	input wire SPI_SS4;
	output wire [18:0] SRAM_ADDR;
	inout [7:0] SRAM_DQ;
	output wire SRAM_WE_N;

	input wire JUP;
	input wire JDN;
	input wire JLT;
	input wire JRT;
	input wire JF1;
	output wire JSEL;

	inout wire SDA;
	inout wire SCL;

	output wire AUDIO_L;
	output wire AUDIO_R;
	input UART_RX;
	output wire UART_TX;

	input PS2C;
	input PS2D;
	output wire PS2COUT;
	output wire PS2DOUT;

	assign PS2COUT = PS2C;
	assign PS2DOUT = PS2D;

	assign SD_cs = SD_cs1;
	assign SD_datain = SD_datain1;
	assign SD_clk = SD_clk1;
	assign SD_dataout1 = SD_dataout;

	assign JSEL = 1'b1;

	localparam [0:0] DIRECT_UPLOAD = 1;
	localparam [0:0] QSPI = 0;
	localparam [0:0] HDMI = 0;
	localparam [0:0] BIG_OSD = 0;
	localparam SEP = "";
	wire clk_x2;
	wire clk_pix;
	wire clk_ram;
	wire pll_locked;
	pll pll(
		.inclk0(CLOCK_50),
		.c0(clk_ram),
		.c1(clk_x2),
		.c2(clk_pix),
		.locked(pll_locked)
	);
	//assign SDRAM_CLK = clk_ram;
	//assign SDRAM_CKE = 1;
	localparam CONF_STR = {"MENU;;", "O1,Video mode,PAL,NTSC;", "O23,Rotate,Off,Left,Right;", "V,", "231230"};
	wire scandoubler_disable;
	wire ypbpr;
	wire no_csync;
	wire[55:0] rtc;
	wire rtc_reset;
	wire [63:0] status;
	wire SPI_DO_U;
	wire SPI_DO_D;
	assign SPI_DO = (CONF_DATA0 ? SPI_DO_D : SPI_DO_U);
	user_io #(
		.STRLEN(63),
		.FEATURES((32'd1 | (BIG_OSD << 13)) | (HDMI << 14)),
		.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD)
	) user_io(
		.clk_sys(clk_x2),
		.conf_str(CONF_STR),
		.SPI_CLK(SPI_SCK),
		.SPI_SS_IO(CONF_DATA0),
		.SPI_MISO(SPI_DO_U),
		.SPI_MOSI(SPI_DI),
		.status(status),
		.scandoubler_disable(scandoubler_disable),
		.ypbpr(ypbpr),
		.no_csync(no_csync),
		.rtc_in(rtc),
		.rtc_reset(rtc_reset)
	);
	wire ntsc = status[1];
	wire [1:0] rotate = status[3:2];
	wire [8:0] line_max = (ntsc ? 9'd262 : 9'd312);
	wire ioctl_downl;
	assign LED = ~ioctl_downl;
	wire ioctl_upl;
	wire [7:0] ioctl_index;
	wire ioctl_wr;
	wire [24:0] ioctl_addr;
	wire [7:0] ioctl_din;
	wire [7:0] ioctl_dout;
	data_io #(.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD)) data_io(
		.clk_sys(clk_ram),
		.SPI_SCK(SPI_SCK),
		.SPI_SS2(SPI_SS2),
		.SPI_SS4(SPI_SS4),
		//.SPI_SS4(1'b1),
		.SPI_DI(SPI_DI),
		.SPI_DO(SPI_DO_D),
		.ioctl_download(ioctl_downl),
		.ioctl_upload(ioctl_upl),
		.ioctl_index(ioctl_index),
		.ioctl_wr(ioctl_wr),
		.ioctl_addr(ioctl_addr),
		.ioctl_din(ioctl_din),
		.ioctl_dout(ioctl_dout)
	);
	reg [23:0] bmp_data_start;
	wire [23:0] downl_addr = ioctl_addr - bmp_data_start;
	reg bmp_loaded = 0;
	reg port1_req;
	always @(posedge clk_ram) begin : sv2v_autoblock_1
		reg ioctl_wr_last;
		reg ioctl_downl_last;
		ioctl_wr_last <= 0;
		ioctl_downl_last <= 0;
		ioctl_wr_last <= ioctl_wr;
		ioctl_downl_last <= ioctl_downl;
		if (ioctl_downl) begin
			if (~ioctl_wr_last & ioctl_wr) begin
				if (ioctl_addr == 10)
					bmp_data_start[7:0] <= ioctl_dout;
				else if (ioctl_addr == 11)
					bmp_data_start[15:8] <= ioctl_dout;
				else if (ioctl_addr == 12)
					bmp_data_start[23:16] <= ioctl_dout;
				port1_req <= ~port1_req;
			end
		end
		if (ioctl_downl_last & ~ioctl_downl)
			bmp_loaded <= 1;
	end
	wire [31:0] cpu_q;
	reg [23:0] cpu1_addr;
	reg [9:0] hc;
	reg [8:0] vc;
	always @(posedge clk_ram) cpu1_addr <= ((((line_max - 1'd1) - vc) << 9) + hc) << 2;

	//dpSRAM_5128 sram(
		//.clk_i(clk_ram),
		//// Port 0
		//.porta0_addr_i(), //19
		//.porta0_ce_i(),
		//.porta0_oe_i(),
		//.porta0_we_i(),
		//.porta0_data_i(), //8
		//.porta0_data_o(), //8
		//// Port 1
		//.porta1_addr_i(), //19
		//.porta1_ce_i(),
		//.porta1_oe_i(),
		//.porta1_we_i(),
		//.porta1_data_i(), //8
		//.porta1_data_o(), //8
		//// SRAM in board
		//.sram_addr_o(SRAM_ADDR),
		//.sram_data_io(SRAM_DQ),
		//.sram_we_n_o(SRAM_WE_N)
		//.sram_ce_n_o(),
		//.sram_oe_n_o()
	//);

	//reg sram_which = 0;
	//reg[1:0] cpu1_state = 0;
	//reg[18:0] sram_addr = sram_which ? ; { cpu1_addr[18:2], cpu1_state[1:0] } : {downl_addr[17:0], cpu1_state[0]};
	//reg[7:0] portb_d;


	reg[2:0] ram_state;
	reg[31:0] cpu_q_;
	assign cpu_q[31:0] = cpu_q_[31:0];
	reg sram_we_n_o = 1'b1;
	reg[7:0] sram_data_i;
	reg[18:0] sram_addr;

	assign SRAM_DQ[7:0] = SRAM_WE_N ? 8'hZZ : sram_data_i[7:0];
	assign SRAM_WE_N = sram_we_n_o;
	assign SRAM_ADDR[18:0] = sram_addr;

	reg port1_req_a = 1'b0;
	reg port1_req_b = 1'b0;
	reg ioctl_downl_a = 1'b0;
	reg ioctl_downl_b = 1'b0;

	always @(posedge port1_req)
		port1_req_a <= !port1_req_a;

	always @(posedge ioctl_downl)
		ioctl_downl_a <= !ioctl_downl_a;

	always @(posedge clk_ram) begin
		case (ram_state)
			3'd0: begin
				if (port1_req_a ^ port1_req_b) begin
					sram_we_n_o <= 1'b1;
					sram_addr[18:0] <= {cpu1_addr[18:2], 2'b00};
					ram_state <= 8'd1;
					port1_req_b <= port1_req_a;
				end else if (ioctl_downl_a ^ ioctl_downl_b) begin
					//sram_addr[18:0] <= {downl_addr[18:1], 1'b0};
					sram_addr[18:0] <= downl_addr[18:0];
					ram_state <= 8'd5;
					sram_data_i[7:0] <= ioctl_dout[7:0];
					ioctl_downl_b <= ioctl_downl_a;
				end;
			end

			3'd1: begin
				cpu_q_[31:24] <= SRAM_DQ;
				sram_addr[18:0] <= {cpu1_addr[18:2], 2'b01};
				ram_state <= 8'd2;
			end

			3'd2: begin
				cpu_q_[23:16] <= SRAM_DQ;
				sram_addr[18:0] <= {cpu1_addr[18:2], 2'b10};
				ram_state <= 8'd3;
			end

			3'd3: begin
				cpu_q_[15:8] <= SRAM_DQ;
				sram_addr[18:0] <= {cpu1_addr[18:2], 2'b11};
				ram_state <= 8'd4;
			end

			3'd4: begin
				cpu_q_[7:0] <= SRAM_DQ;
				ram_state <= 8'd0;
			end

			3'd5: begin
				sram_we_n_o <= 1'b0;
				ram_state <= 8'd6;
			end

			3'd6: begin
				sram_we_n_o <= 1'b1;
				ram_state <= 8'd0;
			end

		endcase;
	end

	reg [9:0] vvc;
	reg [22:0] rnd_reg;
	wire [5:0] rnd_c = {rnd_reg[0], rnd_reg[1], rnd_reg[2], rnd_reg[2], rnd_reg[2], rnd_reg[2]};
	wire [22:0] rnd;
	lfsr random(.rnd(rnd));
	always @(posedge clk_pix) begin
		if (hc == 799) begin
			hc <= 0;
			if (vc == (line_max - 1)) begin
				vc <= 0;
				vvc <= vvc + 9'd6;
			end
			else
				vc <= vc + 1'd1;
		end
		else
			hc <= hc + 1'd1;
		rnd_reg <= rnd;
	end
	reg HBlank;
	reg HSync;
	reg VBlank;
	reg VSync;
	always @(posedge clk_pix) begin
		if (hc == 639)
			HBlank <= 1;
		else if (hc == 1)
			HBlank <= 0;
		if (hc == 655)
			HSync <= 1;
		else if (hc == 751)
			HSync <= 0;
		if ((vc == (line_max - 3)) && (hc == 655))
			VSync <= 1;
		else if ((vc == 0) && (hc == 751))
			VSync <= 0;
		if (vc == (line_max - 5))
			VBlank <= 1;
		else if (vc == 2)
			VBlank <= 0;
	end
	reg [7:0] cos_out;
	wire [7:0] cos_g = cos_out[7:1] + 6'd32;
	wire [8:1] sv2v_tmp_cos_y;
	always @(*) cos_out = sv2v_tmp_cos_y;

	//wire[9:0] cos_x = vvc + {vc, 2'b00};

	cos cos(
		.x(vvc + {vc, 2'b00}),
		//.x(cos_x),
		.y(sv2v_tmp_cos_y)
	);
	wire [7:0] comp_v = (cos_g >= rnd_c ? cos_g - rnd_c : 8'd0);
	//wire [7:0] comp_v = rnd[7:0];
	wire [7:0] bmp_r = cpu_q[23:16];
	wire [7:0] bmp_g = cpu_q[15:8];
	wire [7:0] bmp_b = cpu_q[7:0];
	wire [7:0] R_in = (bmp_loaded ? bmp_r : comp_v);
	wire [7:0] G_in = (bmp_loaded ? bmp_g : comp_v);
	wire [7:0] B_in = (bmp_loaded ? bmp_b : comp_v);
	wire [5:0] VGA_R_;
	wire [5:0] VGA_G_;
	wire [5:0] VGA_B_;
	assign VGA_R[2:0] = VGA_R_[5:3];
	assign VGA_G[2:0] = VGA_G_[5:3];
	assign VGA_B[2:0] = VGA_B_[5:3];

	mist_video #(
		.COLOR_DEPTH(8),
		.SD_HCNT_WIDTH(10),
		.OSD_X_OFFSET(10),
		.OSD_Y_OFFSET(0),
		.OSD_COLOR(4),
		.OSD_AUTO_CE(0),
		.OUT_COLOR_DEPTH(VGA_BITS),
		.USE_BLANKS(1),
		.BIG_OSD(BIG_OSD)
	) mist_video(
		.clk_sys(clk_x2),
		.SPI_SCK(SPI_SCK),
		.SPI_SS3(SPI_SS3),
		.SPI_DI(SPI_DI),
		.R(R_in),
		.G(G_in),
		.B(B_in),
		.HBlank(HBlank),
		.VBlank(VBlank),
		.HSync(~HSync),
		.VSync(~VSync),
		.VGA_R(VGA_R_),
		.VGA_G(VGA_G_),
		.VGA_B(VGA_B_),
		.VGA_VS(VGA_VS),
		.VGA_HS(VGA_HS),
		.ce_divider(1'b1),
		.rotate({rotate[0], |rotate}),
		.blend(1'b0),
		.scandoubler_disable(scandoubler_disable),
		.scanlines(2'b00),
		.ypbpr(ypbpr),
		.no_csync(no_csync)
	);

	pcf8563 pcf8563_inst(
		.mclk(clk_ram),
		//.reset(1'b1), //rtc_reset),
		.reset(rtc_reset),
		.scl(SCL),
		.sda(SDA),
		.rtc(rtc)
	);

	assign AUDIO_L = 1'b0;
	assign AUDIO_R = 1'b0;

endmodule
