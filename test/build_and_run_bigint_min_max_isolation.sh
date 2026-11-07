#!/bin/sh
set -eu
# Independent Python-int oracle and fixture-coverage gates (96/96).
python3 verify_bigint_min_max.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_min_max_isolation_regression.pas
../build/bigint_min_max_isolation_regression
