#!/usr/bin/env sh
set -eu
lake build
lake exe pastafari_stage1_tests
