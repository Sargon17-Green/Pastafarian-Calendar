#!/usr/bin/env bash
set -euo pipefail
chpl -M src -M test test/stage04_tests.chpl -o stage04_tests
./stage04_tests
