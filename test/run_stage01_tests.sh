#!/usr/bin/env bash
set -euo pipefail
chpl -M src -M test test/stage01_tests.chpl -o stage01_tests
./stage01_tests
