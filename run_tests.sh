#!/bin/sh
set -eu
mkdir -p build
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -c src/big_integer.f90 -o build/big_integer.o
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -I build -c src/source_language_catalog.f90 -o build/source_language_catalog.o
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -I build -c src/bootstrap_infrastructure.f90 -o build/bootstrap_infrastructure.o
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -I build -c test/normative_oracle_core.f90 -o build/normative_oracle_core.o
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -I build -c test/normative_oracle_calendar.f90 -o build/normative_oracle_calendar.o
gfortran -std=f2018 -Wall -Wextra -fcheck=all -ffree-line-length-none -J build -I build test/stage01_tests.f90 build/big_integer.o build/source_language_catalog.o build/bootstrap_infrastructure.o build/normative_oracle_core.o build/normative_oracle_calendar.o -o build/stage01_tests
./build/stage01_tests
