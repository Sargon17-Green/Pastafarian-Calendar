#!/usr/bin/env bash
set -euo pipefail
./build.sh
./build/stage01_tests
./build/stage01_smoke
./build/stage02_discovery01
