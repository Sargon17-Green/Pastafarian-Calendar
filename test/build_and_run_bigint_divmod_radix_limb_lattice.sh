#!/bin/sh
set -eu
python3 verify_bigint_divmod_radix_limb_lattice.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_divmod_radix_limb_lattice.pas
../build/bigint_divmod_radix_limb_lattice
