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
# After hashes for the root and canonical 177-digit rank have passed,
# independently count completions after woven prefix 1,1.
# This count needs the same full precision, so it has a separate
# bounded execution log. CI whole-job budget remains 43 minutes.
timeout 1100s vvp build/weave_fullroot.vvp +stop_after=45 +prefix11 \
  2>&1 | tee build/weave_prefix11_run.log
test "$(wc -c < build/foundation_weave_prefix11.bin)" -eq 2809
printf '%s  %s\n' \
  642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac \
  build/foundation_weave_prefix11.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_WEAVE_PREFIX11_SHA256_PASS"

iverilog -g2012 -Wall -s tb_weave_prefix2 \
  -o build/weave_prefix2.vvp tests/tb_weave_prefix2.sv
timeout 60s vvp build/weave_prefix2.vvp \
  2>&1 | tee build/weave_prefix2_run.log
# One further full-width suffix run covers [1,2,1].
# The [1,2,2] block then follows via an exact rational relation,
# rather than running the expensive 4241-day suffix kernel twice.
timeout 1100s vvp build/weave_fullroot.vvp +stop_after=45 +prefix121 \
  2>&1 | tee build/weave_prefix121_run.log
test "$(wc -c < build/foundation_weave_prefix121.bin)" -eq 2809
printf '%s  %s\n' \
  0a29d31d02e980a1ae807575c85a908bd31a05eb73b521a80f7ee3f2e925f1a7 \
  build/foundation_weave_prefix121.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_WEAVE_PREFIX121_SHA256_PASS"
iverilog -g2012 -Wall -s tb_weave_prefix3 \
  -o build/weave_prefix3.vvp tests/tb_weave_prefix3.sv
timeout 60s vvp build/weave_prefix3.vvp \
  2>&1 | tee build/weave_prefix3_run.log
test "$(wc -c < build/foundation_weave_prefix122.bin)" -eq 2809
test "$(wc -c < build/foundation_weave_prefix123.bin)" -eq 2809
printf '%s  %s\n' \
  50064b46e82a20681a0e100e8a1516e0b4c151398231dd2f898be22f07bb9866 \
  build/foundation_weave_prefix122.bin | sha256sum -c -
printf '%s  %s\n' \
  a89a9799db0649b78a5b24bf150f57dc11e549ce2d0d42088929974237762dde \
  build/foundation_weave_prefix123.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_WEAVE_PREFIX3_SHA256_PASS"
# One bounded full-width transfer obtains the [1,2,3,1] block;
# [1,2,3,2] and [1,2,3,3] follow by proven exact active-factor
# ratios, and [1,2,3,4] by lexical partition conservation.
timeout 1100s vvp build/weave_fullroot.vvp +stop_after=45 +prefix1231 \
  2>&1 | tee build/weave_prefix1231_run.log
test "$(wc -c < build/foundation_weave_prefix1231.bin)" -eq 2809
printf '%s  %s\n' \
  b66cf4cc1afb8b2b604e574ff0ba1d788b0eb83bb7dbfc67a103a08ef220d340 \
  build/foundation_weave_prefix1231.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_WEAVE_PREFIX1231_SHA256_PASS"

iverilog -g2012 -Wall -s tb_weave_prefix4 \
  -o build/weave_prefix4.vvp tests/tb_weave_prefix4.sv
timeout 60s vvp build/weave_prefix4.vvp \
  2>&1 | tee build/weave_prefix4_run.log
test "$(wc -c < build/foundation_weave_prefix1232.bin)" -eq 2809
test "$(wc -c < build/foundation_weave_prefix1233.bin)" -eq 2809
test "$(wc -c < build/foundation_weave_prefix1234.bin)" -eq 2809
printf '%s  %s\n' \
  47a2f7fa694e5bd1d85307df85ad5067c7f7aee18c441ec7c47b38a6a66c5531 \
  build/foundation_weave_prefix1232.bin | sha256sum -c -
printf '%s  %s\n' \
  8f680a1e1ee8f272f8ec2b243f2b9a5d4c63c7aa73e6866ba4dc610353440b1a \
  build/foundation_weave_prefix1233.bin | sha256sum -c -
printf '%s  %s\n' \
  cbc01e54edc50fc880531214fc5fe5aa6c72252483a4b70a58458711570f37f5 \
  build/foundation_weave_prefix1234.bin | sha256sum -c -
echo "STAGE1_FOUNDATION_WEAVE_PREFIX4_SHA256_PASS"
