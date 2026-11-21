# Stage 1 QA production advanced conditional route — 2026-10-09

Scope: `qa-befunge98-stage1-order-isolation-20261008` only, Draft PR #17.
Canonical `Befunge+Кыргызча` and `main` remain unchanged.
`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`.

## Exact source-map change

QA production `src/interleaved_work_counts.b98` uses Git blob
`20ff8d38011017fa9182147e864347be4ca9a79c`,
which was independently Native-qualified as
`qa/interleaved_work_counts_advanced_turn_jump_candidate.b98`.
The prior data-dependent fork `qa/interleaved_work_counts_native_bifurcation_candidate.b98`
remains immutable. The source-map guard proves exactly 11 changed Funge
cells relative to that previous proven source; it retains the older
lexical-scanner and k+ proofs rather than deleting their conditions.

The upper route executes `]` at (951,1334), moves the original operand
`0` through a vertical lane, executes `j` at (958,1331) with a
five-cell skip, executes moved `c` and dynamic-vector preparation,
then `x` at (958,1322) returns via vector (1,12).
The landing `>` at (959,1334) restores cardinal motion, preserving
the original arithmetic before the terminal `x` and the shared join.
The lower route executes `[` at (951,1336).
Both branches depend on the measured input-dependent `|` at (951,1335).

## Native evidence

- [Native-qualified candidate run 37856183711](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37856183711):
  10/10 Native exact Befunge oracle differential, 10/10 Native stack/
  route checks, both `[` and `]` actually used; upper branch uses
  `j`, actual skipping, moved `c`, dynamic `x`, heading-reset `>`
  and exact rejoin. Complete raw native TSV traces and JSON proof were
  uploaded as `befunge-kyrgyz-advanced-turn-jump` artifact 11584321470.
- Failed exploratory runs 37855368443, 37855703729, 37855974158
  traced stack-vector ordering and retained non-cardinal direction.
  These failures were fixed **before** source promotion, not excluded from
  the decision record.

## Acceptance boundaries

A ten-case focused proof and a clean overall CI run (to be verified on
this exact production SHA) do not complete either independent Stage 1
acceptance gate. Full semantic state ownership and advanced stack-stack,
dynamic cell lifecycle, multi-route cycle/crossing acceptance remain open.
No Stage 2 work and no merge are authorized by this note.
