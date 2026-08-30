#!/usr/bin/env bash
set -euo pipefail
./build.sh
./build/stage01_tests
./build/stage01_smoke
./build/stage02_discovery01
./build/stage03_patch01
./build/stage04_discovery02
./build/stage05_patch02
./build/stage06_discovery03
./build/stage07_patch03
./build/stage08_discovery04
