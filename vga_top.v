`default_nettype none

module vga_top(CLK12,
	DATA_0, DATA_1, DATA_2, DATA_3, DATA_4, DATA_5, DATA_6, DATA_7,
	CNTR_WE, CNTR_EN, CNTR_ACK, CNTR_BUSY,
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
	output wire CNTR_ACK, CNTR_BUSY;

	wire [7:0] i_data;
	wire [3:0] o_red;
	wire [3:0] o_green;
	wire [3:0] o_blue;

	assign i_data[7:0] = {DATA_7, DATA_6, DATA_5, DATA_4, DATA_3, DATA_2, DATA_1, DATA_0};
	// assign {VGA_R0,VGA_R1,VGA_R2,VGA_R3} = o_red;
	assign {VGA_R3,VGA_R2,VGA_R1,VGA_R0} = o_red[3:0];
	assign {VGA_G3,VGA_G2,VGA_G1,VGA_G0} = o_green[3:0];
	assign {VGA_B3,VGA_B2,VGA_B1,VGA_B0} = o_blue[3:0];

	wire inv_cntr_ack;
	assign CNTR_ACK = !inv_cntr_ack;
	reg inv_cntr_busy;
	assign CNTR_BUSY = !inv_cntr_busy;

	vga_gpu wiring(.i_clk(CLK12),
		.i_we(CNTR_WE), .i_en(CNTR_EN), .i_data(i_data), .o_ack(inv_cntr_ack), .o_busy(inv_cntr_busy),
		.o_hsync(VGA_H_SYNC), .o_vsync(VGA_V_SYNC),
		.o_red(o_red), .o_green(o_green), .o_blue(o_blue));

endmodule


/*
module top(CLK12,
	VGA_H_SYNC, VGA_V_SYNC);
	input wire CLK12;
	output reg VGA_H_SYNC;
	output reg VGA_V_SYNC;
	initial VGA_H_SYNC = 1'b1;
	initial VGA_V_SYNC = 1'b0;

	always @(posedge CLK12) begin
		VGA_H_SYNC <= VGA_V_SYNC;
		VGA_V_SYNC <= VGA_H_SYNC;
	end

endmodule
*/
