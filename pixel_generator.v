`default_nettype none


module pixel_generator(i_clk,
	i_vsync, i_hsync,
	i_screen_reset, i_pixel_x_clock, i_pixel_y_clock, o_color,
	i_instruction, i_instruction_ready);
	input wire i_clk;
	input wire i_vsync;
	input wire i_hsync;

	input wire i_screen_reset;
	input wire i_pixel_x_clock;
	input wire i_pixel_y_clock;

	output reg [11:0] o_color;

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
		SET_BLUE_BG_COLOR = 8'h04,
		SET_BLACK_BG_COLOR = 8'h05,
		SET_WHITE_BG_COLOR = 8'h06,
		SET_PIXEL = 8'h07;

	reg [11:0] pending_bg_color;
	/* verilator lint_off UNUSED */
	reg [11:0] bg_color;
	/* verilator lint_on UNUSED */
	initial bg_color = 12'hf00;

	reg [7:0] pixel_row;
	reg [4:0] pixel_row_counter;
	initial pixel_row_counter = 0;
	initial pixel_row = 0;


	// local copy of registers
	reg [31:0] l_instruction;
	reg l_instruction_ready;

	always @(posedge i_clk) begin
		l_instruction_ready <= i_instruction_ready;
		if (i_instruction_ready) l_instruction[31:0] <= i_instruction[31:0];
		else l_instruction[31:0] <= 32'h0;
	end

	assign instruction[7:0] = l_instruction[7:0];
	assign instruction_args[23:0] = l_instruction[31:8];

	/* verilator lint_off UNUSED */
	wire [10:0] arg_pixel_index;
	assign arg_pixel_index[10:0] = instruction_args[10:0];
	/* verilator lint_on UNUSED */

	wire [6:0] palette_index;
	assign palette_index[6:0] = {screen_buffer[row_offset + pixel_index +: 3], 4'b0};

	always @(posedge i_clk) begin
		if (l_instruction_ready) begin
			case (instruction)
			SET_BG_COLOR: begin
				pending_bg_color <= instruction_args[11:0];
			end
			SET_RED_BG_COLOR: pending_bg_color <= 12'hf00;
			SET_GREEN_BG_COLOR: pending_bg_color <= 12'h0f0;
			SET_BLUE_BG_COLOR: pending_bg_color <= 12'h00f;
			SET_BLACK_BG_COLOR: pending_bg_color <= 12'h000;
			SET_WHITE_BG_COLOR: pending_bg_color <= 12'hfff;
			SET_PIXEL: begin
				// screen_buffer[arg_pixel_index +: 3] <= instruction_args[12:10];
			end 
			default:;
			endcase
		end

		if (i_vsync) begin 
			bg_color <= pending_bg_color;
			pixel_row <= 0;
		end

		if (i_hsync) begin
			pixel_index <= 0;
		end else if (i_pixel_x_clock) begin
			pixel_index <= pixel_index + 3;
		end

		if (i_screen_reset) begin
			pixel_index <= 0;
			pixel_row <= 0;
			pixel_row_counter <= 24;
			row_offset <= 0;
		end

		if (i_pixel_y_clock) begin
			pixel_row_counter <= pixel_row_counter - 1;
			if (pixel_row_counter == 1) begin
				pixel_row <= pixel_row + 1;
				row_offset <= row_offset + 90;
				pixel_index <= 0;
				pixel_row_counter <= 24;
			end
			screen_v_reset <= 1'b1;
		end

		if (screen_v_reset) begin
			screen_v_reset <= 1'b0;
		end

		o_color <= palette[palette_index +: 12];

	end

	reg screen_v_reset;
	initial screen_v_reset = 0;


	// lets try to use simple registers as screen buffer
	reg [1799:0] screen_buffer;
	// initial screen_buffer[1799:0] = {{75{3'h0}}, {75{3'h1}}};
	initial screen_buffer[1799:0] = {
									// {75{3'h0}}
									{1{3'h7, 3'h5, 3'h4, 3'h5, 3'h4, 3'h5, 3'h4, 3'h0}},
									{73{3'h7, 3'h6, 3'h5, 3'h4, 3'h3, 3'h2, 3'h1, 3'h0}},
									{1{3'h7, 3'h5, 3'h4, 3'h5, 3'h4, 3'h5, 3'h4, 3'h0}}};
	// reg [95:0] palette;
	// initial palette[95:0] = {12'hff0,12'h0ff,12'hf0f,12'h00f,12'h0f0,12'hf00,12'hfff,12'h000};
	reg [127:0] palette;
	initial palette[127:0] = {16'hff0,16'h0ff,16'hf0f,16'h00f,16'h0f0,16'hf00,16'hfff,16'h000};

	reg [10:0] row_offset;
	initial row_offset = 0;

	reg [10:0] pixel_index;
	initial pixel_index = 0;


endmodule