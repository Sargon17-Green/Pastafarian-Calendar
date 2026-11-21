#!/bin/sh
set -eu
python3 verify_bigint_regular_mod_subdivisor.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_regular_mod_subdivisor.pas
../build/bigint_regular_mod_subdivisor
