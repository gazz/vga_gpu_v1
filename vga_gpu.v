`default_nettype none


module vga_gpu(i_clk, 
	// 11bit bus in
	i_we, i_en, i_data, o_ack, o_busy,
	// vga signal out
	o_hsync, o_vsync, o_red, o_green, o_blue);

	input wire i_clk;
	input wire i_we;
	input wire i_en;
	input wire [7:0] i_data;
	output wire o_ack;
	output wire o_hsync;
	output wire o_vsync;
	output wire [3:0] o_red;
	output wire [3:0] o_green;
	output wire [3:0] o_blue;

	wire [31:0] instruction;
	wire instruction_ready;
	output wire o_busy;

	instruction_decoder decoder(.i_clk(i_clk),
		.i_we(i_we), .i_en(i_en), .i_data(i_data), .o_ack(o_ack),
		.o_busy(o_busy),
		.o_instruction(instruction), .o_instruction_ready(instruction_ready));

	wire screen_reset;
	wire pixel_x_clock;
	wire pixel_y_clock;
	wire [11:0] color;

	pixel_generator pixels(.i_clk(i_clk),
		.i_vsync(!o_vsync), .i_hsync(!o_hsync),
		.i_screen_reset(screen_reset), .i_pixel_x_clock(pixel_x_clock), .i_pixel_y_clock(pixel_y_clock), .o_color(color),
		.i_instruction(instruction), 
		.i_instruction_ready(instruction_ready));

	signal_generator signal(.i_clk(i_clk),
		.o_screen_reset(screen_reset), .o_pixel_x_clock(pixel_x_clock), .o_pixel_y_clock(pixel_y_clock), .i_color(color),
		.o_hsync(o_hsync), .o_vsync(o_vsync),
		.o_red(o_red), .o_green(o_green), .o_blue(o_blue),
		.i_instruction(instruction), 
		.i_instruction_ready(instruction_ready));

endmodule

