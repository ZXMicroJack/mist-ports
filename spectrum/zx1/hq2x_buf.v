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
	reg [7:0] mem [0:32767];
	always @(posedge clock) begin
		q <= mem[rdaddress];
		if (wren)
			mem[wraddress] <= data;
	end
	altsyncram altsyncram_component(
		.address_a(wraddress),
		.clock0(clock),
		.data_a(data),
		.wren_a(wren),
		.address_b(rdaddress),
		.q_b(q),
		.aclr0(1'b0),
		.aclr1(1'b0),
		.addressstall_a(1'b0),
		.addressstall_b(1'b0),
		.byteena_a(1'b1),
		.byteena_b(1'b1),
		.clock1(1'b1),
		.clocken0(1'b1),
		.clocken1(1'b1),
		.clocken2(1'b1),
		.clocken3(1'b1),
		.data_b({DWIDTH + 1 {1'b1}}),
		.eccstatus(),
		.q_a(),
		.rden_a(1'b1),
		.rden_b(1'b1),
		.wren_b(1'b0)
	);
	defparam altsyncram_component.address_aclr_b = "NONE";
	defparam altsyncram_component.address_reg_b = "CLOCK0";
	defparam altsyncram_component.clock_enable_input_a = "BYPASS";
	defparam altsyncram_component.clock_enable_input_b = "BYPASS";
	defparam altsyncram_component.clock_enable_output_b = "BYPASS";
	defparam altsyncram_component.intended_device_family = "Cyclone III";
	defparam altsyncram_component.lpm_type = "altsyncram";
	defparam altsyncram_component.numwords_a = NUMWORDS;
	defparam altsyncram_component.numwords_b = NUMWORDS;
	defparam altsyncram_component.operation_mode = "DUAL_PORT";
	defparam altsyncram_component.outdata_aclr_b = "NONE";
	defparam altsyncram_component.outdata_reg_b = "UNREGISTERED";
	defparam altsyncram_component.power_up_uninitialized = "FALSE";
	defparam altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE";
	defparam altsyncram_component.widthad_a = AWIDTH + 1;
	defparam altsyncram_component.widthad_b = AWIDTH + 1;
	defparam altsyncram_component.width_a = DWIDTH + 1;
	defparam altsyncram_component.width_b = DWIDTH + 1;
	defparam altsyncram_component.width_byteena_a = 1;
endmodule
