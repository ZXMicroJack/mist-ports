module hq2x_buf (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q
);
	parameter NUMWORDS = 0;
	parameter AWIDTH = 0;
	parameter DWIDTH = 0;
	input clock;
	input [DWIDTH:0] data;
	input [AWIDTH:0] rdaddress;
	input [AWIDTH:0] wraddress;
	input wren;
	output reg [DWIDTH:0] q;
	reg [DWIDTH:0] mem [0:NUMWORDS-1];

	always @(posedge clock) begin
		q <= mem[rdaddress];
		if (wren)
			mem[wraddress] <= data;
	end
endmodule
