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

	assign o_instruction[31:0] = o_ready ? buf_instruction_data[31:0] : 32'h0;

	initial buf_instruction_data = 32'h0;
	initial o_ready = 0;

	reg [7:0] local_input;
	reg local_en;
	reg local_we;

	always @(posedge i_clk) begin
		local_we <= i_we;
		local_en <= i_en;
		if (!i_en) local_input[7:0] <= i_data[7:0];
	end

	reg [1:0] buf_state;
	localparam [1:0] WAITING = 2'h0,
		READING_INSTRUCTION = 2'h1,
		READING_ARGS = 2'h2,
		READY = 2'h3;
	initial buf_state = WAITING;

	always @(posedge i_clk) begin
		case (buf_state)
		WAITING: begin
			o_ready <= 1'b0;
			buf_instruction_data[31:0] <= 32'h0;
			if (!local_we) buf_state <= READING_INSTRUCTION;
		end
		READING_INSTRUCTION: begin
			o_ready <= 1'b0;
			if (!local_en) begin
				o_ack <= 1'b1;
				buf_instruction_data [7:0] <= local_input[7:0];
			end else if (o_ack) begin 
				buf_state <= READING_ARGS;
				o_ack <= 1'b0;
			end
		end
		READING_ARGS: begin
			o_ready <= 1'b0;
			if (!local_en && !o_ack) begin
				buf_instruction_data [31:8] <= {buf_instruction_data[23:8], local_input[7:0]};
				o_ack <= 1'b1;
			end else if (local_en && o_ack) begin
				o_ack <= 1'b0;
			end else if (local_we) buf_state <= READY;
		end
		READY: begin
			o_ready <= 1'b1;
			o_ack <= 1'b0;
		end
		default:;
		endcase
		if (i_reset) begin
			 buf_state <= WAITING;
			 o_ready <= 1'b0;
		end
	end


`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	always @(posedge i_clk)
		if (f_past_valid && o_ack) assume(!local_en);

	always @(posedge i_clk)
		if (f_past_valid && o_ack) assert(!local_we && !local_en);

	always @(posedge i_clk)
		if (local_we) assume(local_en);

	always @(posedge i_clk)
		if (o_ready) assume(local_en && local_we);

	always @(posedge i_clk)
		if (f_past_valid && local_we)
			assume(o_ready);

	always @(posedge i_clk)
		cover(o_ready);

	always @(posedge i_clk)
		cover(!o_ready);


`endif
endmodule