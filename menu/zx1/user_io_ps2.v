module user_io_ps2 (
	clk_sys,
	ps2_clk,
	ps2_clk_i,
	ps2_clk_o,
	ps2_data_i,
	ps2_data_o,
	ps2_tx_strobe,
	ps2_tx_byte,
	ps2_rx_strobe,
	ps2_rx_byte,
	ps2_fifo_ready
);
	input clk_sys;
	input ps2_clk;
	input ps2_clk_i;
	output wire ps2_clk_o;
	input ps2_data_i;
	output reg ps2_data_o = 1;
	input ps2_tx_strobe;
	input [7:0] ps2_tx_byte;
	output reg ps2_rx_strobe = 0;
	output reg [7:0] ps2_rx_byte = 0;
	output wire ps2_fifo_ready;
	parameter PS2_FIFO_BITS = 4;
	parameter PS2_BIDIR = 0;
	reg [7:0] ps2_fifo [(2 ** PS2_FIFO_BITS) - 1:0];
	reg [PS2_FIFO_BITS - 1:0] ps2_wptr;
	reg [PS2_FIFO_BITS - 1:0] ps2_rptr;
	wire [PS2_FIFO_BITS:0] ps2_used = (ps2_wptr >= ps2_rptr ? ps2_wptr - ps2_rptr : (ps2_wptr - ps2_rptr) + (2'd2 ** PS2_FIFO_BITS));
	wire [PS2_FIFO_BITS:0] ps2_free = (2'd2 ** PS2_FIFO_BITS) - ps2_used;
	assign ps2_fifo_ready = ps2_free[PS2_FIFO_BITS:2] != 0;
	reg [3:0] ps2_tx_state;
	reg [7:0] ps2_tx_shift_reg;
	reg ps2_parity;
	reg [3:0] ps2_rx_state = 0;
	reg [1:0] ps2_rx_start = 0;
	assign ps2_clk_o = ps2_clk || ((ps2_tx_state == 0) && (ps2_rx_state == 0));
	always @(posedge clk_sys) begin : ps2_fifo_wr
		if (ps2_tx_strobe) begin
			ps2_fifo[ps2_wptr] <= ps2_tx_byte;
			ps2_wptr <= ps2_wptr + 1'd1;
		end
	end
	always @(posedge clk_sys) begin : ps2_txrx
		reg ps2_clkD;
		reg ps2_clk_iD;
		reg ps2_dat_iD;
		reg ps2_r_inc;
		ps2_clkD <= ps2_clk;
		if (~ps2_clkD & ps2_clk) begin
			ps2_r_inc <= 1'b0;
			if (ps2_r_inc)
				ps2_rptr <= ps2_rptr + 1'd1;
			if (ps2_tx_state == 0) begin
				ps2_data_o <= 1;
				if ((ps2_wptr != ps2_rptr) && (ps2_clk_i | !PS2_BIDIR)) begin
					ps2_tx_shift_reg <= ps2_fifo[ps2_rptr];
					ps2_r_inc <= 1'b1;
					ps2_parity <= 1'b1;
					ps2_tx_state <= 4'd1;
					ps2_data_o <= 1'b0;
				end
			end
			else begin
				if ((ps2_tx_state >= 1) && (ps2_tx_state < 9)) begin
					ps2_data_o <= ps2_tx_shift_reg[0];
					ps2_tx_shift_reg[6:0] <= ps2_tx_shift_reg[7:1];
					if (ps2_tx_shift_reg[0])
						ps2_parity <= !ps2_parity;
				end
				if (ps2_tx_state == 9)
					ps2_data_o <= ps2_parity;
				if (ps2_tx_state == 10)
					ps2_data_o <= 1'b1;
				if (ps2_tx_state == 11)
					ps2_tx_state <= 4'd0;
				else
					ps2_tx_state <= ps2_tx_state + 4'd1;
			end
		end
		if (PS2_BIDIR) begin
			ps2_clk_iD <= ps2_clk_i;
			ps2_dat_iD <= ps2_data_i;
			case (ps2_rx_start)
				2'd0:
					if (ps2_clk_iD & ~ps2_clk_i)
						ps2_rx_start <= 1;
				2'd1:
					if (ps2_dat_iD && !ps2_data_i)
						ps2_rx_start <= 2'd2;
					else if (ps2_clk_i)
						ps2_rx_start <= 0;
				2'd2:
					if (ps2_clkD && ~ps2_clk) begin
						ps2_rx_state <= 4'd1;
						ps2_rx_start <= 0;
					end
				default:
					;
			endcase
			if (((ps2_rx_state != 0) && ~ps2_clkD) && ps2_clk) begin
				ps2_rx_state <= ps2_rx_state + 1'd1;
				if (ps2_rx_state == 9)
					;
				else if (ps2_rx_state == 10)
					ps2_data_o <= 0;
				else if (ps2_rx_state == 11) begin
					ps2_rx_state <= 0;
					ps2_rx_strobe <= ~ps2_rx_strobe;
				end
				else
					ps2_rx_byte <= {ps2_data_i, ps2_rx_byte[7:1]};
			end
		end
		else begin
			ps2_rx_byte <= 0;
			ps2_rx_strobe <= 0;
		end
	end
endmodule
