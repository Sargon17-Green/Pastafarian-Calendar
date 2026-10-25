#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
command -v iverilog >/dev/null
command -v vvp >/dev/null
iverilog -g2012 -Wall -s tb_native_lex_factor_exhaustive \
  -o build/native_lex_factor_unit.vvp tests/tb_native_lex_factor_exhaustive.sv
timeout 90s vvp build/native_lex_factor_unit.vvp \
  2>&1 | tee build/native_lex_factor_unit.log
grep -Fq 'STAGE1_LEX_FAST_TOY_PERMUTATIONS_PASS cases=64' build/native_lex_factor_unit.log
grep -Fq 'STAGE1_LEX_FAST_45_LABEL_FACTOR_QA_PASS synthetic=160' build/native_lex_factor_unit.log
if timeout 90s vvp build/native_lex_factor_unit.vvp +mutate_fast \
  > build/native_lex_factor_unit_mutant.log 2>&1; then
  echo 'FACTOR_UNIT_UNEXPECTED_MUTANT_PASS' >&2
  exit 1
fi
grep -Fq 'FACTOR_UNIT_PARENT_MUTATION_REJECTED' build/native_lex_factor_unit_mutant.log
echo 'STAGE1_LEX_FAST_MUTANT_REJECTED_PASS'
