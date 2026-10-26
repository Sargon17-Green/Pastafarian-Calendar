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
# Separate exact 22528-bit native rank interval replay over 4243
# Python-produced skipped/selected block witness pairs.
# This is NOT native generation of the combinatorial block counts.
test "$(wc -c < build/foundation_weave_rank_intervals.bin)" -eq 23837174
# Independent second exact-bigint reconstruction (not the producer)
# fixed this 23.8 MiB byte stream hash; do not only trust its length.
printf '%s  %s\n' \
  2e46a3081ebbcf866ec5182b45c91f6695abbc83c1e3afec17cf678434749afb \
  build/foundation_weave_rank_intervals.bin | sha256sum -c -
echo "STAGE1_FULL_YEAR_RANK_LEDGER_INDEPENDENT_SHA256_PASS"
test "$(wc -c < build/foundation_weave_root.bin)" -eq 2809
test "$(wc -c < build/foundation_weave_rank.bin)" -eq 2809
printf '%s  %s\n' \
  925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da \
  build/foundation_weave_root.bin | sha256sum -c -
printf '%s  %s\n' \
  2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06 \
  build/foundation_weave_rank.bin | sha256sum -c -
iverilog -g2012 -Wall -s tb_weave_full_rank_replay \
  -o build/full_year_rank_replay.vvp tests/tb_weave_full_rank_replay.sv
timeout 180s vvp build/full_year_rank_replay.vvp \
  2>&1 | tee build/foundation_full_year_rank_replay.log
# A mutation in the first rank interval must be detected natively.
if timeout 15s vvp build/full_year_rank_replay.vvp +mutate_ledger \
    > build/foundation_full_year_rank_replay_negative.log 2>&1; then
  echo "STAGE1_FULL_YEAR_RANK_REPLAY_NEGATIVE_TEST_FALSE_PASS" >&2
  exit 1
fi
grep -Fq "FULL_YEAR_RANK_REPLAY_INVALID_BLOCK" \
  build/foundation_full_year_rank_replay_negative.log
echo "STAGE1_FULL_YEAR_RANK_REPLAY_TAMPER_REJECTED_PASS"
echo "STAGE1_FULL_YEAR_REFERENCE_AND_SV_STRUCTURE_AND_RANK_REPLAY_PASS_ONLY"
echo "STAGE1_FULL_YEAR_NATIVE_SV_BLOCK_COUNT_GENERATION_AND_PRODUCTION_RTL_PENDING"
