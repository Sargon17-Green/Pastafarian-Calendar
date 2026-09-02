#!/bin/sh
set -eu
mmc --make --search-directory src --search-directory test stage01_tests
./stage01_tests
