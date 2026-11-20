#!/bin/sh
set -eu
# Produce 96 Python-int reference rows at runtime before native execution.
python3 verify_bigint_floor_div_positive_quotient512.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_floor_div_positive_quotient512.pas
../build/bigint_floor_div_positive_quotient512
