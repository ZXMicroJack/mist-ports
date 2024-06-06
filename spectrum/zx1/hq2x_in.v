`default_nettype none
module hq2x_in (
	clk,
	rdaddr,
	rdbuf,
	q,
	wraddr,
	wrbuf,
	data,
	wren
);
	parameter LENGTH = 0;
	parameter DWIDTH = 0;
	input clk;
	localparam AWIDTH = (LENGTH <= 2 ? 0 : (LENGTH <= 4 ? 1 : (LENGTH <= 8 ? 2 : (LENGTH <= 16 ? 3 : (LENGTH <= 32 ? 4 : (LENGTH <= 64 ? 5 : (LENGTH <= 128 ? 6 : (LENGTH <= 256 ? 7 : (LENGTH <= 512 ? 8 : (LENGTH <= 1024 ? 9 : 10))))))))));
	input [AWIDTH:0] rdaddr;
	input rdbuf;
	output wire [DWIDTH:0] q;
	input [AWIDTH:0] wraddr;
	input wrbuf;
	input [DWIDTH:0] data;
	input wren;
	wire [DWIDTH:0] out [0:1];
	assign q = out[rdbuf];
	hq2x_buf #(
		.NUMWORDS(LENGTH),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf0(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 0)),
		.q(out[0])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf1(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 1)),
		.q(out[1])
	);
endmodule
