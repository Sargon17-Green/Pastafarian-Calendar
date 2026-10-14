RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PYTHON ?= python3

.PHONY: all build test clean
all: build
build: build/calendar.gb

build/calendar.o: src/boot.asm src/runtime/save127.asm src/runtime/dispatcher.asm src/tests/selftest.asm
	mkdir -p build
	$(RGBASM) -Wall -o $@ src/boot.asm

build/calendar.gb: build/calendar.o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0 -t PASTA-GEEZ $@

test: build/calendar.gb
	$(PYTHON) tests/test_rom.py build/calendar.gb

clean:
	rm -rf build
