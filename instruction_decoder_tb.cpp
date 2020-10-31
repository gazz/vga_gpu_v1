#include <stdio.h>
#include <stdlib.h>
#include "Vinstruction_decoder.h"
#include "verilated_vcd_c.h"
#include "verilated.h"

void	tick(int tickcount, Vinstruction_decoder *tb, VerilatedVcdC* tfp) {
	tb->eval();
	if (tfp)
		tfp->dump(tickcount * 10 - 2);
	tb->i_clk = 1;
	tb->eval();
	if (tfp)
		tfp->dump(tickcount * 10);
	tb->i_clk = 0;
	tb->eval();
	if (tfp) {
		tfp->dump(tickcount * 10 + 5);
		tfp->flush();
	}
	printf("i_we: %d, i_en: %d, o_ack: %d, o_set_mode: %d, o_set_pixel: %x, o_busy: %d\n", 
		tb->i_we, tb->i_en, tb->o_ack, tb->o_set_mode, tb->o_set_pixel, tb->o_busy);
}

void set_display_mode(unsigned &tickcount, Vinstruction_decoder *tb, VerilatedVcdC* tfp);

void set_pixel_color(unsigned &tickcount, Vinstruction_decoder *tb, VerilatedVcdC* tfp);


int main(int argc, char **argv) {
	unsigned tickcount = 0;

	// Call commandArgs first!
	Verilated::commandArgs(argc, argv);

	// Instantiate our design
	Vinstruction_decoder *tb = new Vinstruction_decoder;

	// Generate a trace
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb->trace(tfp, 99);
	tfp->open("instruction_decoder.vcd");

// i_clk, i_we, i_en, i_data, o_ack,
// 	// signal generator instructions
// 	// pixel generator instructions
// 	);

	tb->i_we = 1;
	tb->i_en = 1;
	tb->i_data = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);


	set_display_mode(tickcount, tb, tfp);

	while (tb->o_busy) tick(++tickcount, tb, tfp);

	set_pixel_color(tickcount, tb, tfp);

	while (tb->o_busy) tick(++tickcount, tb, tfp);

}


void set_display_mode(unsigned &tickcount, Vinstruction_decoder *tb, VerilatedVcdC* tfp) {
	// set display mode
	tb->i_we = 0;
	tb->i_data = 1;
	tick(++tickcount, tb, tfp);

	tb->i_en = 0;
	tick(++tickcount, tb, tfp);

	tb->i_en = 1;	
	tick(++tickcount, tb, tfp);

	tb->i_data = 11;
	tick(++tickcount, tb, tfp);

	tb->i_en = 0;
	tick(++tickcount, tb, tfp);

	tb->i_en = 1;	
	tick(++tickcount, tb, tfp);

	tb->i_we = 1;
	while (!tb->o_set_mode) tick(++tickcount, tb, tfp);
	printf("Set Mode: %d, Mode: %d\n", tb->o_set_mode, tb->o_mode);
	while (tb->o_set_mode) tick(++tickcount, tb, tfp);
	printf("Set Mode: %d, Mode: %d\n", tb->o_set_mode, tb->o_mode);
}

void set_pixel_color(unsigned &tickcount, Vinstruction_decoder *tb, VerilatedVcdC* tfp) {
	// set display mode
	tb->i_we = 0;
	tb->i_data = 2;
	tick(++tickcount, tb, tfp);

	tb->i_en = 0;
	tick(++tickcount, tb, tfp);

	tb->i_en = 1;	
	tick(++tickcount, tb, tfp);

	// next 12 bits are color LSB
	tb->i_data = 0x12;
	tick(++tickcount, tb, tfp);
	tb->i_en = 0;
	tick(++tickcount, tb, tfp);

	tb->i_en = 1;	
	tick(++tickcount, tb, tfp);

	tb->i_data = 0x34;
	tick(++tickcount, tb, tfp);
	tb->i_en = 0;
	tick(++tickcount, tb, tfp);

	tb->i_en = 1;	
	tick(++tickcount, tb, tfp);

	tb->i_we = 1;
	while (!tb->o_set_pixel) tick(++tickcount, tb, tfp);
	// 	o_pixel_x, o_pixel_y, o_color, o_set_pixel
	printf("Set Pixel: %d, X: %d, Y: %d, color: %x\n", 
		tb->o_set_pixel, tb->o_pixel_x, tb->o_pixel_y, tb->o_color);
	while (tb->o_set_pixel) tick(++tickcount, tb, tfp);
	printf("Set Pixel: %d, X: %d, Y: %d, color: %x\n", 
		tb->o_set_pixel, tb->o_pixel_x, tb->o_pixel_y, tb->o_color);
}
