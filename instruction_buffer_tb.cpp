#include <stdio.h>
#include <stdlib.h>
#include "Vinstruction_buffer.h"
#include "verilated_vcd_c.h"
#include "verilated.h"

void	tick(int tickcount, Vinstruction_buffer *tb, VerilatedVcdC* tfp) {
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
	printf("i_we: %d, i_en: %d, o_ack: %d, o_ready: %d, o_instruction: %x\n", tb->i_we, tb->i_en, tb->o_ack, tb->o_ready, tb->o_instruction);
}

int main(int argc, char **argv) {
	unsigned tickcount = 0;

	// Call commandArgs first!
	Verilated::commandArgs(argc, argv);

	// Instantiate our design
	Vinstruction_buffer *tb = new Vinstruction_buffer;

	// Generate a trace
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb->trace(tfp, 99);
	tfp->open("instruction_buffer.vcd");

	// lets simulate
	tb->i_we = 1;
	tb->i_en = 1;
	tb->i_data = 0;
	tick(++tickcount, tb, tfp);
	tick(++tickcount, tb, tfp);

	for (int i = 0; i < 3; i++ ) {
		tb->i_we = 0;
		tb->i_data = 3 + i;
		tick(++tickcount, tb, tfp);

		tb->i_en = 0;
		tick(++tickcount, tb, tfp);

		tb->i_en = 1;
		tick(++tickcount, tb, tfp);

		tb->i_data = 8 + i;
		tick(++tickcount, tb, tfp);

		tb->i_en = 0;
		tick(++tickcount, tb, tfp);

		tb->i_en = 1;
		tick(++tickcount, tb, tfp);

		tb->i_data = 5 + i;
		tick(++tickcount, tb, tfp);

		tb->i_en = 0;
		tick(++tickcount, tb, tfp);

		tb->i_en = 1;
		tick(++tickcount, tb, tfp);

		tb->i_data = 12 + i;
		tick(++tickcount, tb, tfp);

		tb->i_en = 0;
		tick(++tickcount, tb, tfp);

		tb->i_en = 1;
		tick(++tickcount, tb, tfp);


		tb->i_we = 1;
		tick(++tickcount, tb, tfp);
		tick(++tickcount, tb, tfp);
		tick(++tickcount, tb, tfp);

		printf("Instruction: %d; arg0: %d; arg1: %d; arg2: %d\n",
			(tb->o_instruction & 0xff),
			((tb->o_instruction >> 8) & 0xff),
			((tb->o_instruction >> 16) & 0xff),
			((tb->o_instruction >> 24) & 0xff));
	}
}
