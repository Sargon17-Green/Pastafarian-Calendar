#!/bin/sh
set -eu
python3 verify_bigint_scalar_signed.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_scalar_signed_regression.pas
../build/bigint_scalar_signed_regression
