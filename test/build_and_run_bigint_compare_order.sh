#!/bin/sh
set -eu
python3 verify_bigint_compare_order.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_compare_order_regression.pas
../build/bigint_compare_order_regression
