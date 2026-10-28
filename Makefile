RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PYTHON ?= python3

.PHONY: all build test clean
all: build
build: build/calendar.gb

build/calendar.o: src/boot.asm src/runtime/save127.asm src/runtime/savewide256.asm src/runtime/mul128.asm src/runtime/mbc5.asm src/runtime/sram_lease.asm src/runtime/magnitude_length.asm src/runtime/divide_u8.asm src/runtime/signed_divide_u8.asm src/runtime/variable_add.asm src/runtime/day_count32.asm src/runtime/work_counts32.asm src/runtime/banked_add.asm src/runtime/banked_sub.asm src/runtime/banked_cmp.asm src/runtime/signed_cmp.asm src/runtime/signed_add.asm src/runtime/dispatcher.asm src/tests/selftest.asm src/tests/wide_test.asm src/tests/mul_test.asm src/tests/ram_test.asm src/tests/banked_add_test.asm src/tests/banked_sub_test.asm src/tests/banked_cmp_test.asm src/tests/signed_cmp_test.asm src/tests/signed_add_test.asm src/tests/sram_lease_test.asm src/tests/day_count32_test.asm src/tests/work_counts32_test.asm src/tests/magnitude_length_test.asm src/tests/divide_u8_test.asm src/tests/signed_divide_u8_test.asm src/tests/variable_add_test.asm
	mkdir -p build
	$(RGBASM) -Wall -o $@ src/boot.asm

build/calendar.gb: build/calendar.o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

test: build/calendar.gb
	$(PYTHON) tests/test_rom.py build/calendar.gb

clean:
	rm -rf build
