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
		SET_PIXEL = 8'h07,
		SET_SPRITE = 8'h08;

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
	reg [7:0] pending_pixel;
	initial pending_pixel = 0;
	/* verilator lint_on UNUSED */


	reg screen_v_reset;
	initial screen_v_reset = 0;

	reg [3:0] palette_index;
	initial palette_index = 0;

	reg [9:0] row_offset;
	initial row_offset = 0;

	reg [8:0] cell_row_offset;
	initial cell_row_offset = 0;

	reg [9:0] cell_index;
	initial cell_index = 0;

	reg [8:0] pixel_counter;
	initial pixel_counter = 0;

	reg line_pad;
	initial line_pad = 0;


	// sprite write
	reg sprite_update_pending;
	reg [1:0] sprite_update_state;
	initial sprite_update_state = SPRITE_UPDATE_IDLE;
	localparam [1:0]
		SPRITE_UPDATE_IDLE = 0,
		SPRITE_LOAD_FOR_UPDATE = 1,
		SPRITE_UPDATE = 2,
		SPRITE_SAVE = 3;
	reg [3:0] sprite_write_index;
	reg [8:0] sprite_write_offset;
	reg [3:0] sprite_write_data;

	always @(posedge i_clk) begin
		pixel_write_pending <= 0;
		sprite_update_pending <= 0;
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
				pending_pixel <= {2'h0,instruction_args[15:10]};
				pixel_write_pending <= 1;
			end 
			SET_SPRITE: begin
				sprite_write_index <= instruction_args[3:0];
				sprite_write_offset <= {instruction_args[10:4], 2'h0};
				sprite_write_data <= instruction_args[14:11];
				sprite_update_pending <= 1;
			end
			default:;
			endcase
		end

		if (i_vsync) begin 
			bg_color <= pending_bg_color;
			pixel_row <= 0;
		end

		if (i_hsync) begin
			cell_index <= 0;
			pixel_counter <= 0;
		end else if (i_pixel_x_clock) begin
			
			if (pixel_counter > 8) pixel_counter <= 0;
			else begin
				if (pixel_counter > 7) cell_index <= cell_index + 1;
				pixel_counter <= pixel_counter + 1;
			end
		end

		if (i_screen_reset) begin
			cell_index <= 0;
			pixel_counter <= 0;
			pixel_row <= 0;
			pixel_row_counter <= 24;
			row_offset <= 0;
			cell_row_offset <= 0;
			line_pad <= 0;
		end

		if (i_pixel_y_clock) begin
			pixel_row_counter <= pixel_row_counter - 1;
			
			// do 2 lines per pixel
			if (line_pad) cell_row_offset <= cell_row_offset + 40;
			line_pad <= ~line_pad;

			if (pixel_row_counter == 1) begin
				cell_index <= 0;
				pixel_counter <= 0;
				pixel_row <= pixel_row + 1;
				pixel_row_counter <= 24;
				row_offset <= row_offset + 30;
				cell_row_offset <= 0;
				line_pad <= 0;
			end
			screen_v_reset <= 1'b1;
		end

		if (screen_v_reset) begin
			screen_v_reset <= 1'b0;
		end

	end

	// lets try to use simple registers as screen buffer
	reg	[7:0]	screen_buffer	[0:599];

	// For loops require integer indices
	integer		k;
	// integer		j;

	initial begin
		for(k=0; k<599; k=k+8) begin
			screen_buffer[k] = 0;
			// for (j=0; j<16; j=j+1) begin
			// 	 + j] = j;
			// end
		end
	end

	/* verilator lint_off UNUSED */
	reg [7:0] sprite_index;
	initial sprite_index = 0;
	/* verilator lint_on UNUSED */

	always @(posedge i_clk)
		// palette_index[6:0] <= {screen_buffer[row_offset + pixel_index], 4'b0};
		sprite_index <= screen_buffer[row_offset + cell_index];
		// palette_index[2:0] <= screen_buffer[row_offset + cell_index];


	// reg [119:0] sprites [8];
	// initial begin
	// 	for(k=0; k<8; k=k+1) begin
	// 		sprites[k] = {
	// 			{10'b1111111111},
	// 			{10'b0000000000},
	// 			{10'b0111111110},
	// 			{10'b0000110000},
	// 			{10'b0000110000},
	// 			{10'b0110110000},
	// 			{10'b0000110110},
	// 			{10'b0000110000},
	// 			{10'b0000110000},
	// 			{10'b0011111100},
	// 			{10'b0000000000},
	// 			{10'b0000000000}
	// 		};
	// 	end
	// end

	reg [479:0] ext_sprites[16];
	initial begin
		for(k=0; k<64; k=k+1) begin
			ext_sprites[k] = {
				{40'h1111111111},
				{40'h0000000000},
				{40'h0111881110},
				{40'h0000990000},
				{40'h0000aa0000},
				{40'h0110bb0000},
				{40'h0000cc0110},
				{40'h0000dd0000},
				{40'h0000ee0000},
				{40'h0011ff1100},
				{40'h0000000000},
				{40'h0000000000}
			};
		end
	end

	/* verilator lint_off UNUSED */
	reg [119:0] current_sprite;
	/* verilator lint_on UNUSED */
	reg [479:0] current_ext_sprite;
	initial current_sprite = 0;
	initial current_ext_sprite = 0;

	always @(posedge i_clk) begin
		// we hav pixel index too
		// current_sprite <= sprites[sprite_index];
		// current_ext_sprite <= ext_sprites[sprite_index];
		current_ext_sprite <= ext_sprites[sprite_index[3:0]];
	end

	always @(posedge i_clk) begin
		// we have a pixel index too
		// palette_index[2:0] <= current_sprite[119 - (cell_row_offset + pixel_counter)] 
		// 	? (sprite_index == 0 ? 4 : sprite_index) : 3'h0;
		palette_index[3:0] <= current_ext_sprite[479 - (cell_row_offset + (pixel_counter << 2)) -:  4];
	end

	always @(posedge i_clk)
		o_color <= palette[palette_index];

	always @(posedge i_clk)
		if (pixel_write_pending) screen_buffer[arg_pixel_index] <= pending_pixel;

	reg [479:0] sprite_being_updated;
	always @(posedge i_clk) begin
		// sprite_update_pending <= 1'b1;
		if (sprite_update_pending) sprite_update_state <= SPRITE_LOAD_FOR_UPDATE;

		case (sprite_update_state)
			SPRITE_UPDATE_IDLE:;
			SPRITE_LOAD_FOR_UPDATE: begin
				// sprite_write_index <= instruction_args[8:0];
				sprite_being_updated <= ext_sprites[sprite_write_index];
				sprite_update_state <= SPRITE_UPDATE;
			end
			SPRITE_UPDATE: begin
				// update sprite inline here...
				// sprite_write_offset <= instruction_args[15:9];
				// sprite_write_data <= instruction_args[23:16];
				sprite_being_updated[sprite_write_offset[8:0] +: 4] <= sprite_write_data;

				sprite_update_state <= SPRITE_SAVE;
			end
			SPRITE_SAVE: begin
				ext_sprites[sprite_write_index] <= sprite_being_updated;
				sprite_update_state <= SPRITE_UPDATE_IDLE;
			end
		endcase
	end


	// assign palette_index[6:0] = {screen_buffer[row_offset + pixel_index +: 3], 4'b0};

	reg [11:0] palette [16];
	initial begin
		palette[0] = 12'h000;
		palette[1] = 12'hfff;
		palette[2] = 12'hf00;
		palette[3] = 12'h0f0;
		palette[4] = 12'h00f;
		palette[5] = 12'hf0f;
		palette[6] = 12'h0ff;
		palette[7] = 12'hff0;
		palette[8] = 12'h444;
		palette[9] = 12'hbbb;
		palette[10] = 12'h700;
		palette[11] = 12'h070;
		palette[12] = 12'h007;
		palette[13] = 12'h707;
		palette[14] = 12'h077;
		palette[15] = 12'h770;
	end

	// reg [119:0] sprites [8];


endmodule