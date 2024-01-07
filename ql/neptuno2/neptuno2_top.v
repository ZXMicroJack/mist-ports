
module ql_neptuno2_top(
  input wire CLOCK_50,

  output wire [7:0] VGA_R,
  output wire [7:0] VGA_G,
  output wire [7:0] VGA_B,
  output wire VGA_HS,
  output wire VGA_VS,

  inout wire SPI_DO,
  input wire SPI_DI,
  input wire SPI_SCK,
  input wire CONF_DATA0,
  input wire SPI_SS2,
  input wire SPI_SS3,
  input wire SPI_SS4,
  output wire SDRAM_CLK,
  output wire SDRAM_CKE,
  output wire SDRAM_DQMH,
  output wire SDRAM_DQML,
  output wire SDRAM_nCAS,
  output wire SDRAM_nRAS,
  output wire SDRAM_nWE,
  output wire SDRAM_nCS,
  output wire[1:0] SDRAM_BA,
  output wire[12:0] SDRAM_A,
  inout wire[15:0] SDRAM_DQ,
  output wire I2SL,
  output wire I2SC,
  output wire I2SD,
  output wire AUDIO_L,
  output wire AUDIO_R,

  output wire LED,

  input wire EAR,

  // forward JAMMA DB9 data
  output wire JOY_CLK,
  input wire XJOY_CLK,
  output wire JOY_LOAD_N,
  input wire XJOY_LOAD_N,
  input wire JOY_DATA,
  output wire XJOY_DATA
);

assign VGA_R[1:0] = 2'b00;
assign VGA_G[1:0] = 2'b00;
assign VGA_B[1:0] = 2'b00;

ql ql_inst(
   .CLOCK_27(CLOCK_50),
   .SPI_DO(SPI_DO),
   .SPI_DI(SPI_DI),
   .SPI_SCK(SPI_SCK),
   .CONF_DATA0(CONF_DATA0),
   .SPI_SS2(SPI_SS2),
   .SPI_SS3(SPI_SS3),
	 .SPI_SS4(SPI_SS4),
   .VGA_HS(VGA_HS),
   .VGA_VS(VGA_VS),
   .VGA_R(VGA_R[7:2]),
   .VGA_G(VGA_G[7:2]),
   .VGA_B(VGA_B[7:2]),
   .LED(LED),
   .SDRAM_A(SDRAM_A), //std_logic_vector(12 downto 0)
   .SDRAM_DQ(SDRAM_DQ),  // std_logic_vector(15 downto 0);
   .SDRAM_DQML(SDRAM_DQML), // out
   .SDRAM_DQMH(SDRAM_DQMH), // out
   .SDRAM_nWE(SDRAM_nWE), //	:  out 		std_logic;
   .SDRAM_nCAS(SDRAM_nCAS), //	:  out 		std_logic;
   .SDRAM_nRAS(SDRAM_nRAS), //	:  out 		std_logic;
   .SDRAM_nCS(SDRAM_nCS), //	:  out 		std_logic;
   .SDRAM_BA(SDRAM_BA), //		:  out 		std_logic_vector(1 downto 0);
   .SDRAM_CLK(SDRAM_CLK), //	:  out 		std_logic;
   .SDRAM_CKE(SDRAM_CKE), //	:  out 		std_logic;
   .AUDIO_L(AUDIO_L),
   .AUDIO_R(AUDIO_R) //,
   //.I2S_BCK(I2SC),
   //.I2S_LRCK(I2SL),
   //.I2S_DATA(I2SD),
   //.AUDIO_IN(EAR),
   //.UART_RX(1'b1),
   //.UART_TX()
);

// JAMMA interface
assign JOY_CLK = XJOY_CLK;
assign JOY_LOAD_N = XJOY_LOAD_N;
assign XJOY_DATA = JOY_DATA;


endmodule


module pll_rtc(
  input wire inclk0,
  output wire c0);

  reg[9:0] counter;
  reg c0out;

  assign c0 = c0out;

  always @(posedge inclk0) begin
      if (counter[9:0] == 10'h2FB) begin
         counter <= 10'd0;
         c0out = 1'b0;
      end else if (counter[9:0] == 10'h17d) begin
         counter <= counter + 1;
         c0out = 1'b1;
      end else begin
         counter <= counter + 1;
      end
   end
endmodule
