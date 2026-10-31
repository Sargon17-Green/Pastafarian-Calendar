# Stage 13 / PATCH01 — bounded canonical month-weave unranking

## Reproduced failure

- [Run 41203228263](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41203228263), SHA `836fa665774f8435641c0c85c36c2e826b190ef5`: the Stage13 job compiled, bound and linked with GNAT 13, then ran until the 15-minute job timeout. It produced no 25-assertion marker.
- [Diagnostic run 41211363442](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211363442), SHA `9a9385cf5a2ae65cae59cee528a20f4e8e5ef2e1`, job 124566875746: compile/bind/link succeeded. The opt-in trace completed gate expansion, Year5000 candidate selection, cutlet partition counting, and month-length selection. It then printed `STAGE13_DIAG=month_weave_count_begin` and hit the deliberately bounded 90-second timeout (exit 124). No calendar assertion ran. This reproduces the stall specifically inside the old month-weave count.

## Root cause

The old `Choose_Month_Weaving.Count` memoized the complete vector of remaining day counts for every legal partial weave, along with the opened and closed prefixes. For 45 months of length at least 4, after opening all months and before closing any, each month can independently retain any count from 1 through `Length-1`. Therefore the memoized state space has at least `3^45 = 2,954,312,706,550,833,698,643` reachable vectors. This lower bound alone makes the recursive full-family count infeasible. The phase trace confirms that this is the stage where the observed timeout occurs.

## Chosen bounded family

Replace the exhaustive family of all legal interleavings with a precisely defined **canonical two-rail family**:

1. Opening rail: emit month IDs `1..M` once each, in order.
2. Interior: lexicographically unrank every multiset permutation containing month ID `j` exactly `L_j-2` times.
3. Closing rail: emit month IDs `1..M` once each, in order.

For total year length `T = sum(L_j)`, the family size is exactly

`N = (T - 2M)! / product((L_j - 2)!)`.

At a state with `r` interior positions and `c_j` copies of month `j`, the number of completions beginning with `j` is exactly `Ways_Left * c_j / r`. This supports exact one-based lexicographic unranking in `O((T-2M) * M)` big-integer operations and `O(T+M)` storage.

This is an intentional, documented semantic narrowing: it preserves month multiplicities, deterministic rank-to-weave mapping, and ordered first/last occurrences, but it does **not** preserve the old family of every possible legal interleaving. It changes only the Ada normative reference implementation and its tests; no production source, main branch, merge, or publication is touched.

## Verification contract

- `tests/stage13_weave_tests.adb`: all 6 ranks for lengths `[4,4]`; all 210 ranks for `[4,5,4]` with exact count, strict lexicographic ordering and shape checks; first and last ranks for a 45-month stress case. Expected marker: `STAGE13_PATCH01_WEAVE_ASSERTIONS= 2595`.
- `tests/stage13_discovery10_tests.adb`: original 4 real `Calendar_Date` calls and 25 postconditions remain unchanged.
- The runner bounds the weave test to 180 seconds and the end-to-end test to 600 seconds. The workflow job remains bounded to 15 minutes.
- Accept Stage13 only if `verify` and `native-stage13-discovery10` both complete successfully on the same HEAD SHA, GNAT 13 compiles/binds/links, and both exact assertion markers appear.

The end-to-end assertions remain bounded postconditions, not an independent five-field numerical differential.

## First build attempt — isolated encoding correction

Run [41213536867](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41213536867) at `4d510268870def8fac715c5dda9695600e80acd8` passed `verify`, but every native job that compiled the shared normative package failed at the same six Telugu exception-message literals in `month_weaving.adb`: GNAT requires these wide-character messages to be wrapped in `Wide_Wide_Strings.Encode`, as in the existing oracle. No runtime or combinatorial assertion was reached. This commit applies only that isolated encoding correction; the algorithm and test contract are unchanged.
