module s_fix (
	clk,
	sync_in,
	sync_out
);
	input clk;
	input sync_in;
	output wire sync_out;
	reg pol;
	assign sync_out = sync_in ^ pol;
	always @(posedge clk) begin : sv2v_autoblock_1
		integer pos;
		integer neg;
		integer cnt;
		reg s1;
		reg s2;
		pos = 0;
		neg = 0;
		cnt = 0;
		s1 <= sync_in;
		s2 <= s1;
		if (~s2 & s1)
			neg <= cnt;
		if (s2 & ~s1)
			pos <= cnt;
		cnt <= cnt + 1;
		if (s2 != s1)
			cnt <= 0;
		pol <= pos > neg;
	end
endmodule
