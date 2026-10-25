# Stage 55 — polynomial family implementation versus historic production DAG

**Status**: awaiting native MATLAB R2026a test. **Branch**:
`MATLAB+Polski`. Historic production class and wrapper remain unchanged.

The original `WholeMonthWeavingFamily` constructor enumerates every
reachable remaining-multiplicity vector in a DAG. Its native full-year
audit repeatedly reached only day 16 (32768 states) before runner
shutdown. Such an exponentially expanding state store cannot support
the genuine 45-month, 4244-day year.

`WholeMonthWeavingFamilyPolynomial` is a separate, experimental,
interface-compatible family with `count()` and `itemAt1(rank)`.
Its constructor uses the independently validated exact first-endpoint
single-vector DP to calculate the whole-family BigInt count in
polynomial memory. Lexicographic inversion delegates to the newly
validated adjoint two-pass exact first-letter blocks and returns
the complete word, with terminal invariants. The extra
`prefixAt1(rank,maxSteps)` method exposes truthful intermediate
cursors and never treats a partial prefix as a complete date.

The test `run_stage55_polynomial_family_equivalence_tests`
constructs BOTH the historic production family and the new
polynomial family for nine bounded families, checks equal exact
cardinalities and compares every original `itemAt1` result against
the replacement. For each rank, it also checks zero-, one-, mid-
and whole-prefix selection and cursor counts, plus input validation.

Native markers required to certify this narrow scope:
- `STAGE_55_POLYNOMIAL_FAMILY_EQUIVALENCE_PASS`
- `STAGE_55_POLYNOMIAL_FAMILY_VALIDATION_PASS`
- `STAGE_55_POLYNOMIAL_FAMILY_EXPERIMENTAL_PASS`

**Deliberate limits:** no production route has been switched, no
semantic change has been asserted, and no full-year `itemAt1` has
completed. Existing exact four-day real-year adjoint passed in
[run 40181731061](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40181731061)
(894.800 sec for four days, plus 177.195 sec independent recount).
Small-family equivalence alone is NOT enough to promote the
replacement or close Stage55. The independent `normative_oracle`
remains unchanged and five-field differential is outstanding.
`LAST_COMPLETED_STAGE=54`.
