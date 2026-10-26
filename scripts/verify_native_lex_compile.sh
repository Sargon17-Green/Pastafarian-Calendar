#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
command -v iverilog >/dev/null
# Fail before generating the 572-MB native H archive if the decoders
# contain Icarus syntax errors or reserved identifiers.
iverilog -g2012 -Wall -s tb_weave_native_lex_prefix \
  -o build/native_lex_prefix.vvp tests/tb_weave_native_lex_prefix.sv \
  2>&1 | tee build/native_lex_prefix_compile.log
iverilog -g2012 -Wall -s tb_weave_native_lex_fast \
  -o build/native_lex_fast.vvp tests/tb_weave_native_lex_fast.sv \
  2>&1 | tee build/native_lex_fast_compile.log
test -s build/native_lex_prefix.vvp
test -s build/native_lex_fast.vvp
echo STAGE1_NATIVE_LEX_TWO_DECODERS_IVERILOG_COMPILE_PASS
