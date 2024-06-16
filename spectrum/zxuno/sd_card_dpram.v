module sd_card_dpram (
	clock_a,
	address_a,
	data_a,
	wren_a,
	q_a,
	clock_b,
	address_b,
	data_b,
	wren_b,
	q_b
);
	parameter DATAWIDTH = 8;
	parameter ADDRWIDTH = 9;
	input clock_a;
	input [ADDRWIDTH - 1:0] address_a;
	input [DATAWIDTH - 1:0] data_a;
	input wren_a;
	output reg [DATAWIDTH - 1:0] q_a;
	input clock_b;
	input [ADDRWIDTH - 1:0] address_b;
	input [DATAWIDTH - 1:0] data_b;
	input wren_b;
	output reg [DATAWIDTH - 1:0] q_b;
	reg [DATAWIDTH - 1:0] ram [0:(1 << ADDRWIDTH) - 1];
	always @(posedge clock_a) begin
		q_a <= ram[address_a];
		if (wren_a) begin
			q_a <= data_a;
			ram[address_a] <= data_a;
		end
	end
	always @(posedge clock_b) begin
		q_b <= ram[address_b];
		if (wren_b) begin
			q_b <= data_b;
			ram[address_b] <= data_b;
		end
	end
endmodule
