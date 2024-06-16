module spi (
	clk_sys,
	tx,
	rx,
	din,
	dout,
	spi_clk,
	spi_di,
	spi_do
);
	input clk_sys;
	input tx;
	input rx;
	input [7:0] din;
	output wire [7:0] dout;
	output wire spi_clk;
	input spi_di;
	output wire spi_do;
	reg [4:0] counter = 5'b10000;
	assign spi_clk = counter[0];
	reg [7:0] io_byte;
	assign spi_do = io_byte[7];
	reg [7:0] data;
	assign dout = data;
	always @(negedge clk_sys)
		if (counter[4]) begin
			if (rx | tx) begin
				counter <= 0;
				data <= io_byte;
				io_byte <= (tx ? din : 8'hff);
			end
		end
		else begin
			if (spi_clk)
				io_byte <= {io_byte[6:0], spi_di};
			counter <= counter + 2'd1;
		end
endmodule
