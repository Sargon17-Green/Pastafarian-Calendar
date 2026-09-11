# Python+Türkçe — Patch 28 checkpoint regression test follow-up

Repository: `Sargon17-Green/Pastafarian-Calendar`
Branch: `Python+Türkçe`
Base/observed HEAD: `e65a951a2fb80a85bcef7c4019c1eb8e110a9ed2`

## Scope

This follow-up changes only `tests/test_acceleration_patches_27_33.py`.
No production/calendar/acceleration implementation is changed.

The prior CI run passed 409/410 tests.  The only failure was
`test_poisoned_checkpoint_is_rejected_then_legacy_year_walk_finishes`.
The saved-sum correction changed the Year 5000 anchor geometry, so the old
fixed target `FOUNDATION_DAY + 1000` could make the injected checkpoint no
closer than the anchor.  In that case the acceleration layer correctly
classified it as a miss instead of selecting it and later recording a poisoned
checkpoint rejection.

## Test witness correction

The revised test derives a target from the current anchor:

`target_day = anchor.close_gate_day + 1`

The injected false checkpoint claims an exact distance-zero hit for that target
while retaining the Year 5000 gate indices.  Therefore it must be selected over
the anchor (distance one), fail gate-boundary validation, be recorded as
rejected/poisoned, and then fall back to the legacy year walk.

## Validation performed locally

- Python syntax compilation of the changed test file: PASS.
- Branch HEAD revalidated before packaging: exact match with the base above.
- Full repository test execution was not possible in the local packaging
  environment; the GitHub Actions workflow should be rerun after upload.

No deletions. No commit or push was performed.
