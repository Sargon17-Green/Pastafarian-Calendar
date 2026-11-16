#!/bin/sh
set -eu
# Independent Python integer oracle gates Native Free Pascal execution.
python3 verify_bigint_from_uint64.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_from_uint64_regression.pas
../build/bigint_from_uint64_regression
