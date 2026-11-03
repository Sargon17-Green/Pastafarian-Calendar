#!/bin/sh
set -eu
python3 verify_bigint_signed_vectors.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_signed_arithmetic_regression.pas
../build/bigint_signed_arithmetic_regression
