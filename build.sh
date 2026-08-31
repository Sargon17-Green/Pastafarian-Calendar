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
as --64 -o build/stage54_integration.o src/production/stage54_integration.s
as --64 -o build/stage56_bowlsum_corrective.o src/production/stage56_bowlsum_corrective.s
as --64 -o build/stage56_historical_sauce_bridge.o tests/stage56_historical_sauce_bridge.s
as --64 -o build/stage54_previous_main_bridge.o tests/stage54_previous_main_bridge.s
as --64 -o build/stage54_final_integration.o tests/stage54_final_integration.s
ld --wrap=calendarDateSpaghetti -o build/stage01_tests build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/tests.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage01_smoke build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/smoke.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage02_discovery01 build/arena.o build/bigint.o build/bootstrap.o build/stage02_discovery01.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage03_patch01 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage03_patch01.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage04_discovery02 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage04_discovery02.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage05_patch02 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage05_patch02.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage06_discovery03 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage06_discovery03.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage07_patch03 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage07_patch03.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage08_discovery04 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage08_discovery04.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage09_patch04 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage09_patch04.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage10_discovery05 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage10_discovery05.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage11_patch05 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage11_patch05.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage12_discovery06 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage12_discovery06.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage13_patch06 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage13_patch06.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage14_discovery07 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage14_discovery07.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage15_patch07 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage15_patch07.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage16_discovery08 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage16_discovery08.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage17_patch08 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage17_patch08.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage18_discovery09 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage18_discovery09.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage19_patch09 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage19_patch09.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage20_discovery10 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage20_discovery10.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage21_patch10 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage21_patch10.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage22_discovery11 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage22_discovery11.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage23_patch11 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage23_patch11.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage24_discovery12 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage24_discovery12.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage25_patch12 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage25_patch12.o build/stage54_previous_main_bridge.o
ld --wrap=calendarDateSpaghetti -o build/stage26_discovery13 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage26_discovery13.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage27_patch13 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage27_patch13.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage28_discovery14 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage28_discovery14.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage29_patch14 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage29_patch14.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage30_discovery15 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage30_discovery15.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage31_patch15 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage31_patch15.o build/stage54_previous_main_bridge.o

ld --wrap=calendarDateSpaghetti -o build/stage32_discovery16 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage32_discovery16.o build/stage54_previous_main_bridge.o

as --64 -o build/stage33_patch16.o tests/stage33_patch16.s
ld --wrap=calendarDateSpaghetti -o build/stage33_patch16 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage33_patch16.o build/stage54_previous_main_bridge.o

as --64 -o build/stage34_discovery17.o tests/stage34_discovery17.s
ld --wrap=calendarDateSpaghetti -o build/stage34_discovery17 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage34_discovery17.o build/stage54_previous_main_bridge.o

as --64 -o build/stage35_patch17.o tests/stage35_patch17.s
ld --wrap=calendarDateSpaghetti -o build/stage35_patch17 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage35_patch17.o build/stage54_previous_main_bridge.o

as --64 -o build/stage36_discovery18.o tests/stage36_discovery18.s
ld --wrap=calendarDateSpaghetti -o build/stage36_discovery18 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage36_discovery18.o build/stage54_previous_main_bridge.o

as --64 -o build/stage37_patch18.o tests/stage37_patch18.s
ld --wrap=calendarDateSpaghetti -o build/stage37_patch18 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage37_patch18.o build/stage54_previous_main_bridge.o

as --64 -o build/stage38_discovery19.o tests/stage38_discovery19.s
ld --wrap=calendarDateSpaghetti -o build/stage38_discovery19 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage38_discovery19.o build/stage54_previous_main_bridge.o

as --64 -o build/stage39_patch19.o tests/stage39_patch19.s
ld --wrap=calendarDateSpaghetti -o build/stage39_patch19 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage39_patch19.o build/stage54_previous_main_bridge.o

as --64 -o build/stage40_discovery20.o tests/stage40_discovery20.s
as --64 -o build/stage41_stage40_abi_bridge.o tests/stage41_stage40_abi_bridge.s
ld --wrap=calendarDateSpaghetti --wrap=bi_cmp -o build/stage40_discovery20 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage40_discovery20.o build/stage41_stage40_abi_bridge.o build/stage54_previous_main_bridge.o

as --64 -o build/stage41_patch20.o tests/stage41_patch20.s
ld --wrap=calendarDateSpaghetti -o build/stage41_patch20 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage41_patch20.o build/stage54_previous_main_bridge.o

as --64 -o build/stage42_discovery21.o tests/stage42_discovery21.s
ld --wrap=calendarDateSpaghetti -o build/stage42_discovery21 build/arena.o build/bigint.o build/bootstrap.o build/catalog.o build/oracle.o build/oracle_calendar.o build/oracle_structure.o build/stage42_discovery21.o build/stage54_previous_main_bridge.o

