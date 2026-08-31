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
as --64 -o build/stage21_patch10.o tests/stage21_patch10.s
as --64 -o build/stage22_discovery11.o tests/stage22_discovery11.s
as --64 -o build/stage23_patch11.o tests/stage23_patch11.s
as --64 -o build/stage24_discovery12.o tests/stage24_discovery12.s
as --64 -o build/stage25_patch12.o tests/stage25_patch12.s
as --64 -o build/stage26_discovery13.o tests/stage26_discovery13.s
as --64 -o build/stage27_patch13.o tests/stage27_patch13.s
as --64 -o build/stage28_discovery14.o tests/stage28_discovery14.s
as --64 -o build/stage29_patch14.o tests/stage29_patch14.s
as --64 -o build/stage30_discovery15.o tests/stage30_discovery15.s
as --64 -o build/stage31_patch15.o tests/stage31_patch15.s
as --64 -o build/stage32_discovery16.o tests/stage32_discovery16.s
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
ld -o build/stage21_patch10 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage21_patch10.o
ld -o build/stage22_discovery11 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage22_discovery11.o
ld -o build/stage23_patch11 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage23_patch11.o
ld -o build/stage24_discovery12 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage24_discovery12.o
ld -o build/stage25_patch12 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage25_patch12.o
ld -o build/stage26_discovery13 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage26_discovery13.o

ld -o build/stage27_patch13 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage27_patch13.o

ld -o build/stage28_discovery14 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage28_discovery14.o

ld -o build/stage29_patch14 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage29_patch14.o

ld -o build/stage30_discovery15 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage30_discovery15.o

ld -o build/stage31_patch15 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage31_patch15.o

ld -o build/stage32_discovery16 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage32_discovery16.o

as --64 -o build/stage33_patch16.o tests/stage33_patch16.s
ld -o build/stage33_patch16 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage33_patch16.o

as --64 -o build/stage34_discovery17.o tests/stage34_discovery17.s
ld -o build/stage34_discovery17 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage34_discovery17.o

as --64 -o build/stage35_patch17.o tests/stage35_patch17.s
ld -o build/stage35_patch17 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage35_patch17.o

as --64 -o build/stage36_discovery18.o tests/stage36_discovery18.s
ld -o build/stage36_discovery18 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage36_discovery18.o

as --64 -o build/stage37_patch18.o tests/stage37_patch18.s
ld -o build/stage37_patch18 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage37_patch18.o

as --64 -o build/stage38_discovery19.o tests/stage38_discovery19.s
ld -o build/stage38_discovery19 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage38_discovery19.o

as --64 -o build/stage39_patch19.o tests/stage39_patch19.s
ld -o build/stage39_patch19 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage39_patch19.o

as --64 -o build/stage40_discovery20.o tests/stage40_discovery20.s
as --64 -o build/stage41_stage40_abi_bridge.o tests/stage41_stage40_abi_bridge.s
ld --wrap=bi_cmp -o build/stage40_discovery20 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage40_discovery20.o build/stage41_stage40_abi_bridge.o

as --64 -o build/stage41_patch20.o tests/stage41_patch20.s
ld -o build/stage41_patch20 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage41_patch20.o

as --64 -o build/stage42_discovery21.o tests/stage42_discovery21.s
ld -o build/stage42_discovery21 build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/stage42_discovery21.o

as --64 -o build/stage43_patch21.o tests/stage43_patch21.s
ld -o build/stage43_patch21 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage43_patch21.o
as --64 -o build/stage44_discovery22.o tests/stage44_discovery22.s
ld -o build/stage44_discovery22 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage44_discovery22.o
as --64 -o build/stage45_patch22.o tests/stage45_patch22.s
ld -o build/stage45_patch22 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage45_patch22.o
