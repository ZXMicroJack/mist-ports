---------------------------------------------------------------------------------
-- TZX player
-- by György Szombathelyi
-- basic idea for the structure based on c1530 tap player by darfpga
--
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

entity tzxplayer is
generic (
	TZX_MS : integer := 64000;       -- CE periods for one milliseconds
	-- Default: ZX Spectrum
	NORMAL_PILOT_LEN    : integer := 2168;
	NORMAL_SYNC1_LEN    : integer := 667;
	NORMAL_SYNC2_LEN    : integer := 735;
	NORMAL_ZERO_LEN     : integer := 855;
	NORMAL_ONE_LEN      : integer := 1710;
	HEADER_PILOT_PULSES : integer := 8063; -- this is the header length
	NORMAL_PILOT_PULSES : integer := 3223  -- this is the non-header length

	-- Amstrad CPC
	--NORMAL_PILOT_LEN    : integer := 2000;
	--NORMAL_SYNC1_LEN    : integer := 855;
	--NORMAL_SYNC2_LEN    : integer := 855;
	--NORMAL_ZERO_LEN     : integer := 855;
	--NORMAL_ONE_LEN      : integer := 1710;
	--HEADER_PILOT_PULSES : integer := 4095; -- no difference between header and data pilot lengths
	--NORMAL_PILOT_PULSES : integer := 4095
);
port(
	clk             : in std_logic;
	ce              : in std_logic;
	restart_tape    : in std_logic;

	host_tap_in     : in unsigned(7 downto 0);          -- 8bits fifo input
	tzx_req         : buffer std_logic;                 -- request for new byte (edge trigger)
	tzx_ack         : in std_logic;                     -- new data available
	loop_start      : out std_logic;                    -- active for one clock if a loop starts
	loop_next       : out std_logic;                    -- active for one clock at the next iteration
	stop            : out std_logic;                    -- tape should be stopped
	stop48k         : out std_logic;                    -- tape should be stopped in 48k mode
	cass_read       : out std_logic;                    -- tape read signal
	cass_motor      : in  std_logic;                    -- 1 = tape motor is powered
	cass_running    : out std_logic                     -- tape is running
);
end tzxplayer;

architecture struct of tzxplayer is

signal tap_fifo_do    : unsigned( 7 downto 0);
signal tick_cnt       : unsigned(16 downto 0);
signal wave_cnt       : unsigned(23 downto 0);
signal wave_period    : std_logic;
signal wave_inverted  : std_logic;
signal skip_bytes     : std_logic;
signal playing        : std_logic;  -- 1 = tap or wav file is playing
signal bit_cnt        : unsigned(2 downto 0);

type tzx_state_t is (
	TZX_HEADER,
	TZX_NEWBLOCK,
	TZX_LOOP_START,
	TZX_LOOP_END,
	TZX_PAUSE,
	TZX_PAUSE2,
	TZX_STOP48K,
	TZX_HWTYPE,
	TZX_TEXT,
	TZX_MESSAGE,
	TZX_ARCHIVE_INFO,
	TZX_CUSTOM_INFO,
	TZX_GLUE,
	TZX_TONE,
	TZX_PULSES,
	TZX_DATA,
	TZX_NORMAL,
	TZX_TURBO,
	TZX_PLAY_TONE,
	TZX_PLAY_SYNC1,
	TZX_PLAY_SYNC2,
	TZX_PLAY_TAPBLOCK,
	TZX_PLAY_TAPBLOCK2,
	TZX_PLAY_TAPBLOCK3,
	TZX_PLAY_TAPBLOCK4,
	TZX_DIRECT,
	TZX_DIRECT2,
	TZX_DIRECT3);

signal tzx_state: tzx_state_t;

signal tzx_offset     : unsigned( 7 downto 0);
signal pause_len      : unsigned(15 downto 0);
signal ms_counter     : unsigned(15 downto 0);
signal pilot_l        : unsigned(15 downto 0);
signal sync1_l        : unsigned(15 downto 0);
signal sync2_l        : unsigned(15 downto 0);
signal zero_l         : unsigned(15 downto 0);
signal one_l          : unsigned(15 downto 0);
signal pilot_pulses   : unsigned(15 downto 0);
signal last_byte_bits : unsigned( 3 downto 0);
signal data_len       : unsigned(23 downto 0);
signal pulse_len      : unsigned(15 downto 0);
signal end_period     : std_logic;
signal cass_motor_D   : std_logic;
signal motor_counter  : unsigned(21 downto 0);
signal loop_iter      : unsigned(15 downto 0);
signal data_len_dword : unsigned(31 downto 0);

