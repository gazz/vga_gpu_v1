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
void set_cell(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int pixel, int sprite_index);

void set_sprite(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, unsigned char sprite_index, unsigned char sprite[60]);

unsigned char mySprite[120] = {
  0xa,1,1,0xb,0xc,1,1,0xd,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1
};

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

	// set_pixel(tickcount, tb, tfp, 3, 1);

	// set_sprite(tickcount, tb, tfp, 0, mySprite);

	set_sprite(tickcount, tb, tfp, 5, mySprite);

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

void set_cell(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, int cell_index, int sprite_index) {
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

	set_data_byte(tb, (sprite_index << 2 | cell_index >> 8));
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	set_data_byte(tb, cell_index & 0xff);
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


void set_sprite_pixels(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, unsigned char sprite_index, unsigned char offset, unsigned char pixel_data) {

	unsigned char arg0 = pixel_data >> 4;
	unsigned char offsetX = offset % 10;
	unsigned char offsetY = offset / 10;
	unsigned char arg1 = ((pixel_data << 4) & 0xff) + (offsetY & 0xf);
	unsigned char arg2 = ((offsetX << 4) & 0xff) + (sprite_index & 0xf);


	printf("sprite_index: %d, offset: %d, \targ0: %x, arg1: %x, arg2: %x:: pixel_data: %x\n", 
		sprite_index, offset, arg0, arg1, arg2, pixel_data);


		// instruction
	set_data_byte(tb, 8);
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

	// 1st byte
	set_data_byte(tb, arg0);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	// 2nd byte
	set_data_byte(tb, arg1);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	tb->CNTR_EN = 1;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	// 3rd byte
	set_data_byte(tb, arg2);
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

void set_sprite(unsigned &tickcount, Vvga_top *tb, VerilatedVcdC* tfp, unsigned char sprite_index, unsigned char sprite[120]) {
	for (int i = 0; i < 120; i+=2) {
		unsigned char sprite_pixel = sprite[i];
		unsigned char sprite_pixel2 = sprite[i+1];
		unsigned char combined_pixels = ((sprite_pixel << 4) & 0xff) + (sprite_pixel2 & 0xf);
		printf("Pixel tuple: 0: %x, 1: %x, combined: %x\t", sprite_pixel, sprite_pixel2, combined_pixels); 

		set_sprite_pixels(tickcount, tb, tfp, sprite_index, i, combined_pixels);
	}
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

