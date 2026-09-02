#!/bin/sh
set -eu
gprbuild -p -P pastafari_calendar.gpr
./bin/stage01_tests
