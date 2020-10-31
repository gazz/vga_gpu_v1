`default_nettype none

module vga_gpu(i_clk, 
	// 11bit bus in
	i_we, i_en, i_data, o_ack, 
	// vga signal out
	o_hsync, o_vsync, o_red, o_green, o_blue);


	input wire i_clk;
	input wire i_we;
	input wire i_en;
	input wire [7:0] i_data;
	input wire o_ack;
	output wire o_hsync;
	output wire o_vsync;
	output wire [3:0] o_red;
	output wire [3:0] o_green;
	output wire [3:0] o_blue;

	wire [7:0] o_mode;
	wire o_set_mode;

	wire [9:0] o_pixel_x;
	wire [9:0] o_pixel_y;
	wire [11:0] o_color;
	wire o_set_pixel;

	wire o_busy;

	assign o_hsync = o_busy;

	instruction_decoder decoder(.i_clk(i_clk),
		.i_we(i_we), .i_en(i_en), .i_data(i_data), .o_ack(o_ack),
		.o_mode(o_mode), .o_set_mode(o_set_mode),
		.o_pixel_x(o_pixel_x), .o_pixel_y(o_pixel_y), .o_color(o_color), .o_set_pixel(o_set_pixel),
		.o_busy(o_busy)
		);	

endmodule


module top(CLK12,
	DATA_0, DATA_1, DATA_2, DATA_3, DATA_4, DATA_5, DATA_6, DATA_7,
	CNTR_WE, CNTR_EN,
	VGA_H_SYNC, VGA_V_SYNC,
	VGA_R0,VGA_R1,VGA_R2,VGA_R3,
	VGA_G0,VGA_G1,VGA_G2,VGA_G3,
	VGA_B0,VGA_B1,VGA_B2,VGA_B3);

	input wire CLK12;
	input wire DATA_0, DATA_1, DATA_2, DATA_3, DATA_4, DATA_5, DATA_6, DATA_7;
	input wire CNTR_WE, CNTR_EN;
	output wire VGA_H_SYNC, VGA_V_SYNC;
	output wire VGA_R0,VGA_R1,VGA_R2,VGA_R3,
		VGA_G0,VGA_G1,VGA_G2,VGA_G3,
		VGA_B0,VGA_B1,VGA_B2,VGA_B3;

	wire [7:0] i_data;
	wire [3:0] o_red;
	wire [3:0] o_green;
	wire [3:0] o_blue;
	reg o_ack;

	assign {DATA_0, DATA_1, DATA_2, DATA_3, DATA_4, DATA_5, DATA_6, DATA_7} = i_data;
	assign {VGA_R0,VGA_R1,VGA_R2,VGA_R3} = o_red;
	assign {VGA_G0,VGA_G1,VGA_G2,VGA_G3} = o_green;
	assign {VGA_B0,VGA_B1,VGA_B2,VGA_B3} = o_blue;

	vga_gpu wiring(.i_clk(CLK12),
		.i_we(CNTR_WE), .i_en(CNTR_EN), .i_data(i_data), .o_ack(o_ack),
		.o_hsync(VGA_H_SYNC), .o_vsync(VGA_V_SYNC),
		.o_red(o_red), .o_green(o_green), .o_blue(o_blue));

endmodule

