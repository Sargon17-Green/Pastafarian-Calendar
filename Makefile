RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
PYTHON ?= python3

.PHONY: all build test clean
all: build
build: build/calendar.gb

build/calendar.o: src/boot.asm src/runtime/save127.asm src/runtime/savewide256.asm src/runtime/mul128.asm src/runtime/mbc5.asm src/runtime/sram_lease.asm src/runtime/sram_owner.asm src/runtime/owner_byte.asm src/runtime/owner_signed_cmp.asm src/runtime/magnitude_length.asm src/runtime/divide_u8.asm src/runtime/signed_divide_u8.asm src/runtime/variable_add.asm src/runtime/day_count32.asm src/runtime/work_counts32.asm src/runtime/banked_add.asm src/runtime/banked_sub.asm src/runtime/banked_cmp.asm src/runtime/signed_cmp.asm src/runtime/signed_add.asm src/runtime/dispatcher.asm src/runtime/ordinal_validate.asm src/runtime/ordinal_unit.asm src/runtime/calendar_save127.asm src/runtime/calendar_year_projection.asm src/runtime/calendar_year_step.asm src/runtime/calendar_select_short.asm src/runtime/calendar_stone_transition.asm src/runtime/calendar_hidden1.asm src/runtime/calendar_hidden2.asm src/runtime/calendar_hidden3.asm src/runtime/calendar_hidden4.asm src/runtime/calendar_hidden5.asm src/runtime/calendar_hidden6.asm src/runtime/calendar_hidden7.asm src/tests/selftest.asm src/tests/wide_test.asm src/tests/mul_test.asm src/tests/ram_test.asm src/tests/banked_add_test.asm src/tests/banked_sub_test.asm src/tests/banked_cmp_test.asm src/tests/signed_cmp_test.asm src/tests/signed_add_test.asm src/tests/sram_lease_test.asm src/tests/sram_owner_test.asm src/tests/owner_byte_test.asm src/tests/owner_signed_cmp_test.asm src/tests/calendar_invocation_lifecycle_test.asm src/tests/calendar_year_projection_test.asm src/tests/calendar_year_step_test.asm src/tests/calendar_answer_select_test.asm src/tests/calendar_stone_transition_test.asm src/tests/calendar_stone_range_test.asm src/tests/day_count32_test.asm src/tests/work_counts32_test.asm src/tests/magnitude_length_test.asm src/tests/divide_u8_test.asm src/tests/signed_divide_u8_test.asm src/tests/variable_add_test.asm
	mkdir -p build
	$(RGBASM) -Wall -o $@ src/boot.asm

build/calendar.gb: build/calendar.o
	$(RGBLINK) -n build/calendar.sym -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

test: build/calendar.gb
	$(PYTHON) tests/test_rom.py build/calendar.gb

clean:
	rm -rf build

# Explicit alternate ROM: all prior Native 1..370 and its 9000-frame gate
# remain unchanged. Depend on the base object for complete source freshness.
build/calendar_i46.o: build/calendar.o src/tests/calendar_stone_i46_native_test.asm
	$(RGBASM) -Wall -D STAGE1_I46_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_i46.gb: build/calendar_i46.o
	$(RGBLINK) -n build/calendar_i46.sym -m build/calendar_i46.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Separate first-hidden-drop cartridge, not part of Native370 or i46 Native371.
build/calendar_hidden1.o: build/calendar.o src/tests/calendar_hidden1_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN1_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden1.gb: build/calendar_hidden1.o
	$(RGBLINK) -n build/calendar_hidden1.sym -m build/calendar_hidden1.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Separate second hidden drop cartridge, not part of 370, 371 or 372.
build/calendar_hidden2.o: build/calendar.o src/tests/calendar_hidden2_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN2_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden2.gb: build/calendar_hidden2.o
	$(RGBLINK) -n build/calendar_hidden2.sym -m build/calendar_hidden2.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Separate third hidden drop cartridge, not part of 370, 371 or 372.
build/calendar_hidden3.o: build/calendar.o src/tests/calendar_hidden3_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN3_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden3.gb: build/calendar_hidden3.o
	$(RGBLINK) -n build/calendar_hidden3.sym -m build/calendar_hidden3.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated k4 Native375, independent of existing 370–374 targets.
build/calendar_hidden4.o: build/calendar.o src/tests/calendar_hidden4_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN4_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden4.gb: build/calendar_hidden4.o
	$(RGBLINK) -n build/calendar_hidden4.sym -m build/calendar_hidden4.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated k5 Native376; retain original 370–375 targets.
build/calendar_hidden5.o: build/calendar.o src/tests/calendar_hidden5_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN5_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden5.gb: build/calendar_hidden5.o
	$(RGBLINK) -n build/calendar_hidden5.sym -m build/calendar_hidden5.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated k6 Native377; retain original 370–376 targets.
build/calendar_hidden6.o: build/calendar.o src/tests/calendar_hidden6_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN6_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden6.gb: build/calendar_hidden6.o
	$(RGBLINK) -n build/calendar_hidden6.sym -m build/calendar_hidden6.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated k7 Native378: preserve default Native370 and prior cases.
build/calendar_hidden7.o: build/calendar.o src/tests/calendar_hidden7_native_test.asm
	$(RGBASM) -Wall -D STAGE1_HIDDEN7_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_hidden7.gb: build/calendar_hidden7.o
	$(RGBLINK) -n build/calendar_hidden7.sym -m build/calendar_hidden7.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated Stage1 visible1 Native379: preserve accepted Native370-378 targets.
build/calendar_visible1.o: build/calendar.o src/tests/calendar_visible1_native_test.asm src/runtime/calendar_visible1.asm
	$(RGBASM) -Wall -D STAGE1_VISIBLE1_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_visible1.gb: build/calendar_visible1.o
	$(RGBLINK) -n build/calendar_visible1.sym -m build/calendar_visible1.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated Stage1 chain Native380; do not append to existing Native370..379.
build/calendar_chain1.o: build/calendar.o src/runtime/calendar_hidden_visible1_chain.asm src/tests/calendar_hidden_visible1_chain_native_test.asm
	$(RGBASM) -Wall -D STAGE1_CHAIN1_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_chain1.gb: build/calendar_chain1.o
	$(RGBLINK) -n build/calendar_chain1.sym -m build/calendar_chain1.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@

# Isolated second-visible Native381, independent of accepted 370..380 routes.
build/calendar_chain2.o: build/calendar.o src/runtime/calendar_hidden_visible2_chain.asm src/tests/calendar_hidden_visible2_chain_native_test.asm
	$(RGBASM) -Wall -D STAGE1_CHAIN2_NATIVE_BENCH=1 -o $@ src/boot.asm

build/calendar_chain2.gb: build/calendar_chain2.o
	$(RGBLINK) -n build/calendar_chain2.sym -m build/calendar_chain2.map -o $@ $<
	$(RGBFIX) -v -p 0 -m 0x1a -r 0x04 -t PASTA-GEEZ $@
