#!/usr/bin/env bash
set -euo pipefail

# Ⲡaudit ⲙⲡⲃⲁⲑⲙⲟⲥ 56 ⲙⲟⲟϣⲉ ⲙⲙⲁⲧⲉ ⲉⲛAssembly executables; ⲙⲛ computational oracle ϩⲛ shell.
./build/stage56_runtime_soft_failure_audit
./build/stage56_semantic_runtime_audit
