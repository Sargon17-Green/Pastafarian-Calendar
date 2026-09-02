#!/bin/sh
set -eu
exec guile -s test/run-tests.scm
