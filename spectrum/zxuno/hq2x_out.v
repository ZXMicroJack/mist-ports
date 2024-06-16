module hq2x_out (
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
	localparam AWIDTH = ((LENGTH * 2) <= 2 ? 0 : ((LENGTH * 2) <= 4 ? 1 : ((LENGTH * 2) <= 8 ? 2 : ((LENGTH * 2) <= 16 ? 3 : ((LENGTH * 2) <= 32 ? 4 : ((LENGTH * 2) <= 64 ? 5 : ((LENGTH * 2) <= 128 ? 6 : ((LENGTH * 2) <= 256 ? 7 : ((LENGTH * 2) <= 512 ? 8 : ((LENGTH * 2) <= 1024 ? 9 : 10))))))))));
	input [AWIDTH:0] rdaddr;
	input [1:0] rdbuf;
	output wire [DWIDTH:0] q;
	input [AWIDTH:0] wraddr;
	input [1:0] wrbuf;
	input [DWIDTH:0] data;
	input wren;
	wire [DWIDTH:0] out [0:3];
	assign q = out[rdbuf];
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
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
		.NUMWORDS(LENGTH * 2),
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
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf2(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 2)),
		.q(out[2])
	);
	hq2x_buf #(
		.NUMWORDS(LENGTH * 2),
		.AWIDTH(AWIDTH),
		.DWIDTH(DWIDTH)
	) buf3(
		.clock(clk),
		.data(data),
		.rdaddress(rdaddr),
		.wraddress(wraddr),
		.wren(wren && (wrbuf == 3)),
		.q(out[3])
	);
endmodule
