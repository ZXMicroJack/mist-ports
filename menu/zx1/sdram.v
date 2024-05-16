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
	cpu1_addr,
	cpu1_q,
	cpu1_oe
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
	output reg port1_ack;
	input port1_we;
	input [23:1] port1_a;
	input [1:0] port1_ds;
	input [15:0] port1_d;
	output reg [31:0] port1_q;
	input [23:2] cpu1_addr;
	output reg [31:0] cpu1_q;
	input cpu1_oe;
	parameter MHZ = 80;
	localparam RASCAS_DELAY = 3'd2;
	localparam BURST_LENGTH = 3'b001;
	localparam ACCESS_TYPE = 1'b0;
	localparam CAS_LATENCY = 3'd2;
	localparam OP_MODE = 2'b00;
	localparam NO_WRITE_BURST = 1'b1;
	localparam MODE = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};
	localparam RFRSH_CYCLES = (16'd78 * MHZ) / 10;
	localparam STATE_RAS0 = 3'd0;
	localparam STATE_CAS0 = STATE_RAS0 + RASCAS_DELAY;
	localparam STATE_DS1 = (STATE_RAS0 + RASCAS_DELAY) + 1'd1;
	localparam STATE_READ0 = (STATE_CAS0 + CAS_LATENCY) + 2'd2;
	localparam STATE_READ1 = (STATE_CAS0 + CAS_LATENCY) + 2'd3;
	localparam STATE_LAST = 3'd7;
	reg [2:0] t;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg clkref_d;
		clkref_d <= clkref;
		t <= t + 1'd1;
		if (t == STATE_LAST)
			t <= STATE_RAS0;
		if (~clkref_d & clkref)
			t <= 3'd1;
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
	reg [24:1] addr_latch;
	reg [24:1] addr_latch_next;
	reg [15:0] din_latch;
	reg oe_latch;
	reg we_latch;
	reg [1:0] ds;
	localparam PORT_NONE = 2'd0;
	localparam PORT_CPU1 = 2'd1;
	localparam PORT_REQ = 2'd2;
	reg [2:0] next_port;
	reg [2:0] port;
	reg port1_state;
	always @(*)
		if (port1_req ^ port1_state) begin
			next_port = PORT_REQ;
			addr_latch_next = {1'b0, port1_a};
		end
		else if (cpu1_oe) begin
			next_port = PORT_CPU1;
			addr_latch_next = {1'b0, cpu1_addr, 1'b0};
		end
		else begin
			next_port = PORT_NONE;
			addr_latch_next = addr_latch;
		end
	reg [15:0] sdram_dq;
	assign SDRAM_DQ = (SDRAM_nWE ? 16'bzzzzzzzzzzzzzzzz : sdram_dq);
	always @(posedge clk) begin
		sd_din <= SDRAM_DQ;
		{SDRAM_DQMH, SDRAM_DQML} <= 2'b11;
		sd_cmd <= CMD_NOP;
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
				addr_latch <= addr_latch_next;
				port <= next_port;
				{oe_latch, we_latch} <= 2'b00;
				if (next_port != PORT_NONE) begin
					sd_cmd <= CMD_ACTIVE;
					SDRAM_A <= addr_latch_next[22:10];
					SDRAM_BA <= addr_latch_next[24:23];
					if (next_port == PORT_REQ) begin
						{oe_latch, we_latch} <= {~port1_we, port1_we};
						ds <= port1_ds;
						din_latch <= port1_d;
						port1_state <= port1_req;
					end
					else begin
						{oe_latch, we_latch} <= 2'b10;
						ds <= 2'b11;
					end
				end
				else
					sd_cmd <= CMD_AUTO_REFRESH;
			end
			if ((t == STATE_CAS0) && (we_latch || oe_latch)) begin
				sd_cmd <= (we_latch ? CMD_WRITE : CMD_READ);
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds;
				if (we_latch) begin
					sdram_dq <= din_latch;
					port1_ack <= port1_req;
				end
				SDRAM_A <= {4'b0010, addr_latch[9:1]};
				SDRAM_BA <= addr_latch[24:23];
			end
			if ((t == STATE_DS1) && oe_latch)
				{SDRAM_DQMH, SDRAM_DQML} <= ~ds;
			if ((t == STATE_READ0) && oe_latch)
				case (port)
					PORT_REQ: port1_q[15:0] <= sd_din;
					PORT_CPU1: cpu1_q[15:0] <= sd_din;
					default:
						;
				endcase
			if ((t == STATE_READ1) && oe_latch)
				case (port)
					PORT_REQ: begin
						port1_q[31:16] <= sd_din;
						port1_ack <= port1_req;
					end
					PORT_CPU1: cpu1_q[31:16] <= sd_din;
					default:
						;
				endcase
		end
	end
endmodule
