`default_nettype none

module signal_generator(i_clk,
	o_screen_reset, o_pixel_x_clock, o_pixel_y_clock, i_color,
	o_hsync, o_vsync,
	o_red, o_green, o_blue,
	i_instruction, i_instruction_ready);
	
	input wire i_clk;

	output reg o_screen_reset;
	output reg o_pixel_x_clock;
	output reg o_pixel_y_clock;
	input wire [11:0] i_color;

	output wire o_hsync, o_vsync;
	output wire [3:0] o_red;
	output wire [3:0] o_green;
	output wire [3:0] o_blue;

	/* verilator lint_off UNUSED */
	input wire [31:0] i_instruction;
	input wire i_instruction_ready;
	/* verilator lint_on UNUSED */

	wire [9:0] hor_pixel_clocks;
	wire [9:0] ver_pixels;

	wire [9:0] hsync_front_porch_clocks;
	wire [9:0] hsync_active_clocks;
	wire [9:0] hsync_back_porch_clocks;

	wire [9:0] vsync_front_porch_lines;
	wire [9:0] vsync_active_lines;
	wire [9:0] vsync_back_porch_lines;

	// vga timing inpixels
	// 640x480, 60Hz 25.175Mhz	
	// 		active video	| front porch	| sync	| back porch
	// hor: 640				| 16			| 96	| 48
	// ver: 480				| 11			| 2		| 31
	// with 12MHz clock, 1 clock pulse => 0.083us
	// 640x480 pixel takes 0.039us, so ~2 pixels per pulse
	assign hor_pixel_clocks = 304; // horizontal resolution pixels
	assign hsync_front_porch_clocks = 8;
	assign hsync_active_clocks = 46;
	assign hsync_back_porch_clocks = 22;

	// parameter ver_clock_pad = 75;
	assign vsync_front_porch_lines = 15;
	assign vsync_active_lines = 3;
	assign vsync_back_porch_lines = 35;

	assign ver_pixels = 480; // vertical resolution pixels

	localparam [1:0] PIXEL_DATA = 2'h0,
 		HSYNC_FRONT_PORCH = 2'h1,
		HSYNC_ACTIVE = 2'h2,
		HSYNC_BACK_PORCH = 2'h3,
		VSYNC_FRONT_PORCH = 2'h1,
		VSYNC_ACTIVE = 2'h2,
		VSYNC_BACK_PORCH = 2'h3;

	assign {o_red, o_green, o_blue} = (hor_state == PIXEL_DATA && ver_state == PIXEL_DATA) ? i_color : 12'h0;
	assign o_hsync = (hor_state == HSYNC_ACTIVE) ? 1'b0 : 1'b1;
	assign o_vsync = (ver_state == VSYNC_ACTIVE) ? 1'b0 : 1'b1;

	initial o_pixel_x_clock = 1'b0;
	initial o_pixel_y_clock = 1'b0;
	initial o_screen_reset = 1'b0;

	reg [1:0] hor_state;
	reg [1:0] ver_state;
	initial hor_state = PIXEL_DATA;
	initial ver_state = PIXEL_DATA;

	reg [9:0] hor_counter;
	reg [4:0] pixel_counter;
	reg [4:0] line_counter;
	initial hor_counter = hor_pixel_clocks;
	reg [9:0] ver_counter;
	initial ver_counter = ver_pixels;

	always @(posedge i_clk) begin
		if (hor_counter == 1) begin
			hor_state <= hor_state + 1;
			case(hor_state)
			PIXEL_DATA: hor_counter <= hsync_front_porch_clocks;
			HSYNC_FRONT_PORCH: hor_counter <= hsync_active_clocks;
			HSYNC_ACTIVE: begin 
				if (ver_state == PIXEL_DATA) begin
					o_pixel_y_clock <= 1'b1;
				end
				hor_counter <= hsync_back_porch_clocks;
				ver_counter <= ver_counter - 1;

				if (line_counter == 0) begin
					line_counter <= 10;
				end line_counter <= line_counter - 1;
			end
			HSYNC_BACK_PORCH: begin
				hor_counter <= hor_pixel_clocks;
				pixel_counter <= 10;
				o_pixel_x_clock <= 1'b1;
			end
			endcase
		end else begin
			hor_counter <= hor_counter - 1;
			o_pixel_y_clock <= 1'b0;
			
			if (pixel_counter == 1) begin
				if (hor_state == PIXEL_DATA && ver_state == PIXEL_DATA) o_pixel_x_clock <= 1'b1;
				pixel_counter <= 10;
			end else begin
			 	pixel_counter <= pixel_counter - 1;
				o_pixel_x_clock <= 1'b0;
			end
		end

		if (ver_counter == 1) begin
			ver_state <= ver_state + 1;
			
			case(ver_state)
			PIXEL_DATA: ver_counter <= vsync_front_porch_lines;
			VSYNC_FRONT_PORCH: ver_counter <= vsync_active_lines;
			VSYNC_ACTIVE: ver_counter <= vsync_back_porch_lines;
			VSYNC_BACK_PORCH: begin
				ver_counter <= ver_pixels;
				line_counter <= 10;
				o_screen_reset <= 1'b1;
			end
			endcase
		end else o_screen_reset <= 1'b0;

	end

endmodule

// vga signal
// pixels are 25.17 μs