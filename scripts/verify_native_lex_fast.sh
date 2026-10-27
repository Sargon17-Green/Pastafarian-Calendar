#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
# Requires native-SV H archive and SHA-pinned rank from preceding
# verify_native_lex_prefix.sh. It loads no Python-generated child blocks.
test "$(wc -c < build/native_H_table.hex)" -eq 572279002
test "$(wc -c < build/native_lex_rank.bin)" -eq 2809
iverilog -g2012 -Wall -s tb_weave_native_lex_fast \
    -o build/native_lex_fast.vvp tests/tb_weave_native_lex_fast.sv
timeout 240s vvp build/native_lex_fast.vvp +max_positions=64 \
    2>&1 | tee build/native_lex_fast64.log
grep -Fq 'STAGE1_NATIVE_LEX_FAST_SV_PASS positions=64' build/native_lex_fast64.log
test "$(wc -c < build/native_lex_fast_prefix.bin)" -eq 64
test "$(wc -c < build/native_lex_prefix.bin)" -eq 16
cmp -n 16 build/native_lex_fast_prefix.bin build/native_lex_prefix.bin
printf '%s\n' 'c799e928b30deb45924e8aa9f11be013b5a5f205190788e01dc99508793447dc  build/native_lex_fast_prefix.bin' | sha256sum -c
echo 'STAGE1_NATIVE_LEX_FAST_64_SHA256_AND_DIRECT16_OVERLAP_PASS'
# Preserve the independently checked 64-byte run for cross-run prefix equivalence.
cp build/native_lex_fast_prefix.bin build/native_lex_fast64_prefix.bin

timeout 480s vvp build/native_lex_fast.vvp +max_positions=256 \
    2>&1 | tee build/native_lex_fast256.log
grep -Fq 'STAGE1_NATIVE_LEX_FAST_SV_PASS positions=256' build/native_lex_fast256.log
grep -Fq 'NATIVE_LEX_PREFIX_PROGRESS position=255 ordinal=45 started=45' build/native_lex_fast256.log
test "$(wc -c < build/native_lex_fast_prefix.bin)" -eq 256
printf '%s\n' 'f85aafeaa582a87bbc66c43a752a40fe3a2a88ad7d47b8e43500a2306f69c45b  build/native_lex_fast_prefix.bin' | sha256sum -c
# The independently SHA-pinned 256-byte run must extend, not contradict,
# both the 64-byte fast run and the 16-byte direct native-SV decoder.
test "$(wc -c < build/native_lex_fast64_prefix.bin)" -eq 64
cmp -n 64 build/native_lex_fast64_prefix.bin build/native_lex_fast_prefix.bin
cmp -n 16 build/native_lex_prefix.bin build/native_lex_fast_prefix.bin
echo 'STAGE1_NATIVE_LEX_FAST_256_EXTENDS_64_AND_DIRECT16_PASS'
echo 'STAGE1_NATIVE_LEX_FAST_256_ALL45_STARTED_SHA256_PASS'

if timeout 180s vvp build/native_lex_fast.vvp +max_positions=64 +mutate_old_H \
    > build/native_lex_fast_negative.log 2>&1; then
  echo 'NATIVE_LEX_FAST_H_MUTANT_FALSE_PASS' >&2
  exit 1
fi
grep -Fq 'NATIVE_LEX_FRESH_PARTITION_MISMATCH' build/native_lex_fast_negative.log
echo 'STAGE1_NATIVE_LEX_FAST_MUTANT_REJECTED_PASS'
