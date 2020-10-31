`default_nettype none

module instruction_decoder(i_clk, i_we, i_en, i_data, o_ack,
	// signal generator instructions
	o_mode, o_set_mode,
	// pixel generator instructions
	o_pixel_x, o_pixel_y, o_color, o_set_pixel,
	o_busy);

	input wire i_clk;
	input wire i_we;
	input wire i_en;
	input wire [7:0] i_data;
	output wire o_ack;

	// instruction specific latch registers

	// signal generator instructions
	output reg [7:0] o_mode;
	output reg o_set_mode;
	initial o_set_mode = 1'b0;

	// pixel generator instructions
	output reg [9:0] o_pixel_x;
	output reg [9:0] o_pixel_y;
	output reg [11:0] o_color;
	output reg o_set_pixel;
	initial o_set_pixel = 1'b0;

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

	localparam [7:0] NOOP = 8'h0,
		SET_MODE = 8'h1,
		SET_BG_COLOR = 8'h2;


	initial instr_done = 1'b1;
	initial instr_loaded = 1'b0;

	always @(posedge i_clk)
		reset <= i_we && instr_done;

	localparam [2:0] WAITING_INSTRUCTION = 3'h0,
		LOADING_INSTRUCTION = 3'h1,
		EXECUTING_INSTRUCTION = 3'h2,
		WAITING_RESET = 3'h5;

	reg [2:0] state;
	initial state = 3'd0;

	always @(posedge i_clk) begin
		case (state)
		WAITING_INSTRUCTION: begin
			instr_loaded <= 1'b0;
			o_busy <= 1'b0;
		end
		LOADING_INSTRUCTION: begin
			o_busy <= 1'b1;
			instruction <= dec_instruction_data[7:0];
			instruction_args <= dec_instruction_data[31:8];
			instr_loaded <= 1'b1;
			state <= state + 1;
		end
		EXECUTING_INSTRUCTION: begin
			instr_loaded <= 1'b0;
			state <= state + 1;
		end
		WAITING_RESET: begin
			state <= WAITING_INSTRUCTION;
		end
		default: state <= state + 1;
		endcase
	end

	always @(posedge i_clk) begin
		if (o_ready && state == WAITING_INSTRUCTION) state <= LOADING_INSTRUCTION;
		else state <= WAITING_INSTRUCTION;
	end

	always @(posedge i_clk) begin
		if (instr_loaded && !instr_done&& !reset) begin
			case (instruction)
			SET_MODE:
				begin
					o_set_mode <= 1'b1;
					o_mode <= instruction_args[7:0];
					instr_done <= 1'b1;
				end
			SET_BG_COLOR:
				begin
					o_set_pixel <= 1'b1;
					o_pixel_x <= 0;
					o_pixel_y <= 0;
					o_color[11:0] <= instruction_args[11:0];
					instr_done <= 1'b1;
				end
			default:
				begin
					instr_done <= 1'b1;
					o_set_mode <= 1'b0;
					o_set_pixel <= 1'b0;
				end
			endcase
		end else begin
			instr_done <= 1'b0;
			o_set_mode <= 1'b0;
			o_set_pixel <= 1'b0;
		end

	end

	instruction_buffer buffer(
		.i_clk(i_clk), .i_reset(reset), .i_we(i_we), .i_en(i_en), .i_data(i_data), 
		.o_ack(o_ack), .o_instruction(dec_instruction_data), .o_ready(o_ready));

endmodule