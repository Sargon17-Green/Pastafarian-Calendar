RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PYTHON ?= python3

.PHONY: all build test clean
all: build
build: build/calendar.gb

build/calendar.o: src/boot.asm src/runtime/save127.asm src/runtime/savewide256.asm src/runtime/mul128.asm src/runtime/mbc5.asm src/runtime/banked_add.asm src/runtime/banked_sub.asm src/runtime/banked_cmp.asm src/runtime/signed_cmp.asm src/runtime/signed_add.asm src/runtime/dispatcher.asm src/tests/selftest.asm src/tests/wide_test.asm src/tests/mul_test.asm src/tests/ram_test.asm src/tests/banked_add_test.asm src/tests/banked_sub_test.asm src/tests/banked_cmp_test.asm src/tests/signed_cmp_test.asm src/tests/signed_add_test.asm
	mkdir -p build
	$(RGBASM) -Wall -o $@ src/boot.asm

build/calendar.gb: build/calendar.o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

test: build/calendar.gb
	$(PYTHON) tests/test_rom.py build/calendar.gb

clean:
	rm -rf build
