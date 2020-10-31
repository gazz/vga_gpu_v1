`default_nettype none

module instruction_buffer(i_clk, i_reset, i_we, i_en, i_data, o_ack, o_instruction, o_ready);
	input wire i_clk;
	input wire i_reset;
	input wire [7:0] i_data;
	input wire i_we;
	input wire i_en;
	output reg o_ack;
	output wire [31:0] o_instruction;
	output reg o_ready;

	reg [31:0] buf_instruction_data;

	assign o_instruction = o_ready ? buf_instruction_data : 0;

	initial buf_instruction_data = 32'h0;
	initial o_ready = 0;

	reg [1:0] buf_state;
	localparam [1:0] WAITING = 2'h0,
		READING_INSTRUCTION = 2'h1,
		READING_ARGS = 2'h2,
		READY = 2'h3;

	// always @(posedge i_clk) 
	// 	if (i_reset) o_ready <= 1'b0;
	// 	else o_ready <= i_we;
	always @(posedge i_clk) 
		if (i_reset) buf_state <= WAITING;
		else if (!i_we && buf_state == WAITING) buf_state <= READING_INSTRUCTION;
		else if (i_we && buf_state == READING_ARGS) buf_state <= READY;

	always @(posedge i_clk)
	case (buf_state)
	WAITING: begin
	 	o_ready <= 1'b0;
	end
	READING_INSTRUCTION: begin
		o_ready <= 1'b0;
		buf_state <= buf_state + 1;
	end
	READING_ARGS: begin
		o_ready <= 1'b0;
	end
	READY: o_ready <= 1'b1;
	default: o_ready <= 1'b0;
	endcase

	always @(posedge i_clk) begin
		if (!i_we && !i_en) begin 
			buf_instruction_data [31:0] <= (buf_state == READING_INSTRUCTION)
				? { 24'b0, i_data[7:0] } 
				: { buf_instruction_data[23:8], i_data[7:0], buf_instruction_data[7:0] };
			o_ack <= 1'b1;
		end else if (o_ready && !i_we) begin
			buf_instruction_data <= 32'h0;
		end else o_ack <= 1'b0;
	end


`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	always @(posedge i_clk)
		if (f_past_valid && o_ack) assume(!i_en);

	always @(posedge i_clk)
		if (f_past_valid && o_ack) assert(!i_we && !i_en);

	always @(posedge i_clk)
		if (i_we) assume(i_en);

	always @(posedge i_clk)
		if (o_ready) assume(i_en && i_we);

	always @(posedge i_clk)
		if (f_past_valid && i_we)
			assume(o_ready);

	always @(posedge i_clk)
		cover(o_ready);

	always @(posedge i_clk)
		cover(!o_ready);


`endif
endmodule