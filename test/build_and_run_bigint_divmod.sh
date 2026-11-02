#!/bin/sh
set -eu
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_divmod_oracle_regression.pas
../build/bigint_divmod_oracle_regression
