# Co-simulacion de top_level con Verilator + puerto serie virtual
#   make          compila
#   make run      compila y levanta el puerto en /tmp/ttyALU
#   make BAUD_RATE=115200 run

CLK_FREQ  ?= 100000000
BAUD_RATE ?= 19200
SRC_DIR   := ../ALU.srcs/sources_1/new

SRCS := $(SRC_DIR)/top_level.v \
        $(SRC_DIR)/baud_rate_generator.v \
        $(SRC_DIR)/uart_rx.v \
        $(SRC_DIR)/uart_tx.v \
        $(SRC_DIR)/interface.v \
        $(SRC_DIR)/ALU.v

VFLAGS := --cc --exe --build -O2 -j 0 \
          --top-module top_level \
          -Wno-fatal -Wno-WIDTH -Wno-UNUSED -Wno-DECLFILENAME \
          -GCLK_FREQ=$(CLK_FREQ) -GBAUD_RATE=$(BAUD_RATE) \
          -CFLAGS "-DCLK_FREQ=$(CLK_FREQ) -DBAUD_RATE=$(BAUD_RATE)"

BIN := obj_dir/Vtop_level

all: $(BIN)

$(BIN): $(SRCS) sim_main.cpp Makefile
	verilator $(VFLAGS) $(SRCS) sim_main.cpp

run: $(BIN)
	./$(BIN) /tmp/ttyALU

clean:
	rm -rf obj_dir

.PHONY: all run clean
