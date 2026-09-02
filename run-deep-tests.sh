#!/bin/sh
set -eu
exec guile -s test/run-deep-tests.scm
