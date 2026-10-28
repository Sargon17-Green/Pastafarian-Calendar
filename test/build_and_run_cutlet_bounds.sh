#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build cutlet_partition_memo_bounds_regression.pas
../build/cutlet_partition_memo_bounds_regression
