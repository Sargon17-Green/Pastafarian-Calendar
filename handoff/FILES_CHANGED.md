# Stage 1 Handoff - QA Inventory

Existing Stage 1 sources include:
- src/big_integer.f90
- src/source_language_catalog.f90
- src/bootstrap_infrastructure.f90
- test/normative_oracle_core.f90
- test/normative_oracle_calendar.f90
- test/stage01_tests.f90

This focused QA patch adds the three missing handoff prose files, moves the existing ASCII prose assertion into the bounded Oracle smoke path, and increases the CI smoke assertion lock from 50 to 51.

No production algorithm changes are included. The bounded Oracle smoke remains narrower than full Stage 1 acceptance.

This inventory describes the current QA change; it is not a reconstruction of a lost historical handoff.
