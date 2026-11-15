#!/bin/sh
set -eu
# Python arbitrary-precision oracle and coverage gates before Native execution.
python3 verify_bigint_negate_abs.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_negate_abs_regression.pas
../build/bigint_negate_abs_regression
