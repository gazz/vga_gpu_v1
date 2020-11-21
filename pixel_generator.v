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

	localparam [3:0] SET_BG_COLOR = 4'h01,
		SET_RED_BG_COLOR = 4'h02,
		SET_GREEN_BG_COLOR = 4'h03,
		SET_BLUE_BG_COLOR = 4'h04,
		SET_BLACK_BG_COLOR = 4'h05,
		SET_WHITE_BG_COLOR = 4'h06,
		SET_PIXEL = 4'h07,
		SET_SPRITE = 4'h08;

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
	/* verilator lint_off UNUSED */
	reg [31:0] l_instruction;
	/* verilator lint_on UNUSED */
	reg l_instruction_ready;

	always @(posedge i_clk) begin
		l_instruction_ready <= i_instruction_ready;
		if (i_instruction_ready) l_instruction[31:0] <= i_instruction[31:0];
		else l_instruction[31:0] <= 32'h0;
	end

	/* verilator lint_off UNUSED */
	reg pixel_write_pending;
	initial pixel_write_pending = 0;
	reg [9:0] arg_pixel_index;
	initial arg_pixel_index = 0;
	reg [6:0] pending_pixel;
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
	reg [3:0] cell_row;
	initial cell_row = 0;

	reg [9:0] cell_index;
	initial cell_index = 0;

	reg [5:0] pixel_counter;
	initial pixel_counter = 0;

	reg line_pad;
	initial line_pad = 0;


	// sprite write
	/* verilator lint_off UNUSED */
	reg sprite_update_pending;
	reg [9:0] sprite_write_line_index;
	reg [5:0] sprite_write_offset;
	reg [7:0] sprite_write_data;
	/* verilator lint_on UNUSED */

	always @(posedge i_clk) begin
		pixel_write_pending <= 0;
		sprite_update_pending <= 0;
		if (l_instruction_ready) begin
			case (l_instruction[3:0])
			SET_BG_COLOR: begin
				pending_bg_color <= l_instruction[19:8];
			end
			SET_RED_BG_COLOR: pending_bg_color <= 12'hf00;
			SET_GREEN_BG_COLOR: pending_bg_color <= 12'h0f0;
			SET_BLUE_BG_COLOR: pending_bg_color <= 12'h00f;
			SET_BLACK_BG_COLOR: pending_bg_color <= 12'h000;
			SET_WHITE_BG_COLOR: pending_bg_color <= 12'hfff;
			SET_PIXEL: begin
				pixel_write_pending <= 1;
				arg_pixel_index <= l_instruction[17:8];
				pending_pixel <= l_instruction[24:18];
			end 
			SET_SPRITE: begin
				sprite_update_pending <= 1;

				// unsigned char arg0 = pixel_data;
				// unsigned char arg1 = (offsetY << 4) + (offsetX & 0xf);
				// unsigned char arg2 = sprite_index & 0xff;



				// something not right
				// sprite_write_line_index <= {l_instruction[15:8], 2'h0} + {l_instruction[14:8], 2'h0}
				// 	+ {6'h0, l_instruction[19:16]};
				// sprite_write_line_index <= 0;

				// 16 sprite input should result in 16 * 12 = 192
				// sprite_write_line_index <= ({4'h0, l_instruction[15:8]} << 3) + ({4'h0, l_instruction[15:8]} << 2);
				// sprite_write_line_index <= ({3'h0, l_instruction[14:8]} << 3) + ({3'h0, l_instruction[14:8]} << 2)
				// 	+ {6'h0, l_instruction[23:20]};
				sprite_write_line_index <= ({3'h0, l_instruction[14:8]} << 3) + ({3'h0, l_instruction[14:8]} << 2) 
					+ {6'h0, l_instruction[23:20]};

				// sprite_write_line_index <= {l_instruction[15:8], 3'h0} + {l_instruction[14:8], 2'h0};
					// + {6'h0, l_instruction[19:16]};


				sprite_write_offset <= (39 - {l_instruction[19:16], 2'h0});
				sprite_write_data <= l_instruction[31:24];
			end
			default:;
			endcase
		end
	end

	always @(posedge i_clk) begin
		// if (pxi)
	end	

	always @(posedge i_clk) begin
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
				if (pixel_counter == 5) cell_index <= cell_index + 1;
				pixel_counter <= pixel_counter + 1;
			end
		end

		if (i_screen_reset) begin
			cell_index <= 0;
			pixel_counter <= 0;
			pixel_row <= 0;
			pixel_row_counter <= 24;
			row_offset <= 0;
			cell_row <= 0;
			cell_row_offset <= 0;
			line_pad <= 0;
		end

		if (i_pixel_y_clock) begin
			pixel_row_counter <= pixel_row_counter - 1;
			
			// do 2 lines per pixel
			if (line_pad) begin 
				cell_row <= cell_row + 1;
				cell_row_offset <= cell_row_offset + 40;
			end 
			line_pad <= ~line_pad;

			if (pixel_row_counter == 1) begin
				cell_index <= 0;
				pixel_counter <= 0;
				pixel_row <= pixel_row + 1;
				pixel_row_counter <= 24;
				row_offset <= row_offset + 30;
				cell_row <= 0;
				cell_row_offset <= 0;
				line_pad <= 0;
			end
			screen_v_reset <= 1'b1;
		end

		if (screen_v_reset) begin
			screen_v_reset <= 1'b0;
		end

	end


	// this greatly affects how much memory we have
	localparam screen_buffer_size = 600;
	localparam sprite_count = 85;

	reg	[6:0]	screen_buffer	[screen_buffer_size];
	// For loops require integer indices
	integer		k;
	integer		j;
	initial begin
		for(k=0; k<screen_buffer_size-1; k=k+sprite_count) begin
			for (j=0; j<sprite_count && k+j < screen_buffer_size; j=j+1)
				screen_buffer[k+j] = j[6:0];
		end
	end

	/* verilator lint_off UNUSED */
	reg [6:0] sprite_index;
	initial sprite_index = 0;
	/* verilator lint_on UNUSED */

	reg [9:0] read_access_index;
	always @(posedge i_clk)
		read_access_index <= row_offset + cell_index;

	always @(posedge i_clk)
		sprite_index <= screen_buffer[read_access_index];

	reg [39:0] ext_sprites_12lines[sprite_count * 12]; // 192 lines
	initial begin
		for(k=0; k<sprite_count * 12; k=k+96) begin

			ext_sprites_12lines[k] = 	 {40'h0033003300};
			ext_sprites_12lines[k + 1] = {40'h0000000000};
			ext_sprites_12lines[k + 2] = {40'h0111881110};
			ext_sprites_12lines[k + 3] = {40'h0000990000};
			ext_sprites_12lines[k + 4] = {40'h0000cd0000};
			ext_sprites_12lines[k + 5] = {40'h0770bb0000};
			ext_sprites_12lines[k + 6] = {40'h0000cc0770};
			ext_sprites_12lines[k + 7] = {40'h0000dd0000};
			ext_sprites_12lines[k + 8] = {40'h0000ee0000};
			ext_sprites_12lines[k + 9] = {40'h0011ff1100};
			ext_sprites_12lines[k + 10] = {40'h0333553330};
			ext_sprites_12lines[k + 11] = {40'h0000000000};

			ext_sprites_12lines[k + 24] = {40'h0000000000};
			ext_sprites_12lines[k + 25] = {40'h0077777700};
			ext_sprites_12lines[k + 26] = {40'h0700000070};
			ext_sprites_12lines[k + 27] = {40'h7000000007};
			ext_sprites_12lines[k + 28] = {40'h7007007007};
			ext_sprites_12lines[k + 29] = {40'h7000000007};
			ext_sprites_12lines[k + 30] = {40'h7000000007};
			ext_sprites_12lines[k + 31] = {40'h7070000707};
			ext_sprites_12lines[k + 32] = {40'h7007777007};
			ext_sprites_12lines[k + 33] = {40'h0700000070};
			ext_sprites_12lines[k + 34] = {40'h0077777700};
			ext_sprites_12lines[k + 35] = {40'h0000000000};
		end
	end

	reg [39:0] current_ext_sprite_line;
	initial current_ext_sprite_line = 0;

	reg [9:0] sprite_line_index;
	always @(posedge i_clk)
		sprite_line_index <= ({3'h0, sprite_index[6:0]} << 2)
			 + ({3'h0, sprite_index[6:0]} << 3) + {5'h0, cell_row};

	always @(posedge i_clk)
		current_ext_sprite_line <= ext_sprites_12lines[sprite_line_index];

	always @(posedge i_clk)
		palette_index[3:0] <= current_ext_sprite_line[(39 - (pixel_counter << 2)) -: 4];

	always @(posedge i_clk)
		o_color <= palette[palette_index];

	always @(posedge i_clk)
		if (pixel_write_pending) screen_buffer[arg_pixel_index] <= pending_pixel;


	reg [2:0] sprite_update_state;
	initial sprite_update_state = SPRITE_UPDATE_IDLE;
	localparam [2:0]
		SPRITE_UPDATE_IDLE = 0,
		SPRITE_LOAD_FOR_UPDATE = 1,
		SPRITE_LOADED = 2,
		SPRITE_UPDATE = 3,
		SPRITE_SAVE = 4,
		SPRITE_PAD = 5,
		SPRITE_RELOAD = 6;
	reg [39:0] sprite_line_being_updated;
	/* verilator lint_off UNUSED */
	reg [39:0] flushable_sprite;
	/* verilator lint_on UNUSED */

	always @(posedge i_clk) begin

		if (sprite_update_pending) begin
			sprite_update_state <= SPRITE_LOAD_FOR_UPDATE;
		end

		case (sprite_update_state)
			SPRITE_UPDATE_IDLE:;
			SPRITE_LOAD_FOR_UPDATE: begin
				sprite_update_state <= SPRITE_LOADED;
			end
			SPRITE_LOADED: begin
				sprite_update_state <= SPRITE_UPDATE;
				flushable_sprite <= sprite_line_being_updated;
			end
			SPRITE_UPDATE: begin
				sprite_update_state <= SPRITE_SAVE;
				flushable_sprite[sprite_write_offset -: 8] <= sprite_write_data;
			end
			SPRITE_SAVE: begin
				sprite_update_state <= SPRITE_PAD;
			end
			SPRITE_PAD: begin
				if (some_flag) sprite_update_state <= SPRITE_RELOAD;
			end
			SPRITE_RELOAD: begin
				sprite_update_state <= SPRITE_UPDATE_IDLE;
			end
			default:;
		endcase
	end


	always @(posedge i_clk)
		if (sprite_update_state == SPRITE_LOAD_FOR_UPDATE
			|| sprite_update_state == SPRITE_RELOAD)
			sprite_line_being_updated <= ext_sprites_12lines[sprite_write_line_index];
		// else sprite_line_being_updated <= 40'h0;

	reg some_flag;
	always @(posedge i_clk)
		if (sprite_update_state == SPRITE_SAVE) begin
			// ext_sprites_12lines[sprite_write_line_index] <= 40'hff00ff;//flushable_sprite[39:0];
			ext_sprites_12lines[sprite_write_line_index] <= flushable_sprite;
			some_flag <= 1;
		end else some_flag <= 0;

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


endmodule