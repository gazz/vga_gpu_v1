`default_nettype none


module pixel_generator(i_clk,
	i_pixel_x, i_pixel_y, o_color,
	i_instruction, i_instruction_ready);
	input wire i_clk;
	input wire [9:0] i_pixel_x;
	input wire [9:0] i_pixel_y;
	output wire [11:0] o_color;
	// instructions
	input wire [31:0] i_instruction;
	input wire i_instruction_ready;

	wire [7:0] instruction;
	/* verilator lint_off UNUSED */
	wire [23:0] instruction_args;
	/* verilator lint_on UNUSED */

	localparam [7:0] SET_BG_COLOR = 8'h01,
		SET_RED_BG_COLOR = 8'h02,
		SET_GREEN_BG_COLOR = 8'h03,
		SET_BLUE_BG_COLOR = 8'h04;

	reg [11:0] bg_color;
	initial bg_color = 12'hf00;

	assign o_color = (i_pixel_x >= 10'h1 && i_pixel_y >= 10'h1) ? bg_color : bg_color;
	assign {instruction, instruction_args} = {i_instruction[7:0], i_instruction[31:8]};

	always @(posedge i_clk) begin
		if (i_instruction_ready) begin
			case (instruction)
			SET_BG_COLOR: begin
				bg_color <= instruction_args[11:0];
			end
			SET_RED_BG_COLOR: bg_color <= 12'hf00;
			SET_GREEN_BG_COLOR: bg_color <= 12'h0f0;
			SET_BLUE_BG_COLOR: bg_color <= 12'h00f;
			default:;
			endcase
		end
	end

endmodule