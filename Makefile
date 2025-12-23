# Rachel Amstrad CPC - Makefile
PASMO ?= pasmo

.PHONY: all clean

all: build/rachel-cpc.bin
	@echo "Built: build/rachel-cpc.bin"

build/rachel-cpc.bin: src/main.asm src/*.asm src/net/m4board.asm
	$(PASMO) src/main.asm build/rachel-cpc.bin

clean:
	rm -rf build/*
