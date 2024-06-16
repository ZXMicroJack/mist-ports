module sdram (
	SDRAM_DQ,
	SDRAM_A,
	SDRAM_DQML,
	SDRAM_DQMH,
	SDRAM_BA,
	SDRAM_nCS,
	SDRAM_nWE,
	SDRAM_nRAS,
	SDRAM_nCAS,
	init_n,
	clk,
	clkref,
	port1_req,
	port1_ack,
	port1_we,
	port1_a,
	port1_ds,
	port1_d,
	port1_q,
	port2_req,
	port2_ack,
	port2_we,
	port2_a,
	port2_ds,
	port2_d,
	port2_q
);
	inout [15:0] SDRAM_DQ;
	output reg [12:0] SDRAM_A;
	output reg SDRAM_DQML;
	output reg SDRAM_DQMH;
	output reg [1:0] SDRAM_BA;
	output wire SDRAM_nCS;
	output wire SDRAM_nWE;
	output wire SDRAM_nRAS;
	output wire SDRAM_nCAS;
	input init_n;
	input clk;
	input clkref;
	input port1_req;
	output wire port1_ack;
	input port1_we;
	input [23:1] port1_a;
	input [1:0] port1_ds;
	input [15:0] port1_d;
	output wire [15:0] port1_q;
	input port2_req;
	output wire port2_ack;
	input port2_we;
	input [23:1] port2_a;
	input [1:0] port2_ds;
	input [15:0] port2_d;
	output wire [15:0] port2_q;
	localparam RASCAS_DELAY = 3'd3;
	localparam BURST_LENGTH = 3'b000;
	localparam ACCESS_TYPE = 1'b0;
	localparam CAS_LATENCY = 3'd3;
	localparam OP_MODE = 2'b00;
	localparam NO_WRITE_BURST = 1'b1;
	localparam MODE = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};
	localparam RFRSH_CYCLES = 10'd842;
	localparam STATE_RAS0 = 3'd0;
	localparam STATE_RAS1 = 3'd2;
	localparam STATE_CAS0 = STATE_RAS0 + RASCAS_DELAY;
	localparam STATE_DS0 = (STATE_RAS0 + RASCAS_DELAY) + 1'd1;
	localparam STATE_CAS1 = STATE_RAS1 + RASCAS_DELAY;
	localparam STATE_DS1 = (STATE_RAS1 + RASCAS_DELAY) + 1'd1;
	localparam STATE_READ0 = 3'd0;
	localparam STATE_READ1 = 3'd1 + 3'd1;
	localparam STATE_LAST = 3'd7;
	reg [2:0] t;
	always @(posedge clk) begin
		t <= t + 1'd1;
		if (t == STATE_LAST)
			t <= STATE_RAS0;
		if (clkref)
			t <= 3'd6;
	end
	reg [4:0] reset;
	reg init = 1'b1;
	always @(posedge clk or negedge init_n)
		if (!init_n) begin
			reset <= 5'h1f;
			init <= 1'b1;
		end
		else begin
			if ((t == STATE_LAST) && (reset != 0))
				reset <= reset - 5'd1;
			init <= reset != 0;
		end
	localparam CMD_INHIBIT = 4'b1111;
	localparam CMD_NOP = 4'b0111;
	localparam CMD_ACTIVE = 4'b0011;
	localparam CMD_READ = 4'b0101;
	localparam CMD_WRITE = 4'b0100;
	localparam CMD_BURST_TERMINATE = 4'b0110;
	localparam CMD_PRECHARGE = 4'b0010;
	localparam CMD_AUTO_REFRESH = 4'b0001;
	localparam CMD_LOAD_MODE = 4'b0000;
	reg [3:0] sd_cmd;
	reg [15:0] sd_din;
	assign SDRAM_nCS = sd_cmd[3];
	assign SDRAM_nRAS = sd_cmd[2];
	assign SDRAM_nCAS = sd_cmd[1];
	assign SDRAM_nWE = sd_cmd[0];
	reg [15:0] SDRAM_DQr;
	reg [24:1] addr_latch [0:1];
	reg [24:1] addr_latch_next [0:1];
	reg [15:0] din_latch [0:1];
	reg [1:0] oe_latch;
	reg [1:0] we_latch;
	reg [1:0] ds [0:1];
	reg [1:0] state;
	assign SDRAM_DQ = (sd_cmd[0] ? 16'hzzzz : SDRAM_DQr);
	localparam PORT_NONE = 1'd0;
	localparam PORT_REQ = 1'd1;
	reg [1:0] next_port;
	reg [1:0] port;
	reg port1_ack_reg;
	reg [15:0] port1_q_reg;
	reg port2_ack_reg;
	reg [15:0] port2_q_reg;
	reg refresh;
	reg [10:0] refresh_cnt;
	wire need_refresh = refresh_cnt >= RFRSH_CYCLES;
	always @(*)
		if (refresh) begin
			next_port[0] = PORT_NONE;
			addr_latch_next[0] = addr_latch[0];
		end
		else if (port1_req ^ state[0]) begin
			next_port[0] = PORT_REQ;
			addr_latch_next[0] = {1'b0, port1_a};
		end
		else begin
			next_port[0] = PORT_NONE;
			addr_latch_next[0] = addr_latch[0];
		end
	always @(*)
		if (port2_req ^ state[1]) begin
			next_port[1] = PORT_REQ;
			addr_latch_next[1] = {1'b1, port2_a};
		end
		else begin
			next_port[1] = PORT_NONE;
			addr_latch_next[1] = addr_latch[1];
		end
	always @(posedge clk) begin
		sd_din <= SDRAM_DQ;
		{SDRAM_DQMH, SDRAM_DQML} <= 2'b11;
		sd_cmd <= CMD_NOP;
		refresh_cnt <= refresh_cnt + 1'd1;
		if (init) begin
			if (t == STATE_RAS0) begin
				if (reset == 15) begin
					sd_cmd <= CMD_PRECHARGE;
					SDRAM_A[10] <= 1'b1;
				end
				if ((reset == 10) || (reset == 8))
					sd_cmd <= CMD_AUTO_REFRESH;
				if (reset == 2) begin
					sd_cmd <= CMD_LOAD_MODE;
					SDRAM_A <= MODE;
					SDRAM_BA <= 2'b00;
				end
			end
		end
		else begin
			if (t == STATE_RAS0) begin
				addr_latch[0] <= addr_latch_next[0];
				port[0] <= next_port[0];
				{oe_latch[0], we_latch[0]} <= 2'b00;
				if (next_port[0] != PORT_NONE) begin
					state[0] <= port1_req;
					sd_cmd <= CMD_ACTIVE;
					SDRAM_A <= addr_latch_next[0][22:10];
					SDRAM_BA <= addr_latch_next[0][24:23];
					{oe_latch[0], we_latch[0]} <= {~port1_we, port1_we};
					ds[0] <= port1_ds;
					din_latch[0] <= port1_d;
				end
			end
			if (t == STATE_RAS1) begin
				refresh <= 0;
				addr_latch[1] <= addr_latch_next[1];
				{oe_latch[1], we_latch[1]} <= 2'b00;
				port[1] <= next_port[1];
				if (next_port[1] != PORT_NONE) begin
					state[1] <= port2_req;
					sd_cmd <= CMD_ACTIVE;
					SDRAM_A <= addr_latch_next[1][22:10];
					SDRAM_BA <= addr_latch_next[1][24:23];
					{oe_latch[1], we_latch[1]} <= {~port2_we, port2_we};
					ds[1] <= port2_ds;
					din_latch[1] <= port2_d;
				end
				if ((((next_port[1] == PORT_NONE) && need_refresh) && !we_latch[0]) && !oe_latch[0]) begin
					refresh <= 1;
					refresh_cnt <= 0;
					sd_cmd <= CMD_AUTO_REFRESH;
				end
			end
			if ((t == STATE_CAS0) && (we_latch[0] || oe_latch[0])) begin
				sd_cmd <= (we_latch[0] ? CMD_WRITE : CMD_READ);
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds[0];
				if (we_latch[0]) begin
					SDRAM_DQr <= din_latch[0];
					port1_ack_reg <= port1_req;
				end
				SDRAM_A <= {4'b0010, addr_latch[0][9:1]};
				SDRAM_BA <= addr_latch[0][24:23];
			end
			if ((t == STATE_CAS1) && (we_latch[1] || oe_latch[1])) begin
				sd_cmd <= (we_latch[1] ? CMD_WRITE : CMD_READ);
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds[1];
				if (we_latch[1]) begin
					SDRAM_DQr <= din_latch[1];
					port2_ack_reg <= port2_req;
				end
				SDRAM_A <= {4'b0010, addr_latch[1][9:1]};
				SDRAM_BA <= addr_latch[1][24:23];
			end
			if ((t == STATE_DS0) && oe_latch[0])
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds[0];
			if ((t == STATE_READ0) && oe_latch[0]) begin
				port1_q_reg <= sd_din;
				port1_ack_reg <= port1_req;
			end
			if ((t == STATE_DS1) && oe_latch[1])
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds[1];
			if ((t == STATE_READ1) && oe_latch[1]) begin
				port2_q_reg <= sd_din;
				port2_ack_reg <= port2_req;
			end
		end
	end
	assign port1_q = ((t == STATE_READ0) && oe_latch[0] ? sd_din : port1_q_reg);
	assign port1_ack = ((t == STATE_READ0) && oe_latch[0] ? port1_req : port1_ack_reg);
	assign port2_q = ((t == STATE_READ1) && oe_latch[1] ? sd_din : port2_q_reg);
	assign port2_ack = ((t == STATE_READ1) && oe_latch[1] ? port2_req : port2_ack_reg);
endmodule
