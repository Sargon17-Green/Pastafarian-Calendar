#!/bin/sh
set -eu
python3 verify_bigint_divmod_wide_quotient768.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_divmod_wide_quotient768.pas
../build/bigint_divmod_wide_quotient768
