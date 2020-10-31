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
	wire [23:0] instruction_args;

	localparam [7:0] SET_BG_COLOR = 8'h01;

	reg [11:0] bg_color;
	initial bg_color = 12'hf00;

	assign o_color = bg_color;
	assign {instruction, instruction_args} = {i_instruction[7:0], i_instruction[31:8]};

	always @(posedge i_clk) begin
		if (i_instruction_ready) begin
			case (instruction)
			SET_BG_COLOR: begin
				bg_color <= instruction_args[11:0];
			end
			endcase
		end
	end

endmodule