#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
# Twelve months need at most 4496 bits by the trivial 12^L bound;
# run the probe with a much smaller compiled width.
iverilog -g2012 -Wall -s tb_weave_full_root \
  -Ptb_weave_full_root.WIDTH=6144 \
  -o build/weave_probe.vvp tests/tb_weave_full_root.sv
timeout 300s vvp build/weave_probe.vvp +stop_after=12 \
  2>&1 | tee build/weave_fullroot_probe.log
# Separate 22528-bit elaboration only for the full-root run.
iverilog -g2012 -Wall -s tb_weave_full_root \
  -Ptb_weave_full_root.WIDTH=22528 \
  -o build/weave_fullroot.vvp tests/tb_weave_full_root.sv
timeout 2100s vvp build/weave_fullroot.vvp +stop_after=45 \
  2>&1 | tee build/weave_fullroot_run.log
test "$(wc -c < build/foundation_weave_root.bin)" -eq 2809
printf '%s  %s\n' \
  925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da \
  build/foundation_weave_root.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_FULL_WEAVE_ROOT_SHA256_PASS"
# Root count is now verified independently by SHA-256.
# Wide answer and rank use only unsigned exact arithmetic.
iverilog -g2012 -Wall -s tb_weave_full_rank \
  -o build/weave_fullrank.vvp tests/tb_weave_full_rank.sv
timeout 300s vvp build/weave_fullrank.vvp \
  2>&1 | tee build/weave_fullrank_run.log
test "$(wc -c < build/foundation_weave_rank.bin)" -eq 2809
printf '%s  %s\n' \
  2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06 \
  build/foundation_weave_rank.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_FULL_WEAVE_RANK_SHA256_PASS"
