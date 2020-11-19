#include <stdio.h>
#include <stdlib.h>
#include "Vvga_top.h"
#include "verilated_vcd_c.h"
#include "verilated.h"

void	tick(int tickcount, Vvga_top *tb, VerilatedVcdC* tfp) {
	tb->eval();
	if (tfp)
		tfp->dump(tickcount * 10 - 2);
	tb->CLK12 = 1;
	tb->eval();
	if (tfp)
		tfp->dump(tickcount * 10);
	tb->CLK12 = 0;
	tb->eval();
	if (tfp) {
		tfp->dump(tickcount * 10 + 5);
		tfp->flush();
	}
	// printf("i_we: %d, i_en: %d, o_ack: %d, o_set_mode: %d, o_set_pixel: %x, o_busy: %d\n", 
	// 	tb->i_we, tb->i_en, tb->o_ack, tb->o_set_mode, tb->o_set_pixel, tb->o_busy);
}

void set_data_byte(Vvga_top *tb, short b) {
	tb->DATA_0 = b & 1;
	tb->DATA_1 = (b >> 1) & 1;
	tb->DATA_2 = (b >> 2) & 1;
	tb->DATA_3 = (b >> 3) & 1;
	tb->DATA_4 = (b >> 4) & 1;
	tb->DATA_5 = (b >> 5) & 1;
	tb->DATA_6 = (b >> 6) & 1;
	tb->DATA_7 = (b >> 7) & 1;
}

void set_bg(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int bg);
void set_pixel(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int pixel, int palette_index);

int main(int argc, char **argv) {
	unsigned tickcount = 0;

	// Call commandArgs first!
	Verilated::commandArgs(argc, argv);

	// Instantiate our design
	Vvga_top *tb = new Vvga_top;

	// Generate a trace
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb->trace(tfp, 99);
	tfp->open("vga_top.vcd");

	set_pixel(tickcount, tb, tfp, 3, 1);

	// tb->CNTR_WE = 1;
	// tb->CNTR_EN = 1;
	// set_data_byte(tb, 0);
	// tick(++tickcount, tb, tfp);

	// set_bg(tickcount, tb, tfp, 0xabc);

	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);

	// // return 0;

	// while (!tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	// set_bg(tickcount, tb, tfp, 0x987);

	// while (!tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	// set_bg(tickcount, tb, tfp, 0x345);

	// while (!tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);
	// tick(++tickcount, tb, tfp);


	// set_pixel_color(tickcount, tb, tfp);

	// while (tb->o_busy) tick(++tickcount, tb, tfp);


	// simulate VGA for 12Mhz & 60 clokcs
	// int num_ticks = 12000000 / 60;
	int num_ticks = 12000000 / 30;
	for (int i = 0; i< num_ticks; i++) {
		tick(++tickcount, tb, tfp);
	}

}

void set_pixel(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int pixel, int palette_index) {
	// instruction
	set_data_byte(tb, 7);
	tick(++tickcount, tb, tfp);

	tb->CNTR_WE = 0;
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, (palette_index << 2 | pixel >> 8));
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, pixel & 0xff);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_WE = 1;
	tick(++tickcount, tb, tfp);

	while (tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	while (!tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

}


void set_bg(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int bg) {
	// set display mode
	set_data_byte(tb, 1);
	tick(++tickcount, tb, tfp);

	tb->CNTR_WE = 0;
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, ((bg >> 8) & 0xff ));
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, (bg & 0xff));
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, 0xab);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);


	tb->CNTR_WE = 1;
	tick(++tickcount, tb, tfp);

	while (tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	while (!tb->CNTR_BUSY) tick(++tickcount, tb, tfp);

	// tb->i_en = 1;	
	// tick(++tickcount, tb, tfp);

	// tb->i_data = 11;
	// tick(++tickcount, tb, tfp);

	// tb->i_en = 0;
	// tick(++tickcount, tb, tfp);

	// tb->i_en = 1;	
	// tick(++tickcount, tb, tfp);

	// tb->i_we = 1;
	// while (!tb->o_set_mode) tick(++tickcount, tb, tfp);
	// printf("Set Mode: %d, Mode: %d\n", tb->o_set_mode, tb->o_mode);

	// while (tb->o_set_mode) tick(++tickcount, tb, tfp);
	// printf("Set Mode: %d, Mode: %d\n", tb->o_set_mode, tb->o_mode);
}

