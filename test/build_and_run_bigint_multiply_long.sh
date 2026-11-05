#!/bin/sh
set -eu
python3 verify_bigint_multiply_long.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_multiply_long_regression.pas
../build/bigint_multiply_long_regression
