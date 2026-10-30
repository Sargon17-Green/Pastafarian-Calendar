#!/bin/sh
set -eu
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_boundary_regression.pas
../build/bigint_boundary_regression
