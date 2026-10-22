#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Static gates must run even when no HDL simulator is installed.
bash scripts/check_sv_declarations.sh rtl/*.sv tests/*.sv
bash scripts/check_catalog_structure.sh
if grep -R -n -Ei 'oracle_|pcal_stage1_oracle_pkg' rtl; then
  echo "PRODUCTION_ORACLE_ISOLATION_FAILED" >&2
  exit 1
fi
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
iverilog -g2012 -s tb_stage1_arithmetic_properties -Wall -o build/arithmetic.vvp \
  tests/pcal_stage1_oracle_pkg.sv tests/tb_stage1_arithmetic_properties.sv
vvp build/arithmetic.vvp
iverilog -g2012 -s tb_stage1_reset -Wall -o build/reset.vvp \
  rtl/pcal_stage1_bootstrap.sv tests/tb_stage1_reset.sv
vvp build/reset.vvp
iverilog -g2012 -s tb_sauce_foundation -Wall -o build/sauce.vvp \
  tests/pcal_stage1_oracle_pkg.sv tests/tb_sauce_foundation.sv
vvp build/sauce.vvp
iverilog -g2012 -s tb_gate_gap_oracle -Wall -o build/gate.vvp \
  tests/pcal_stage1_oracle_pkg.sv tests/tb_gate_gap_oracle.sv
vvp build/gate.vvp
iverilog -g2012 -s tb_selection_rejection_equivalence -Wall -o build/selection.vvp \
  tests/tb_selection_rejection_equivalence.sv
vvp build/selection.vvp
echo "STAGE1_SIMULATION_BOOTSTRAP_RESET_FOUNDATION_AND_CATALOG_STRUCTURE_PASS_ONLY"
echo "STAGE1_FULL_ORACLE_AND_CATALOG_QA_STILL_PENDING"
