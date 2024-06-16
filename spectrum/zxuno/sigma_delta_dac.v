module sigma_delta_dac (
	DACout,
	DACin,
	CLK,
	RESET
);
	parameter MSBI = 7;
	parameter INV = 1'b1;
	output reg DACout;
	input [MSBI:0] DACin;
	input CLK;
	input RESET;
	reg [MSBI + 2:0] DeltaAdder;
	reg [MSBI + 2:0] SigmaAdder;
	reg [MSBI + 2:0] SigmaLatch;
	reg [MSBI + 2:0] DeltaB;
	always @(*) DeltaB = {SigmaLatch[MSBI + 2], SigmaLatch[MSBI + 2]} << (MSBI + 1);
	always @(*) DeltaAdder = DACin + DeltaB;
	always @(*) SigmaAdder = DeltaAdder + SigmaLatch;
	always @(posedge CLK or posedge RESET)
		if (RESET) begin
			SigmaLatch <= 1'b1 << (MSBI + 1);
			DACout <= INV;
		end
		else begin
			SigmaLatch <= SigmaAdder;
			DACout <= SigmaLatch[MSBI + 2] ^ INV;
		end
endmodule
