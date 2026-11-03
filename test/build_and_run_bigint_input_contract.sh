#!/bin/sh
set -eu
python3 verify_bigint_input_contract.py
mkdir -p ../build
fpc -B -Fu../src -Fu. -FE../build bigint_input_contract_regression.pas
../build/bigint_input_contract_regression
