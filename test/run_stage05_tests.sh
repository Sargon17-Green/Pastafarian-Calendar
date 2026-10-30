#!/usr/bin/env bash
set -euo pipefail
chpl -M src -M test test/stage05_tests.chpl -o stage05_tests
./stage05_tests
