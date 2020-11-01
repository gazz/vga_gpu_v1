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
	reg [31:0] instruction;
	reg instr_done;
	reg instr_loaded;

	reg reset;
	wire o_ready;

	output reg o_busy;
	initial o_busy = 0;

	initial instr_done = 1'b1;
	initial instr_loaded = 1'b0;

	localparam [2:0] WAITING_INSTRUCTION = 3'h0,
		LOADING_INSTRUCTION = 3'h1,
		EXECUTING_INSTRUCTION = 3'h2,
		WAITING_RESET = 3'h5;

	reg [2:0] dec_state;
	initial dec_state = 3'd0;

	reg [2:0] excute_counter; 

	always @(posedge i_clk) begin
		case (dec_state)
		WAITING_INSTRUCTION: begin
			instr_loaded <= 1'b0;
			o_busy <= 1'b0;
			reset <= 1'b0;
			if (!reset && o_ready) dec_state <= LOADING_INSTRUCTION;
		end
		LOADING_INSTRUCTION: begin
			o_busy <= 1'b1;
			instruction[31:0] <= dec_instruction_data[31:0];
			instr_done <= 1'b0;
			dec_state <= EXECUTING_INSTRUCTION;
			excute_counter <= 1;

		end
		EXECUTING_INSTRUCTION: begin
			instr_loaded <= 1'b1;
			if (excute_counter == 0) begin
				dec_state <= WAITING_RESET;
				instr_done <= 1'b1;
			end
			else excute_counter <= excute_counter - 1;
		end
		WAITING_RESET: begin
			reset <= 1'b1;
			dec_state <= WAITING_INSTRUCTION;
		end
		default:;
		endcase
	end

	assign o_instruction[31:0] = instruction[31:0];
	assign o_instruction_ready = (instr_loaded && !instr_done && !reset);

	instruction_buffer buffer(
		.i_clk(i_clk), .i_reset(reset), .i_we(i_we), .i_en(i_en), .i_data(i_data), 
		.o_ack(o_ack), .o_instruction(dec_instruction_data), .o_ready(o_ready));

endmodule