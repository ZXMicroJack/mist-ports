`default_nettype wire
module zx3top(
  input wire clk50mhz,

  // VGA
  output wire [7:0] vga_r,
  output wire [7:0] vga_g,
  output wire [7:0] vga_b,
  output wire vga_hs,
  output wire vga_vs,

  // MiST control
  inout wire mist_miso,
  input wire mist_mosi,
  input wire mist_sck,
  input wire mist_confdata0,
  input wire mist_ss2,
  input wire mist_ss3,
  input wire mist_ss4,

  // SDRAM
  output wire sdram_clk,
  output wire sdram_cke,
  output wire sdram_dqmh_n,
  output wire sdram_dqml_n,
  output wire sdram_cas_n,
  output wire sdram_ras_n,
  output wire sdram_we_n,
  output wire sdram_cs_n,
  output wire[1:0] sdram_ba,
  output wire[12:0] sdram_addr,
  inout wire[15:0] sdram_dq,

  // MISC
  output wire testled,

  // AUDIO
  output wire audio_out_left,
  output wire audio_out_right,
  output wire i2s_bclk,
  output wire i2s_lrclk,
  output wire i2s_dout,

  // DB9 data
  output wire joy_clk,
  input wire xjoy_clk,
  output wire joy_load_n,
  input wire xjoy_load_n,
  input wire joy_data,
  output wire xjoy_data,
  output wire joy_select,

  // MIDI in
   output wire midi_out,
   input wire midi_clkbd,
   input wire midi_dabd
);

// JAMMA interface
reg joy_select_ = 1'b1;
assign joy_clk = xjoy_clk;
assign joy_load_n = xjoy_load_n;
assign xjoy_data = joy_data;
assign joy_select = joy_select_;

always @(posedge xjoy_load_n) begin
	joy_select_ <= ~joy_select_ | ~xjoy_clk;
end

wire[15:0] audio_l;
wire[15:0] audio_r;
wire clock50;

wire[15:0] midi_audio_l;
wire[15:0] midi_audio_r;

zxspectrum spectrum_mist_inst(
   .CLOCK_27({clk50mhz, clk50mhz}),
   .SPI_DO(mist_miso),
   .SPI_DI(mist_mosi),
   .SPI_SCK(mist_sck),
   .CONF_DATA0(mist_confdata0),
   .SPI_SS2(mist_ss2),
   .SPI_SS3(mist_ss3),
//	 .SPI_SS4(mist_ss4),
   .VGA_HS(vga_hs),
   .VGA_VS(vga_vs),
   .VGA_R(vga_r[7:2]),
   .VGA_G(vga_g[7:2]),
   .VGA_B(vga_b[7:2]),
   .LED(testled),
   .SDRAM_A(sdram_addr), //std_logic_vector(12 downto 0)
   .SDRAM_DQ(sdram_dq),  // std_logic_vector(15 downto 0);
   .SDRAM_DQML(sdram_dqml_n), // out
   .SDRAM_DQMH(sdram_dqmh_n), // out
   .SDRAM_nWE(sdram_we_n), //	:  out 		std_logic;
   .SDRAM_nCAS(sdram_cas_n), //	:  out 		std_logic;
   .SDRAM_nRAS(sdram_ras_n), //	:  out 		std_logic;
   .SDRAM_nCS(sdram_cs_n), //	:  out 		std_logic;
   .SDRAM_BA(sdram_ba), //		:  out 		std_logic_vector(1 downto 0);
   .SDRAM_CLK(sdram_clk), //	:  out 		std_logic;
   .SDRAM_CKE(sdram_cke), //	:  out 		std_logic;
   .AUDIO_LEFT(audio_l),
   .AUDIO_RIGHT(audio_r),
   .AUDIO_L(audio_out_left),
   .AUDIO_R(audio_out_right),
   .clock50(clock50),
   .MIDI_OUT(midi_out),
   .AUDIO_LEFT_IN(midi_audio_l),
   .AUDIO_RIGHT_IN(midi_audio_r)
);

i2s_sound #(.CLKMHZ(50)) i2scodec (
    .clk(clock50),
    .audio_l(audio_l),
    .audio_r(audio_r),
    .i2s_bclk(i2s_bclk),
    .i2s_lrclk(i2s_lrclk),
    .i2s_dout(i2s_dout)
  );

i2s_decoder (
    .clk(clock50),
    .sck(midi_clkbd),
    .ws(),
    .sd(midi_dabd),
    .left_out(midi_audio_l),
    .right_out(midi_audio_r)
  );

endmodule
