RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PYTHON ?= python3

.PHONY: all build test clean
all: build
build: build/calendar.gb

build/calendar.o: src/boot.asm src/runtime/save127.asm src/runtime/savewide256.asm src/runtime/mul128.asm src/runtime/mbc5.asm src/runtime/dispatcher.asm src/tests/selftest.asm src/tests/wide_test.asm src/tests/mul_test.asm src/tests/ram_test.asm
	mkdir -p build
	$(RGBASM) -Wall -o $@ src/boot.asm

build/calendar.gb: build/calendar.o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

test: build/calendar.gb
	$(PYTHON) tests/test_rom.py build/calendar.gb

clean:
	rm -rf build
