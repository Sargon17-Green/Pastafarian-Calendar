#!/bin/sh
set -eu
python3 verify_bigint_regular_mod_zero_unit.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_regular_mod_zero_unit.pas
../build/bigint_regular_mod_zero_unit
