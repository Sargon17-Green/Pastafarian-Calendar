#!/bin/sh
set -eu
python3 verify_bigint_divmod_long.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_divmod_long_regression.pas
../build/bigint_divmod_long_regression
