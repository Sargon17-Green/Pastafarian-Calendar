#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
command -v python3 >/dev/null
command -v iverilog >/dev/null
command -v vvp >/dev/null
command -v timeout >/dev/null
command -v sha256sum >/dev/null
timeout 120s python3 scripts/test_foundation_weave_full.py \
  2>&1 | tee build/foundation_full_year_reference.log
test "$(wc -c < build/foundation_weave_all4244.bin)" -eq 4244
test "$(wc -l < build/foundation_weave_all4244.hex)" -eq 4244
printf '%s  %s\n' \
  e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29 \
  build/foundation_weave_all4244.bin | sha256sum -c -
iverilog -g2012 -Wall -s tb_weave_reference_structure \
  -o build/full_year_structural.vvp tests/tb_weave_reference_structure.sv
timeout 30s vvp build/full_year_structural.vvp \
  2>&1 | tee build/foundation_full_year_sv_structure.log
echo "STAGE1_FULL_YEAR_REFERENCE_AND_SV_STRUCTURE_PASS_ONLY"
echo "STAGE1_FULL_YEAR_NATIVE_SV_UNRANK_AND_PRODUCTION_RTL_PENDING"
