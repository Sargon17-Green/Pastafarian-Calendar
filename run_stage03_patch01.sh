#!/bin/sh
set -eu

# Issue29 GMP-aware restoration of the existing, non-calendar Stage03 tests.
# Do not use gnatmake -Isrc -Itests: the patched Normative_Oracle imports GMP.
command -v gprbuild >/dev/null 2>&1 || { echo 'GPRBuild required for GNATCOLL.GMP' >&2; exit 127; }
command -v timeout >/dev/null 2>&1 || { echo 'timeout required for bounded native test' >&2; exit 127; }
gprbuild -p -j2 -P pastafari_calendar_legacy_gmp.gpr -XNATIVE_MAIN=stage03_patch01_tests.adb
timeout --signal=TERM --kill-after=5s 90s ./bin_gmp_legacy/stage03_patch01_tests
