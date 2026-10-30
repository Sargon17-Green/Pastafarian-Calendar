#!/usr/bin/env bash
set -euo pipefail
chpl -M src -M test test/stage02_tests.chpl -o stage02_tests
./stage02_tests