begin

cass_read <= wave_period;
cass_running <= playing;
tap_fifo_do <= host_tap_in;

process(clk)
begin
  if rising_edge(clk) then
	if restart_tape = '1' then

		tzx_offset <= (others => '0');
		tzx_state <= TZX_HEADER;
		pulse_len <= (others => '0');
		motor_counter <= (others => '0');
		wave_period <= '0';
		playing <= '0';
		tzx_req <= tzx_ack;
		loop_start <= '0';
		loop_next <= '0';
		loop_iter <= (others => '0');
		wave_inverted <= '0';
	else

		-- simulate tape motor momentum
		-- don't change the playing state if the motor is switched in 50 ms
		-- Opera Soft K17 protection needs this!
		cass_motor_D <= cass_motor;
		if cass_motor_D /= cass_motor then
			motor_counter <= to_unsigned(50*TZX_MS, motor_counter'length);
		elsif motor_counter /= 0 then
			if ce = '1' then motor_counter <= motor_counter - 1; end if;
		else
			playing <= cass_motor;
		end if;

		if playing = '0' then
			--cass_read <= '1';
		end if;	

		if pulse_len /= 0 then
			if ce = '1' then
				tick_cnt <= tick_cnt + 3500;
				if tick_cnt >= (TZX_MS - 3500) then
					tick_cnt <= tick_cnt + 3500 - TZX_MS;
					wave_cnt <= wave_cnt + 1;
					if wave_cnt = pulse_len - 1 then
						wave_cnt <= (others => '0');
						if wave_period = end_period then
							pulse_len <= (others => '0');
						else
							wave_period <= not wave_period;
						end if;
					end if;
				end if;
			end if;
		else
			wave_cnt <= (others => '0');
			tick_cnt <= (others => '0');
		end if;

		loop_start <= '0';
		loop_next  <= '0';
		stop       <= '0';
		stop48k    <= '0';

		if playing = '1' and pulse_len = 0 and tzx_req = tzx_ack then

			tzx_req <= not tzx_ack; -- default request for new data

			case tzx_state is
			when TZX_HEADER =>
				wave_period <= '1';
				wave_inverted <= '0';
				tzx_offset <= tzx_offset + 1;
				if tzx_offset = x"0A" then -- skip 9 bytes, offset lags 1
					tzx_state <= TZX_NEWBLOCK;
				end if;

			when TZX_NEWBLOCK =>
				tzx_offset <= (others=>'0');
				ms_counter <= (others=>'0');
				case tap_fifo_do is
					when x"10" => tzx_state <= TZX_NORMAL;
					when x"11" => tzx_state <= TZX_TURBO;
					when x"12" => tzx_state <= TZX_TONE;
					when x"13" => tzx_state <= TZX_PULSES;
					when x"14" => tzx_state <= TZX_DATA;
					when x"15" => tzx_state <= TZX_DIRECT;
					when x"18" => null; -- CSW recording (not implemented)
					when x"19" => null; -- Generalized data block (not implemented)
					when x"20" => tzx_state <= TZX_PAUSE;
					when x"21" => tzx_state <= TZX_TEXT; -- Group start
					when x"22" => null; -- Group end
					when x"23" => null; -- Jump to block (not implemented)
					when x"24" => tzx_state <= TZX_LOOP_START;
					when x"25" => tzx_state <= TZX_LOOP_END;
					when x"26" => null; -- Call sequence (not implemented)
					when x"27" => null; -- Return from sequence (not implemented)
					when x"28" => null; -- Select block (not implemented)
					when x"2A" => tzx_state <= TZX_STOP48K;
					when x"2B" => null; -- Set signal level (not implemented)
					when x"30" => tzx_state <= TZX_TEXT;
					when x"31" => tzx_state <= TZX_MESSAGE;
					when x"32" => tzx_state <= TZX_ARCHIVE_INFO;
					when x"33" => tzx_state <= TZX_HWTYPE;
					when x"35" => tzx_state <= TZX_CUSTOM_INFO;
					when x"5A" => tzx_state <= TZX_GLUE;
					when others => null;
				end case;

			when TZX_LOOP_START =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then loop_iter( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then
					loop_iter(15 downto  8) <= tap_fifo_do;
					tzx_state <= TZX_NEWBLOCK;
					loop_start <= '1';
				end if;

			when TZX_LOOP_END =>
				if loop_iter > 1 then
					loop_iter <= loop_iter - 1;
					loop_next <= '1';
				else
					tzx_req <= tzx_ack; -- don't request new byte
				end if;
				tzx_state <= TZX_NEWBLOCK;

			when TZX_PAUSE =>
				tzx_offset <= tzx_offset + 1;
				if tzx_offset = x"00" then 
					pause_len(7 downto 0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then
					pause_len(15 downto 8) <= tap_fifo_do;
					tzx_state <= TZX_PAUSE2;
					if pause_len(7 downto 0) = 0 and tap_fifo_do = 0 then
						stop <= '1';
					end if;
				end if;

			when TZX_PAUSE2 =>
				tzx_req <= tzx_ack; -- don't request new byte
				if ms_counter /= 0 then
					if ce = '1' then
						ms_counter <= ms_counter - 1;
						-- Set pulse level to low after 1 ms
						if ms_counter = 1 then
							wave_inverted <= '0';
							wave_period <= '0';
							end_period <= '0';
						end if;
					end if;
				elsif pause_len /= 0 then
					pause_len <= pause_len - 1;
					ms_counter <= to_unsigned(TZX_MS, ms_counter'length);
				else
					tzx_state <= TZX_NEWBLOCK;
				end if;

			when TZX_STOP48K =>
				tzx_offset <= tzx_offset + 1;
				if tzx_offset = x"03" then
					stop48k <= '1';
					tzx_state <= TZX_NEWBLOCK;
				end if;

			when TZX_HWTYPE =>
				tzx_offset <= tzx_offset + 1;
				-- 0, 1-3, 1-3, ...
				if    tzx_offset = x"00" then data_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then
					if data_len(7 downto 0) = x"01" then
						tzx_state <= TZX_NEWBLOCK;
					else
						data_len(7 downto 0) <= data_len(7 downto 0) - 1;
						tzx_offset <= x"01";
					end if;
				end if;

			when TZX_MESSAGE =>
				-- skip display time, then then same as TEXT DESRCRIPTION
				tzx_state <= TZX_TEXT;

			when TZX_TEXT =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then data_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = data_len(7 downto 0) then
						tzx_state <= TZX_NEWBLOCK;
				end if;

			when TZX_ARCHIVE_INFO =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then data_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then data_len(15 downto  8) <= tap_fifo_do;
				else
					tzx_offset <= x"02";
					data_len <= data_len - 1;
					if data_len = 1 then
						tzx_state <= TZX_NEWBLOCK;
					end if;
				end if;

			when TZX_CUSTOM_INFO =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"10" then data_len_dword( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"11" then data_len_dword(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"12" then data_len_dword(23 downto 16) <= tap_fifo_do;
				elsif tzx_offset = x"13" then data_len_dword(31 downto 24) <= tap_fifo_do;
				elsif tzx_offset = x"14" then
					tzx_offset <= x"14";
					if data_len_dword = 1 then
						tzx_state <= TZX_NEWBLOCK;
					else
						data_len_dword <= data_len_dword - 1;
					end if;
				end if;

			when TZX_GLUE =>
				tzx_offset <= tzx_offset + 1;
				if tzx_offset = x"08" then
					tzx_state <= TZX_NEWBLOCK;
				end if;

			when TZX_TONE =>
				tzx_offset <= tzx_offset + 1;
				-- 0, 1, 2, 3, 4, 4, 4, ...
				if    tzx_offset = x"00" then pilot_l( 7 downto 0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then pilot_l(15 downto 8) <= tap_fifo_do;
				elsif tzx_offset = x"02" then pilot_pulses( 7 downto 0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then
					tzx_req <= tzx_ack; -- don't request new byte
					pilot_pulses(15 downto 8) <= tap_fifo_do;
				else
					tzx_offset <= x"04";
					tzx_req <= tzx_ack; -- don't request new byte
					if pilot_pulses = 0 then
						tzx_req <= not tzx_ack; -- default request for new data
						tzx_state <= TZX_NEWBLOCK;
					else
						pilot_pulses <= pilot_pulses - 1;
						if wave_inverted = '0' then
							wave_period <= not wave_period;
							end_period <= not wave_period; -- request pulse
						else
							wave_inverted <= '0';
							end_period <= wave_period;
						end if;
						pulse_len <= pilot_l;
					end if;
				end if;

			when TZX_PULSES =>
				tzx_offset <= tzx_offset + 1;
				-- 0, 1-2+3, 1-2+3, ...
				if    tzx_offset = x"00" then data_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then one_l( 7 downto 0) <= tap_fifo_do;
				elsif tzx_offset = x"02" then
					tzx_req <= tzx_ack; -- don't request new byte
						if wave_inverted = '0' then
							wave_period <= not wave_period;
							end_period <= not wave_period; -- request pulse
						else
							wave_inverted <= '0';
							end_period <= wave_period;
						end if;
					pulse_len <= tap_fifo_do & one_l( 7 downto 0);
				elsif tzx_offset = x"03" then
					if data_len(7 downto 0) = x"01" then
						tzx_state <= TZX_NEWBLOCK;
					else
						data_len(7 downto 0) <= data_len(7 downto 0) - 1;
						tzx_offset <= x"01";
					end if;
				end if;

			when TZX_DATA =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then zero_l ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then zero_l (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"02" then one_l  ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then one_l  (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"04" then last_byte_bits <= tap_fifo_do(3 downto 0);
				elsif tzx_offset = x"05" then pause_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"06" then pause_len(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"07" then data_len ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"08" then data_len (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"09" then
					data_len (23 downto 16) <= tap_fifo_do;
					tzx_state <= TZX_PLAY_TAPBLOCK;
				end if;

			when TZX_NORMAL =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then pause_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then pause_len(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"02" then data_len ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then
					data_len(15 downto  8) <= tap_fifo_do;
					data_len(23 downto 16) <= (others => '0');
				elsif tzx_offset = x"04" then
					-- this is the first data byte to determine if it's a header or data block (on Speccy)
					tzx_req <= tzx_ack; -- don't request new byte
					pilot_l <= to_unsigned(NORMAL_PILOT_LEN, pilot_l'length);
					sync1_l <= to_unsigned(NORMAL_SYNC1_LEN, sync1_l'length);
					sync2_l <= to_unsigned(NORMAL_SYNC2_LEN, sync2_l'length);
					zero_l  <= to_unsigned(NORMAL_ZERO_LEN,  zero_l'length);
					one_l   <= to_unsigned(NORMAL_ONE_LEN,   one_l'length);
					if tap_fifo_do = 0 then
						pilot_pulses <= to_unsigned(HEADER_PILOT_PULSES, pilot_pulses'length);
					else
						pilot_pulses <= to_unsigned(NORMAL_PILOT_PULSES, pilot_pulses'length);
					end if;
					last_byte_bits <= "1000";
					tzx_state <= TZX_PLAY_TONE;
				end if;

			when TZX_TURBO =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then pilot_l( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"01" then pilot_l(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"02" then sync1_l( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then sync1_l(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"04" then sync2_l( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"05" then sync2_l(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"06" then zero_l ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"07" then zero_l (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"08" then one_l  ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"09" then one_l  (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"0A" then pilot_pulses( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"0B" then pilot_pulses(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"0C" then last_byte_bits <= tap_fifo_do(3 downto 0);
				elsif tzx_offset = x"0D" then pause_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"0E" then pause_len(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"0F" then data_len ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"10" then data_len (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"11" then
					data_len (23 downto 16) <= tap_fifo_do;
					tzx_state <= TZX_PLAY_TONE;
				end if;

			when TZX_PLAY_TONE =>
				tzx_req <= tzx_ack; -- don't request new byte
				if wave_inverted = '0' then
					wave_period <= not wave_period;
					end_period <= not wave_period; -- request pulse
				else
					end_period <= wave_period;
					wave_inverted <= '0';
				end if;
				pulse_len <= pilot_l;
				if pilot_pulses = 1 then
					tzx_state <= TZX_PLAY_SYNC1;
				else
					pilot_pulses <= pilot_pulses - 1;
				end if;

			when TZX_PLAY_SYNC1 =>
				tzx_req <= tzx_ack; -- don't request new byte
				wave_period <= not wave_period;
				end_period <= not wave_period; -- request pulse
				pulse_len <= sync1_l;
				tzx_state <= TZX_PLAY_SYNC2;

			when TZX_PLAY_SYNC2 =>
				tzx_req <= tzx_ack; -- don't request new byte
				wave_period <= not wave_period;
				end_period <= not wave_period; -- request pulse
				pulse_len <= sync2_l;
				tzx_state <= TZX_PLAY_TAPBLOCK;

			when TZX_PLAY_TAPBLOCK =>
				tzx_req <= tzx_ack; -- don't request new byte
				bit_cnt <= "111";
				tzx_state <= TZX_PLAY_TAPBLOCK2;

			when TZX_PLAY_TAPBLOCK2 =>
				tzx_req <= tzx_ack; -- don't request new byte
				bit_cnt <= bit_cnt - 1;
				if bit_cnt = "000" or (data_len = 1 and ((bit_cnt = (8 - last_byte_bits)) or (last_byte_bits = 0))) then
					data_len <= data_len - 1;
					tzx_state <= TZX_PLAY_TAPBLOCK3;
				end if;
				if wave_inverted = '0' then
					wave_period <= not wave_period;
					end_period <= wave_period; -- request full period
				else
					end_period <= not wave_period;
					wave_inverted <= '0';
				end if;
				if tap_fifo_do(to_integer(bit_cnt)) = '0' then
					pulse_len <= zero_l;
				else
					pulse_len <= one_l;
				end if;

			when TZX_PLAY_TAPBLOCK3 =>
				if data_len = 0 then
					wave_period <= not wave_period;
					wave_inverted <= '1';
					tzx_state <= TZX_PAUSE2;
				else
					tzx_state <= TZX_PLAY_TAPBLOCK4;
				end if;

			when TZX_PLAY_TAPBLOCK4 =>
				tzx_req <= tzx_ack; -- don't request new byte
				tzx_state <= TZX_PLAY_TAPBLOCK2;

			when TZX_DIRECT =>
				tzx_offset <= tzx_offset + 1;
				if    tzx_offset = x"00" then zero_l    ( 7 downto  0) <= tap_fifo_do; -- here this is used for one bit, too
				elsif tzx_offset = x"01" then zero_l    (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"02" then pause_len ( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"03" then pause_len (15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"04" then last_byte_bits <= tap_fifo_do(3 downto 0);
				elsif tzx_offset = x"05" then data_len( 7 downto  0) <= tap_fifo_do;
				elsif tzx_offset = x"06" then data_len(15 downto  8) <= tap_fifo_do;
				elsif tzx_offset = x"07" then 
					data_len(23 downto 16) <= tap_fifo_do;
					tzx_state <= TZX_DIRECT2;
					bit_cnt <= "111";
				end if;

			when TZX_DIRECT2 =>
				tzx_req <= tzx_ack; -- don't request new byte
				bit_cnt <= bit_cnt - 1;
				if bit_cnt = "000" or (data_len = 1 and ((bit_cnt = (8 - last_byte_bits)) or (last_byte_bits = 0))) then
					data_len <= data_len - 1;
					tzx_state <= TZX_DIRECT3;
				end if;

				pulse_len <= zero_l;
				wave_period <= tap_fifo_do(to_integer(bit_cnt));
				end_period <= tap_fifo_do(to_integer(bit_cnt));

			when TZX_DIRECT3 =>
				if data_len = 0 then
					wave_inverted <= '0';
					tzx_state <= TZX_PAUSE2;
				else
					tzx_state <= TZX_DIRECT2;
				end if;

			when others => null;
			end case;

		end if; -- play tzx

	end if;
  end if; -- clk
end process;

end struct;
