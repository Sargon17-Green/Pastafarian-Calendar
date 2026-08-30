#!/usr/bin/env bash
set -euo pipefail
./build.sh
./build/stage01_tests
./build/stage01_smoke
./build/stage02_discovery01
./build/stage03_patch01
./build/stage04_discovery02
