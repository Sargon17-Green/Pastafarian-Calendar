#!/bin/sh
set -eu
# Python-int independently constructs expected quotient and remainder vectors.
python3 verify_bigint_floor_div_positive.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_floor_div_positive_regression.pas
../build/bigint_floor_div_positive_regression
