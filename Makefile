.PHONY: formal
.PHONY: all
.DELETE_ON_ERROR:
TOPMOD  := instruction_decoder
VLOGFIL := $(TOPMOD)
VCDFILE := $(TOPMOD).vcd
SIMPROG := $(TOPMOD)_tb
SIMFILE := $(SIMPROG).cpp
VDIRFB  := ./obj_dir
all: $(VCDFILE)

GCC := g++
CFLAGS = -g -Wall -I$(VINC) -I $(VDIRFB) -std=gnu++14 

VERILATOR=verilator
VFLAGS := -O3 -MMD --trace -Wall

VERILATOR_ROOT ?= $(shell bash -c '$(VERILATOR) -V|grep VERILATOR_ROOT | head -1 | sed -e "s/^.*=\s*//"')
VINC := $(VERILATOR_ROOT)/include

$(VDIRFB)/V$(TOPMOD).cpp: $(VLOGFIL).v
	$(VERILATOR) $(VFLAGS) -cc $(VLOGFIL)

$(VDIRFB)/V$(TOPMOD)__ALL.a: $(VDIRFB)/V$(TOPMOD).cpp
	make --no-print-directory -C $(VDIRFB) -f V$(TOPMOD).mk

$(SIMPROG): $(SIMFILE) $(VDIRFB)/V$(TOPMOD)__ALL.a $(COSIMS)
	$(GCC) $(CFLAGS) $(VINC)/verilated.cpp				\
		$(VINC)/verilated_vcd_c.cpp $(SIMFILE) $(COSIMS)	\
		$(VDIRFB)/V$(TOPMOD)__ALL.a -o $(SIMPROG)

$(VCDFILE): $(SIMPROG)
	./$(SIMPROG)
	
	
.PHONY: clean
clean:
	rm -rf $(VDIRFB)/ $(SIMPROG) $(VCDFILE) *_cvr *_prf *.dSYM

DEPS := $(wildcard $(VDIRFB)/*.d)

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif

formal:
	sby -f instruction_buffer.sby

TOP_MODULE := vga_gpu
VDEPS  := instruction_decoder.v instruction_buffer.v signal_generator.v pixel_generator.v
# VDEPS  := signal_generator.v
# VDEPS  := 
.PHONY: bin
bin: $(TOP_MODULE).rpt $(TOP_MODULE).bin

$(TOP_MODULE).json: $(TOP_MODULE).v $(VDEPS)
	yosys -ql $(TOP_MODULE).yslog -p 'synth_ice40 -top top -json $@' $^

$(TOP_MODULE).asc: $(TOP_MODULE).json ice40.pcf
	nextpnr-ice40 -ql $(TOP_MODULE).nplog --up5k --package sg48 --freq 12 --asc $@ --pcf ice40.pcf --top top --json $<

$(TOP_MODULE).bin: $(TOP_MODULE).asc
	icepack $< $@

$(TOP_MODULE).rpt: $(TOP_MODULE).asc
	icetime -d up5k -c 12 -mtr $@ $<

.PHONY: prog
prog: bin
	iceprog $(TOP_MODULE).bin
