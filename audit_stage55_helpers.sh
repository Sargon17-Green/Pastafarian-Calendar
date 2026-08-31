#!/usr/bin/env bash
set -euo pipefail
./build/stage01_tests
./build/stage09_patch04
./build/stage11_patch05
./build/stage15_patch07
./build/stage17_patch08
./build/stage21_patch10
./build/stage23_patch11
./build/stage27_patch13
./build/stage29_patch14
./build/stage31_patch15
./build/stage33_patch16
./build/stage35_patch17
./build/stage37_patch18
./build/stage39_patch19
./build/stage43_patch21
./build/stage45_patch22
./build/stage47_patch23
./build/stage49_patch24
./build/patch22_month_names_regression
./build/stage51_patch25
./build/stage53_patch26

./build/stage55_save_edges_audit
./build/stage55_wide_edges_audit
./build/stage55_short_edges_audit
