#!/bin/sh
set -eu
python3 verify_bigint_add_sub_long.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_add_sub_long_regression.pas
../build/bigint_add_sub_long_regression
