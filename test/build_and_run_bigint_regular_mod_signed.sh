#!/bin/sh
set -eu
python3 verify_bigint_regular_mod_signed.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_regular_mod_signed_regression.pas
../build/bigint_regular_mod_signed_regression
