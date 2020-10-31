`default_nettype none

module instruction_decoder(i_clk, i_we, i_en, i_data, i_instr_done, o_ack, o_instruction);
	input wire i_clk;
	input wire i_we;
	input wire i_en;
	input wire i_data;
	input wire i_instr_done;
	input wire o_ack;
	input wire o_instruction;

	wire i_reset;
	wire o_ready;

	assign i_reset = !i_we && i_instr_done;

	instruction_buffer buffer(i_clk, i_reset, i_we, i_en, i_data, 
		o_ack, o_instruction, o_ready);

endmodule