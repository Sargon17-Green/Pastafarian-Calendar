#!/bin/sh
set -eu
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build stage01_tests.pas
../build/stage01_tests
