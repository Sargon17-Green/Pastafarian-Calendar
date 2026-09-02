#!/usr/bin/env sh
set -eu
DMD_BIN="${DMD_BIN:-dmd}"
"$DMD_BIN" -i -Isource -unittest -debug -of=stage01_tests tests/stage01_tests.d tests/normative_oracle.d source/pastafari/catalog.d source/pastafari/monster_base.d
./stage01_tests
rm -f stage01_tests stage01_tests.o
