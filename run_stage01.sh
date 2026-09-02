#!/usr/bin/env sh
set -eu
rm -f stage01_tests stage01_tests.u stage01_tests.c
unicon -o stage01_tests src/source_language_catalog.icn src/normative_oracle.icn src/monster_bootstrap.icn test/stage01_tests.icn
./stage01_tests
