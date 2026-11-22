#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"
python3 -B qa/issue29_stage41_provenance_runner_v12.py --selftest --output qa-selftest-v12