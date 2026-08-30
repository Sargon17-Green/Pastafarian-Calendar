#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
as --64 -o build/arena.o src/runtime/arena.s
as --64 -o build/bigint.o src/runtime/bigint.s
as --64 -o build/bootstrap.o src/production/bootstrap.s
as --64 -o build/catalog.o src/catalog/source_language_catalog.s
as --64 -o build/oracle.o src/oracle/oracle_reference.s
as --64 -o build/oracle_calendar.o src/oracle/oracle_calendar.s
as --64 -o build/oracle_structure.o src/oracle/oracle_structure.s
as --64 -o build/tests.o tests/stage01_tests.s
as --64 -o build/smoke.o tests/stage01_smoke.s
as --64 -o build/stage02_discovery01.o tests/stage02_discovery01.s
as --64 -o build/stage03_patch01.o tests/stage03_patch01.s
as --64 -o build/stage04_discovery02.o tests/stage04_discovery02.s
as --64 -o build/stage05_patch02.o tests/stage05_patch02.s
as --64 -o build/stage06_discovery03.o tests/stage06_discovery03.s
as --64 -o build/stage07_patch03.o tests/stage07_patch03.s
as --64 -o build/stage08_discovery04.o tests/stage08_discovery04.s
as --64 -o build/stage09_patch04.o tests/stage09_patch04.s
as --64 -o build/stage10_discovery05.o tests/stage10_discovery05.s
as --64 -o build/stage11_patch05.o tests/stage11_patch05.s
as --64 -o build/stage12_discovery06.o tests/stage12_discovery06.s
as --64 -o build/stage13_patch06.o tests/stage13_patch06.s
as --64 -o build/stage14_discovery07.o tests/stage14_discovery07.s
as --64 -o build/stage15_patch07.o tests/stage15_patch07.s
as --64 -o build/stage16_discovery08.o tests/stage16_discovery08.s
as --64 -o build/stage17_patch08.o tests/stage17_patch08.s
as --64 -o build/stage18_discovery09.o tests/stage18_discovery09.s
as --64 -o build/stage19_patch09.o tests/stage19_patch09.s
as --64 -o build/stage20_discovery10.o tests/stage20_discovery10.s
ld -o build/stage01_tests build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/tests.o
ld -o build/stage01_smoke build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/smoke.o
ld -o build/stage02_discovery01 build/arena.o build/bigint.o build/bootstrap.o build/stage02_discovery01.o
ld -o build/stage03_patch01 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage03_patch01.o
ld -o build/stage04_discovery02 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage04_discovery02.o
ld -o build/stage05_patch02 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage05_patch02.o
ld -o build/stage06_discovery03 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage06_discovery03.o
ld -o build/stage07_patch03 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage07_patch03.o
ld -o build/stage08_discovery04 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage08_discovery04.o
ld -o build/stage09_patch04 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage09_patch04.o
ld -o build/stage10_discovery05 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage10_discovery05.o
ld -o build/stage11_patch05 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage11_patch05.o
ld -o build/stage12_discovery06 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage12_discovery06.o
ld -o build/stage13_patch06 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage13_patch06.o
ld -o build/stage14_discovery07 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage14_discovery07.o
ld -o build/stage15_patch07 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage15_patch07.o

ld -o build/stage16_discovery08 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage16_discovery08.o
ld -o build/stage17_patch08 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage17_patch08.o
ld -o build/stage18_discovery09 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage18_discovery09.o
ld -o build/stage19_patch09 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage19_patch09.o
ld -o build/stage20_discovery10 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage20_discovery10.o
