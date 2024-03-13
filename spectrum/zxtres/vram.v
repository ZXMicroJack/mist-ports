module vram (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q);

	input	  clock;
	input	[7:0]  data;
	input	[14:0]  rdaddress;
	input	[14:0]  wraddress;
	input	  wren;
	output reg	[7:0]  q;

   reg [7:0] mem [0:32767] /* synthesis ramstyle = "M144K" */;

   always @(posedge clock) begin
     q <= mem[rdaddress];
     if (wren)
        mem[wraddress] <= data;
   end
endmodule

