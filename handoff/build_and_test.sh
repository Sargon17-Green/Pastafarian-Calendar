#!/bin/sh
set -eu

cobc -std=default -free -x -o bootstrap-tests \
  src/big_integer.cob \
  src/source_language_catalog.cob \
  src/monster_bootstrap.cob \
  test/oracle/oracle_constants.cob \
  test/oracle/oracle_bigint.cob \
  test/oracle/normative_basic.cob \
  test/oracle/normative_bigint_primitives.cob \
  test/oracle/normative_sauce.cob \
  test/oracle/normative_selection.cob \
  test/oracle/normative_families.cob \
  test/oracle/normative_weaving.cob \
  test/oracle/normative_gates.cob \
  test/oracle/normative_year.cob \
  test/oracle/normative_oracle.cob \
  test/big_integer_tests.cob \
  test/normative_primitive_tests.cob \
  test/source_catalog_tests.cob \
  test/family_bruteforce_tests.cob \
  test/selection_tests.cob \
  test/bootstrap_tests.cob

./bootstrap-tests
