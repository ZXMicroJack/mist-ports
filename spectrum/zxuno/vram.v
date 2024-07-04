module vram (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q,
	dbg
);
	input wire clock;
	input [7:0] data;
	input [14:0] rdaddress;
	input [14:0] wraddress;
	input wire wren;
	output wire [7:0] q;
	input wire[15:0] dbg;

	reg[7:0] ram[0:32767];

	always @(posedge clock) begin
		if (wren) ram[wraddress] <= data;
	end

	//assign q = ram[rdaddress];

	assign w = !dbg[rdaddress[3:0]];
	assign q = rdaddress[14:4] == 11'h180 ? {w,w,w,w,w,w,w,w} : ram[rdaddress];
	//assign q = 8'haa;
endmodule
