#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v iverilog >/dev/null 2>&1; then
  echo "IVERILOG_MISSING: run on a host with Icarus Verilog (IEEE 1800 subset)." >&2
  exit 127
fi
if ! command -v vvp >/dev/null 2>&1; then
  echo "VVP_MISSING" >&2
  exit 127
fi
mkdir -p build
iverilog -g2012 -s tb_stage1 -Wall -o build/stage1.vvp \
  tests/pcal_stage1_oracle_pkg.sv \
  rtl/pcal_stage1_bootstrap.sv tests/tb_stage1.sv
vvp build/stage1.vvp
iverilog -g2012 -s tb_sauce_foundation -Wall -o build/sauce.vvp \
  tests/pcal_stage1_oracle_pkg.sv tests/tb_sauce_foundation.sv
vvp build/sauce.vvp
if grep -R -n -Ei 'oracle_|pcal_stage1_oracle_pkg' rtl; then
  echo "PRODUCTION_ORACLE_ISOLATION_FAILED" >&2
  exit 1
fi
echo "STAGE1_SIMULATION_PRIMITIVES_AND_FOUNDATION_PASS_ONLY"
echo "STAGE1_FULL_ORACLE_AND_CATALOG_QA_STILL_PENDING"
