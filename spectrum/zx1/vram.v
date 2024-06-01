module vram (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q
);
	input wire clock;
	input [7:0] data;
	input [14:0] rdaddress;
	input [14:0] wraddress;
	input wire wren;
	output wire [7:0] q;

	reg[7:0] ram[0:32767];

	always @(posedge clock) begin
		if (wren) ram[wraddress] <= data;
	end

	assign q = ram[rdaddress];
endmodule