as --64 -o build/stage43_patch21.o tests/stage43_patch21.s
ld --wrap=calendarDateSpaghetti -o build/stage43_patch21 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage43_patch21.o build/stage54_previous_main_bridge.o
as --64 -o build/stage44_discovery22.o tests/stage44_discovery22.s
ld --wrap=calendarDateSpaghetti -o build/stage44_discovery22 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage44_discovery22.o build/stage54_previous_main_bridge.o
as --64 -o build/stage45_patch22.o tests/stage45_patch22.s
ld --wrap=calendarDateSpaghetti -o build/stage45_patch22 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage45_patch22.o build/stage54_previous_main_bridge.o
as --64 -o build/stage46_discovery23.o tests/stage46_discovery23.s
ld --wrap=calendarDateSpaghetti -o build/stage46_discovery23 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage46_discovery23.o build/stage54_previous_main_bridge.o
as --64 -o build/stage47_patch23.o tests/stage47_patch23.s
ld --wrap=calendarDateSpaghetti -o build/stage47_patch23 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage47_patch23.o build/stage54_previous_main_bridge.o
as --64 -o build/stage48_discovery24.o tests/stage48_discovery24.s
ld --wrap=calendarDateSpaghetti -o build/stage48_discovery24 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage48_discovery24.o build/stage54_previous_main_bridge.o
as --64 -o build/stage49_patch24.o tests/stage49_patch24.s
ld --wrap=calendarDateSpaghetti -o build/stage49_patch24 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage49_patch24.o build/stage54_previous_main_bridge.o
as --64 -o build/patch22_month_names_regression.o tests/patch22_month_names_regression.s
ld --wrap=calendarDateSpaghetti -o build/patch22_month_names_regression build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/patch22_month_names_regression.o build/stage54_previous_main_bridge.o
as --64 -o build/stage50_discovery25.o tests/stage50_discovery25.s
ld --wrap=calendarDateSpaghetti -o build/stage50_discovery25 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage50_discovery25.o build/stage54_previous_main_bridge.o
as --64 -o build/stage51_patch25.o tests/stage51_patch25.s
ld --wrap=calendarDateSpaghetti -o build/stage51_patch25 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage51_patch25.o build/stage54_previous_main_bridge.o
as --64 -o build/stage52_discovery26.o tests/stage52_discovery26.s
ld --wrap=calendarDateSpaghetti -o build/stage52_discovery26 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage52_discovery26.o build/stage54_previous_main_bridge.o
as --64 -o build/stage53_patch26.o tests/stage53_patch26.s
ld --wrap=calendarDateSpaghetti -o build/stage53_patch26 build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage53_patch26.o build/stage54_previous_main_bridge.o
ld --wrap=stage56SauceRawBowlSumCorrective -o build/stage54_final_integration build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage54_final_integration.o

# Ⲃⲁⲑⲙⲟⲥ 55 — ⲛⲇⲟⲕⲓⲙⲏ ⲙⲡaudit.
for n in $(seq 1 14); do
  as --64 --defsym AUDIT_CASE=$n -o build/stage55_end_to_end_$n.o tests/stage55_end_to_end_audit.s
  ld --wrap=stage56SauceRawBowlSumCorrective -o build/stage55_end_to_end_$n build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_end_to_end_$n.o
done
for n in 1 2 3; do
  as --64 --defsym FAR_CASE=$n -o build/stage55_far_end_to_end_$n.o tests/stage55_far_end_to_end_audit.s
  ld --wrap=stage56SauceRawBowlSumCorrective -o build/stage55_far_end_to_end_$n build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_far_end_to_end_$n.o
done
as --64 -o build/stage55_observability_audit.o tests/stage55_observability_audit.s
ld --wrap=stage56SauceRawBowlSumCorrective --wrap=monster_context_new -o build/stage55_observability_audit build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_observability_audit.o
as --64 -o build/stage55_error_cleanup_audit.o tests/stage55_error_cleanup_audit.s
ld --wrap=stage56SauceRawBowlSumCorrective --wrap=catalog_get_cutlet -o build/stage55_error_cleanup_audit build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_error_cleanup_audit.o
as --64 -o build/stage55_history_audit.o tests/stage55_history_audit.s
ld --wrap=stage56SauceRawBowlSumCorrective -o build/stage55_history_audit build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_history_audit.o
for n in 0 1 2 3; do
  as --64 --defsym FAIL_N=$n -o build/stage55_recovery_$n.o tests/stage55_recovery_audit.s
  ld --wrap=stage56SauceRawBowlSumCorrective --wrap=catalog_get_cutlet --wrap=monster_cutlet_partition_route -o build/stage55_recovery_$n build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_recovery_$n.o
done

# Ⲃⲁⲑⲙⲟⲥ 55 — ⲛshort/wide/SAVE ⲛⲇⲟⲕⲓⲙⲏ.
as --64 -o build/stage55_save_edges_audit.o tests/stage55_save_edges_audit.s
ld -o build/stage55_save_edges_audit build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage55_save_edges_audit.o
as --64 -o build/stage55_wide_edges_audit.o tests/stage55_wide_edges_audit.s
ld --wrap=calendarDateSpaghetti -o build/stage55_wide_edges_audit build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage55_wide_edges_audit.o build/stage54_previous_main_bridge.o
as --64 -o build/stage55_short_edges_audit.o tests/stage55_short_edges_audit.s
ld -o build/stage55_short_edges_audit build/arena.o build/bigint.o build/bootstrap.o build/oracle.o build/stage55_short_edges_audit.o

# Ⲃⲁⲑⲙⲟⲥ 55 — ⲡlocale/catalog ⲛⲇⲟⲕⲓⲙⲏ.
as --64 -o build/stage55_locale_catalog_audit.o tests/stage55_locale_catalog_audit.s
ld --wrap=stage56SauceRawBowlSumCorrective --wrap=catalog_get_cutlet --wrap=catalog_get_month -o build/stage55_locale_catalog_audit build/arena.o build/bigint.o build/bootstrap.o build/stage54_integration.o build/stage56_bowlsum_corrective.o build/stage56_historical_sauce_bridge.o build/catalog.o build/stage55_locale_catalog_audit.o
