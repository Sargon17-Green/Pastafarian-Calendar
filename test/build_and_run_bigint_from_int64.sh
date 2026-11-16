#!/bin/sh
set -eu
# Python arbitrary-precision oracle runs before native Free Pascal checks.
python3 verify_bigint_from_int64.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_from_int64_regression.pas
../build/bigint_from_int64_regression
