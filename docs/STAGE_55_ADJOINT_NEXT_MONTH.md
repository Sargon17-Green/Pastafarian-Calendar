# Stage 55 — scalar forward/adjoint exact next-month partition

**State:** native MATLAB tests PENDING. Canonical/production engine,
main and test-only `normative_oracle` are unchanged. Stage 55 open.

The source `countWholeWeavingSuffixByFirstEndpoint` now optionally
returns exact full-family counts for each prefix of inserted month IDs
as a second output. Its one-output semantics and existing callers
remain unchanged.

The new exact adjoint recurrence computes EVERY legal first-letter
block in a single forward plus backward pass of scalar first-position
arrays (O(months * days) BigInt arithmetic and O(days) BigInt cells,
plus 45 prefix totals), not a per-label first-position matrix.

For insertion of largest month j at first position p and last position
N, the interior-copy coefficient is C(N-p-1,m-2). A previous
first-letter label is retained only for p>=2; if j is unopened, its
first occurrence must follow the earlier largest month's first:
p>f. Therefore backwards retention weights obey

  W_old(f)=sum_{p>=2, and p>f if required}
            C(N-p-1,m-2)*W_new(p).

Whenever j is a legally opened-or-next first letter, its exact child
block is

  block_j=forwardTotal(j-1)*C(N-2,m-2)*W_j(1).

The first remaining month's block is W_first(1). A single-copy month
cannot become the first letter unless it is the first remaining month;
it is appended at the final position. Backwards, its weight is the
single final-position weight copied to every earlier f.

Independent small-family lexical enumeration verifies every reachable
frontier, every legal and illegal first label and many full rank
inversions. The real-year 4244-day pilot separately checks the four
initial first letters [1 2 3 4] of the 6765-digit interior rank and
recounts all 4240-day completions from the resulting frontier.

For comparison, earlier native **binary cumulative first-letter** job
[40169982048](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40169982048)
completed four real-year days in 1118.072 seconds (plus 186.506
seconds for independent child recount), and the binary brute native
[40169982046](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40169982046)
passed 53 frontiers, 210 thresholds, 208 full inversions and 204
chunk-resume checks.

Do NOT treat the adjoint method as faster or PASS until native logs
contain all `STAGE_55_ADJOINT_*` and
`STAGE_55_REAL_YEAR_ADJOINT_FOUR_*` markers. No five-field
`normative_oracle` differential has completed; the old full production
DAG still receives runner-shutdown in Stage 55 audit, latest
[40169981986](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40169981986).
`LAST_COMPLETED_STAGE=54`.
