#!/bin/sh
set -eu
python3 verify_bigint_min_max.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_min_max_regression.pas
../build/bigint_min_max_regression
