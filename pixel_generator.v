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
	reg pixel_write_pending;
	initial pixel_write_pending = 0;
	reg [9:0] arg_pixel_index;
	initial arg_pixel_index = 0;
	reg [2:0] pending_pixel;
	initial pending_pixel = 0;
	/* verilator lint_on UNUSED */

	
	reg screen_v_reset;
	initial screen_v_reset = 0;

	reg [2:0] palette_index;
	initial palette_index = 0;

	reg [9:0] row_offset;
	initial row_offset = 0;

	reg [9:0] pixel_index;
	initial pixel_index = 0;

	reg [4:0] pixel_counter;
	initial pixel_counter = 0;

	always @(posedge i_clk) begin
		pixel_write_pending <= 0;
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
				// screen_buffer[arg_pixel_index] <= instruction_args[12:10];
				// screen_buffer[arg_pixel_index] <= 3'h2;
				arg_pixel_index <= instruction_args[9:0];
				pending_pixel <= instruction_args[12:10];
				pixel_write_pending <= 1;
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
			pixel_index <= pixel_index + 1;
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
				row_offset <= row_offset + 30;
				pixel_index <= 0;
				pixel_row_counter <= 24;
			end
			screen_v_reset <= 1'b1;
		end

		if (screen_v_reset) begin
			screen_v_reset <= 1'b0;
		end

	end


	// reg [4:0] pixel_counter;
	// if (pixel_counter == 1) begin
	// 	if (hor_state == PIXEL_DATA && ver_state == PIXEL_DATA) o_pixel_x_clock <= 1'b1;
	// 	pixel_counter <= 10;
	// end else begin
	//  	pixel_counter <= pixel_counter - 1;
	// 	o_pixel_x_clock <= 1'b0;
	// end



	// lets try to use simple registers as screen buffer
	// reg [1799:0] screen_buffer;
	reg	[2:0]	screen_buffer	[0:599];

	// For loops require integer indices
	integer		k;

	initial begin
		for(k=0; k<599; k=k+8) begin
			screen_buffer[k + 0] = 3'h0;
			screen_buffer[k + 1] = 3'h1;
			screen_buffer[k + 2] = 3'h2;
			screen_buffer[k + 3] = 3'h3;
			screen_buffer[k + 4] = 3'h4;
			screen_buffer[k + 5] = 3'h5;
			screen_buffer[k + 6] = 3'h6;
			screen_buffer[k + 7] = 3'h7;
		end

		// $readmemh("speech.hex", tx_memory);
	end

	wire [9:0] total_pixel_index;
	assign total_pixel_index = row_offset + pixel_index;

	always @(posedge i_clk)
		// palette_index[6:0] <= {screen_buffer[row_offset + pixel_index], 4'b0};
		palette_index[2:0] <= screen_buffer[total_pixel_index];

	always @(posedge i_clk)
		o_color <= palette[palette_index];

	// always @(posedge i_clk)
	// 	if (pixel_write_pending) screen_buffer[arg_pixel_index] <= pending_pixel;

	// assign palette_index[6:0] = {screen_buffer[row_offset + pixel_index +: 3], 4'b0};

	reg [11:0] palette [0:7];
	initial begin
		palette[0] = 12'h000;
		palette[1] = 12'hfff;
		palette[2] = 12'hf00;
		palette[3] = 12'h0f0;
		palette[4] = 12'h00f;
		palette[5] = 12'hf0f;
		palette[6] = 12'h0ff;
		palette[7] = 12'hff0;
	end



	// reg [119:0] sprites [8];


endmodule