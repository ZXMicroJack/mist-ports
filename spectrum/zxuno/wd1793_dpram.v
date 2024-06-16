module wd1793_dpram (
	clock,
	address_a,
	data_a,
	wren_a,
	q_a,
	address_b,
	data_b,
	wren_b,
	q_b
);
	parameter DATAWIDTH = 8;
	parameter ADDRWIDTH = 11;
	input clock;
	input [ADDRWIDTH - 1:0] address_a;
	input [DATAWIDTH - 1:0] data_a;
	input wren_a;
	output reg [DATAWIDTH - 1:0] q_a;
	input [ADDRWIDTH - 1:0] address_b;
	input [DATAWIDTH - 1:0] data_b;
	input wren_b;
	output reg [DATAWIDTH - 1:0] q_b;
	reg [DATAWIDTH - 1:0] ram [0:(1 << ADDRWIDTH) - 1];
	always @(posedge clock)
		if (wren_a) begin
			ram[address_a] <= data_a;
			q_a <= data_a;
		end
		else
			q_a <= ram[address_a];
	always @(posedge clock)
		if (wren_b) begin
			ram[address_b] <= data_b;
			q_b <= data_b;
		end
		else
			q_b <= ram[address_b];
endmodule
