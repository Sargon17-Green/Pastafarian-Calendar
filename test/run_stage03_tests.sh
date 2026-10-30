#!/usr/bin/env bash
set -euo pipefail
chpl -M src -M test test/stage03_tests.chpl -o stage03_tests
./stage03_tests
