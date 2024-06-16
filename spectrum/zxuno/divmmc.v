module divmmc (
	clk_sys,
	mode,
	nWR,
	nRD,
	nMREQ,
	nRFSH,
	nIORQ,
	nM1,
	addr,
	din,
	dout,
	enable,
	disable_pagein,
	active_io,
	rom_active,
	ram_active,
	ram_bank,
	spi_ss,
	spi_clk,
	spi_di,
	spi_do
);
	input clk_sys;
	input [1:0] mode;
	input nWR;
	input nRD;
	input nMREQ;
	input nRFSH;
	input nIORQ;
	input nM1;
	input [15:0] addr;
	input [7:0] din;
	output wire [7:0] dout;
	input enable;
	input disable_pagein;
	output wire active_io;
	output wire rom_active;
	output wire ram_active;
	output wire [3:0] ram_bank;
	output reg spi_ss;
	output wire spi_clk;
	input spi_di;
	output wire spi_do;
	wire io_we = (~nIORQ & ~nWR) & nM1;
	wire io_rd = (~nIORQ & ~nRD) & nM1;
	wire m1 = ~nMREQ & ~nM1;
	reg old_we;
	reg old_rd;
	reg old_m1;
	always @(posedge clk_sys) begin
		old_we <= io_we;
		old_rd <= io_rd;
		old_m1 <= m1;
	end
	wire port_io = (mode[0] && (addr[7:0] == 8'heb)) || ((mode == 2'b10) && (addr[7:0] == 8'h3f));
	assign active_io = port_io;
	wire port_cs = (mode[0] && (addr[7:0] == 8'he7)) || ((mode == 2'b10) && (addr[7:0] == 8'h1f));
	reg tx_strobe;
	reg rx_strobe;
	always @(posedge clk_sys) begin : sv2v_autoblock_1
		reg m1_trigger;
		rx_strobe <= 0;
		tx_strobe <= 0;
		if (enable) begin
			if (io_we & ~old_we) begin
				if (port_cs)
					spi_ss <= din[0];
				if (port_io)
					tx_strobe <= 1'b1;
			end
			if ((io_rd & ~old_rd) & port_io)
				rx_strobe <= 1;
		end
		else
			spi_ss <= 1;
	end
	wire page0 = addr[15:13] == 3'b000;
	wire page1 = addr[15:13] == 3'b001;
	reg automap;
	reg conmem;
	reg mapram;
	assign rom_active = (nRFSH & page0) & (conmem | (!mapram & automap));
	assign ram_active = ((((nRFSH & page0) & !conmem) & mapram) & automap) | (page1 & (conmem | automap));
	reg [3:0] sram_page;
	assign ram_bank = (page0 ? 4'h3 : sram_page);
	always @(posedge clk_sys) begin : sv2v_autoblock_2
		reg m1_trigger;
		if (enable && (mode == 2'b11)) begin
			if (io_we & ~old_we)
				case (addr[7:0])
					'he3: {conmem, mapram, sram_page} <= {din[7:6], din[3:0]};
					default:
						;
				endcase
			if (m1 & ~old_m1)
				casex (addr)
					16'h0000, 16'h0008, 16'h0038, 16'h0066: m1_trigger <= 1;
					16'h04c6, 16'h0562: m1_trigger <= !disable_pagein;
					16'h3dxx: {automap, m1_trigger} <= 2'b11;
					16'b0001111111111xxx: m1_trigger <= 0;
					default:
						;
				endcase
			if (~nRFSH)
				automap <= m1_trigger;
		end
		else begin
			m1_trigger <= 0;
			automap <= 0;
			conmem <= 0;
			sram_page <= 0;
			mapram <= 0;
		end
	end
	spi spi(
		.clk_sys(clk_sys),
		.tx(tx_strobe),
		.rx(rx_strobe),
		.din(din),
		.dout(dout),
		.spi_clk(spi_clk),
		.spi_di(spi_di),
		.spi_do(spi_do)
	);
endmodule
