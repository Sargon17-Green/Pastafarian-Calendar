#!/bin/sh
set -eu
python3 verify_bigint_conversion_exact.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_conversion_exact_regression.pas
../build/bigint_conversion_exact_regression
