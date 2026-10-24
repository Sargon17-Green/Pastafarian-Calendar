# Legacy Native gate-anchor regression: source-consistent, causally isolated forgery

Affected QA-only test: qa/test_stage1_native_four_cell_pg_event_coverage.py.
Historical failed Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39028560385
Failed job: native-four-cell-full-postfork-four-pairs (117384284215), line 349.
86 jobs were run; 85 successful; this one failed.

The old skipped_physical_first_cell mutation moved ONLY the first
postfork record from y=1334 to y=1333. However the remaining records stayed
on y=1334: the first synthetic '>' then incorrectly produced a successor
on a different directed axis. The regular postfork geometric verifier
correctly rejected it BEFORE the gate-anchor check. This invalidated the
test's claim that the rejection was unique to the gate-anchor invariant.
This is QA fixture construction, not evidence that production Funge is wrong.

The corrected mutation creates an independent altered source copy with
row 1333 containing the same real source bytes as row 1334. It shifts
the ENTIRE postfork route to y=1333 and rebuilds the bounded independent
prefix observer. The forged route is now internally straight and physical
byte-consistent (including p/g receipts and @ termination). The original
gate remains at (951,1335), and physical (951,1334) still contains '>';
therefore that physical first instruction cannot have been skipped. With
require_gate_anchor=False the forged record must pass. With
require_gate_anchor=True it MUST fail. The Python test enforces both.

This is intentionally narrow: the authoritative audit verifier, source
production, reference files, and the earlier failed Native run remain
unchanged. Until an exact-head regression concludes SUCCESS, do not claim
the legacy regression is fixed.
