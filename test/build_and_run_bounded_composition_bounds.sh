#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bounded_composition_overflow_regression.pas
../build/bounded_composition_overflow_regression
