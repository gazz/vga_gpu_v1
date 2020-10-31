`default_nettype none

module instruction_decoder(i_clk, i_we, i_en, i_data, o_ack,
	o_busy,
	// output instruction
	o_instruction, o_instruction_ready);

	input wire i_clk;
	input wire i_we;
	input wire i_en;
	input wire [7:0] i_data;
	output wire o_ack;

	output wire [31:0] o_instruction;
	output wire o_instruction_ready;

	wire [31:0] dec_instruction_data;
	reg [7:0] instruction;
	/* verilator lint_off UNUSED */
	// we disable linter as we do not have all the instructions fleshed out just yet
	reg [23:0] instruction_args;
	/* verilator lint_on UNUSED */
	reg instr_done;
	reg instr_loaded;

	reg reset;
	wire o_ready;

	output reg o_busy;
	initial o_busy = 0;

	initial instr_done = 1'b1;
	initial instr_loaded = 1'b0;

	always @(posedge i_clk)
		reset <= i_we && instr_done;

	localparam [2:0] WAITING_INSTRUCTION = 3'h0,
		LOADING_INSTRUCTION = 3'h1,
		EXECUTING_INSTRUCTION = 3'h2,
		WAITING_RESET = 3'h5;

	reg [2:0] dec_state;
	initial dec_state = 3'd0;

	always @(posedge i_clk) begin
		case (dec_state)
		WAITING_INSTRUCTION: begin
			instr_loaded <= 1'b0;
			o_busy <= 1'b0;
			if (o_ready) dec_state <= LOADING_INSTRUCTION;
		end
		LOADING_INSTRUCTION: begin
			o_busy <= 1'b1;
			instruction <= dec_instruction_data[7:0];
			instruction_args <= dec_instruction_data[31:8];
			instr_loaded <= 1'b1;
			dec_state <= dec_state + 1;
		end
		EXECUTING_INSTRUCTION: begin
			instr_loaded <= 1'b0;
			dec_state <= dec_state + 1;
		end
		WAITING_RESET: begin
			dec_state <= WAITING_INSTRUCTION;
		end
		default: dec_state <= dec_state + 1;
		endcase
	end

	assign o_instruction = { instruction_args[23:0], instruction[7:0] };
	assign o_instruction_ready = (instr_loaded && !instr_done && !reset);

	always @(posedge i_clk) begin
		if (instr_loaded && !instr_done && !reset) begin
			instr_done <= 1'b1;
		end else begin
			instr_done <= 1'b0;
		end

	end

	instruction_buffer buffer(
		.i_clk(i_clk), .i_reset(reset), .i_we(i_we), .i_en(i_en), .i_data(i_data), 
		.o_ack(o_ack), .o_instruction(dec_instruction_data), .o_ready(o_ready));

endmodule