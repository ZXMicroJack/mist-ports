module gs (
	RESET,
	CLK,
	CE_N,
	CE_P,
	A,
	DI,
	DO,
	CS_n,
	WR_n,
	RD_n,
	MEM_ADDR,
	MEM_DI,
	MEM_DO,
	MEM_RD,
	MEM_WR,
	MEM_WAIT,
	OUTL,
	OUTR
);
	input RESET;
	input CLK;
	input CE_N;
	input CE_P;
	input A;
	input [7:0] DI;
	output wire [7:0] DO;
	input CS_n;
	input WR_n;
	input RD_n;
	output wire [20:0] MEM_ADDR;
	output wire [7:0] MEM_DI;
	input [7:0] MEM_DO;
	output wire MEM_RD;
	output wire MEM_WR;
	input MEM_WAIT;
	output wire [14:0] OUTL;
	output wire [14:0] OUTR;
	parameter INT_DIV = 291;
	reg flag_cmd;
	reg flag_data;
	reg [7:0] port_03;
	assign DO = (A ? {flag_data, 6'b111111, flag_cmd} : port_03);
	reg int_n;
	wire cpu_m1_n;
	wire cpu_mreq_n;
	wire cpu_iorq_n;
	wire cpu_rfsh_n;
	wire cpu_rd_n;
	wire cpu_wr_n;
	wire [15:0] cpu_a_bus;
	wire [7:0] cpu_do_bus;
	wire mem_rd = ~cpu_rd_n & ~cpu_mreq_n;
	reg [7:0] port_B3;
	reg [7:0] port_BB;
	wire [7:0] cpu_di_bus = (mem_rd ? MEM_DO : ((~cpu_iorq_n && ~cpu_rd_n) && (cpu_a_bus[3:0] == 1) ? port_BB : ((~cpu_iorq_n && ~cpu_rd_n) && (cpu_a_bus[3:0] == 2) ? port_B3 : ((~cpu_iorq_n && ~cpu_rd_n) && (cpu_a_bus[3:0] == 4) ? {flag_data, 6'b111111, flag_cmd} : 8'hff))));
	T80pa cpu(
		.RESET_n(~RESET),
		.CLK(CLK),
		.CEN_n(CE_N),
		.CEN_p(CE_P),
		.INT_n(int_n),
		.M1_n(cpu_m1_n),
		.MREQ_n(cpu_mreq_n),
		.RFSH_n(cpu_rfsh_n),
		.IORQ_n(cpu_iorq_n),
		.RD_n(cpu_rd_n),
		.WR_n(cpu_wr_n),
		.A(cpu_a_bus),
		.DO(cpu_do_bus),
		.DI(cpu_di_bus)
	);
	wire CE = CE_P;
	reg WR_n_d;
	reg RD_n_d;
	wire RD = RD_n_d & ~RD_n;
	wire WR = WR_n_d & ~WR_n;
	always @(posedge CLK) begin
		RD_n_d <= RD_n;
		WR_n_d <= WR_n;
	end
	always @(posedge CLK) begin : sv2v_autoblock_1
		reg [9:0] cnt;
		if (RESET) begin
			cnt <= 0;
			int_n <= 1;
		end
		else if (CE) begin
			cnt <= cnt + 1'b1;
			if (cnt == INT_DIV) begin
				cnt <= 0;
				int_n <= 0;
			end
		end
		if (~cpu_iorq_n & ~cpu_m1_n)
			int_n <= 1;
	end
	reg [5:0] port_00;
	reg signed [6:0] port_09;
	always @(posedge CLK) begin
		if (~cpu_iorq_n & cpu_m1_n)
			case (cpu_a_bus[3:0])
				'h2: flag_data <= 0;
				'h3: flag_data <= 1;
				'h5: flag_cmd <= 0;
				'ha: flag_data <= ~port_00[0];
				'hb: flag_cmd <= port_09[5];
			endcase
		if (~CS_n) begin
			if (~A & RD)
				flag_data <= 0;
			if (~A & WR)
				flag_data <= 1;
			if (A & WR)
				flag_cmd <= 1;
		end
	end
	always @(posedge CLK)
		if (RESET) begin
			port_BB <= 0;
			port_B3 <= 0;
		end
		else if (~CS_n && WR) begin
			if (A)
				port_BB <= DI;
			else
				port_B3 <= DI;
		end
	reg signed [6:0] port_06;
	reg signed [6:0] port_07;
	reg signed [6:0] port_08;
	reg signed [7:0] ch_a;
	reg signed [7:0] ch_b;
	reg signed [7:0] ch_c;
	reg signed [7:0] ch_d;
	always @(posedge CLK)
		if (RESET) begin
			port_00 <= 0;
			port_03 <= 0;
		end
		else begin
			if (~cpu_iorq_n & ~cpu_wr_n)
				case (cpu_a_bus[3:0])
					0: port_00 <= cpu_do_bus[5:0];
					3: port_03 <= cpu_do_bus;
					6: port_06 <= cpu_do_bus[5:0];
					7: port_07 <= cpu_do_bus[5:0];
					8: port_08 <= cpu_do_bus[5:0];
					9: port_09 <= cpu_do_bus[5:0];
				endcase
			if ((mem_rd && (cpu_a_bus[15:13] == 3)) && ~MEM_WAIT)
				case (cpu_a_bus[9:8])
					0: ch_a <= {~MEM_DO[7], MEM_DO[6:0]};
					1: ch_b <= {~MEM_DO[7], MEM_DO[6:0]};
					2: ch_c <= {~MEM_DO[7], MEM_DO[6:0]};
					3: ch_d <= {~MEM_DO[7], MEM_DO[6:0]};
				endcase
		end
	wire [5:0] page_addr = (cpu_a_bus[15] ? port_00 : cpu_a_bus[14]);
	wire mem_wr = (~cpu_wr_n & ~cpu_mreq_n) & |page_addr;
	assign MEM_ADDR = {page_addr, &cpu_a_bus[15:14], cpu_a_bus[13:0]};
	assign MEM_RD = mem_rd;
	assign MEM_WR = mem_wr;
	assign MEM_DI = cpu_do_bus;
	reg signed [14:0] out_a;
	reg signed [14:0] out_b;
	reg signed [14:0] out_c;
	reg signed [14:0] out_d;
	always @(posedge CLK)
		if (CE) begin
			out_a <= ch_a * port_06;
			out_b <= ch_b * port_07;
			out_c <= ch_c * port_08;
			out_d <= ch_d * port_09;
		end
	reg signed [14:0] outl;
	reg signed [14:0] outr;
	always @(posedge CLK)
		if (CE) begin
			outl <= out_a + out_b;
			outr <= out_c + out_d;
		end
	assign OUTL = outl;
	assign OUTR = outr;
endmodule
