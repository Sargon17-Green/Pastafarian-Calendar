#!/bin/sh
set -eu
# Independent Python oracle runs before native Pascal assertions.
python3 verify_bigint_decimal_long.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_decimal_long_regression.pas
../build/bigint_decimal_long_regression
