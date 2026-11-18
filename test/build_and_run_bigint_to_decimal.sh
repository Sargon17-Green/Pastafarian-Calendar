#!/bin/sh
set -eu
# Python-int independently constructs the canonical expected decimal strings.
python3 verify_bigint_to_decimal.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_to_decimal_regression.pas
../build/bigint_to_decimal_regression
