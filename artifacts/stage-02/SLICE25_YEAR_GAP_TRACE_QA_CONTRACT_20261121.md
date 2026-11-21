# Slice25 QA-only bounded year/gate-gap tracer — SQL+தமிழ்

**Project:** PC-BRANCH-SQL-TAMIL. **Parent:** `d0287c2c3e13f6002daa23ae52ef947ea3dcd353`. **Branch:** SQL+தமிழ்.

## Observed defect in prior instrumentation
Run [44928511225](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928511225)
completed/failure on 59e139f: one `find_target_year` interval measured
694470.435 ms **inclusive**, while an uninstrumented
`negative_gate_gap -> gate_gap_signed -> sauce` path subsequently timed out.
The 6203.125-ms observed sauce call was only one traced call, not total sauce
cost. No five-field QA verdict was reached. Previous original-ZIP forensic
audit at d0287c2 validated SHA-256/CRC, not the target year function.

## Contract
- **Inputs:** exact existing `prev_3_prev_middle` calculation day -15055671,
  target -15072356. Separate negative gate-offset 1 diagnostic.
- **Source lock:** seven exact branch-local Git objects? Precisely **six**:
  production SQL 10,13,16,17,18 and historic independent 151 JSONL.
  Any mismatch aborts *before* PostgreSQL and before any QA assertion.
- **No production changes:** clone definitions into `qa_*` SQL functions only,
  proving unique-string substitutions and byte-exact inversion in local
  generation. Existing original functions 00..27 load in order, untouched.
- **Call coverage:** `qa_find_target_year` wraps seed year5000 and each
  next_year/previous_year transition; QA copies of year5000's gate-window and
  adjacent-year navigation wrap positive/negative gate-gap, gate_gap_signed
  and original sauce calls. Each wrapper logs ENTER before the call and EXIT
  with wall time in milliseconds after it. A timeout's trailing unmatched ENTER
  identifies the last in-flight operation. Nested durations MUST NOT be added.
- **Independent oracle:** year_first/year_last from the locked 29-case historical
  corpus imply eight boundaries by `open=first-1,close=last`; consecutive
  years must share boundaries. For year 4996, open=-15074038,
  close=-15070673 and -15072356 lies in (open,close]. Production year output
  must match all three fields. This corpus is historical evidence, not generated
  from the traced function. The gap result must be integral and within [42,963],
  and match a *separate* original-production evaluation; equality alone is not
  treated as an independent oracle.
- **Budgets:** gap/equivalence SQL statement max 60s; navigation max 180s.
  One isolated PG17.12 database, one run, no retry or full 56-job matrix.
  Archive immutable SHA, source manifests, generated SQL, full logs and exit
  codes whether completed or timed out. Neither an ENTER nor static PASS is
  a Native PASS.
- **Accept:** native gap equivalence 1/1 and year-boundary 3/3 only when
  their notices and exit 0 are present in completed exact-SHA job and original
  artifact is verified. These two diagnostics **never imply Slice25
  acceptance**; normative five-field and differential gates remain separate.
  Timing and cloning can alter planner behavior, so this diagnoses path cost
  but does not prove production runtime equivalence.

NEXT after first completed run: inspect raw job logs and original ZIP digest/CRC;
locate dominant unmatched ENTER and decide a narrower source-locked production
optimization or independent differential probe. No main/merge/release.
