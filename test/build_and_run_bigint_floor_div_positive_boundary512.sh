#!/bin/sh
set -eu
# Generate the independent 96-case Python-int TSV at runtime.
python3 verify_bigint_floor_div_positive_boundary512.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_floor_div_positive_boundary512.pas
../build/bigint_floor_div_positive_boundary512
