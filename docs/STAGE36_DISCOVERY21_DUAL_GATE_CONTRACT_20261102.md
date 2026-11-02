# Stage36 / Discovery21 — dual-gate calculation–target response (contract-first)

Project: `PC-BRANCH-POWERSHELL-TAGALOG`; **existing** branch `PowerShell+Tagalog`.
Status: **CONTRACT ONLY; no Stage36 source/test/workflow execution and no Stage36 Native PASS.**
All stage numbers are internal development milestones, not Gregorian date parts.

## Verified prerequisite and exact-SHA seal

Previous commit: `ab698bfd046c649f8e6ab84d5055a7ccfe7521d1`. Its automatic [Actions run 41408679087](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41408679087) completed/success, all **9/9 jobs** on the exact branch and SHA. Log observations: Stage35 **896/896**, zero failures, `STAGE35_SEAL_RECHECK=PASS`; predecessor 664+309+441+85+239+560+448 = **2746/2746**; total **3642/3642**. Native Windows PowerShell 5.1 Stage23 finalizer ran twice: `ALREADY_FINALIZED=True`, exit 0, stderr length 0, identical pre/post metadata SHA256 `CF3656F5BBDB3084EF32785B650AAF06C2B50B9B1BF264752AC3207028ECF2FE`; canonical names verify succeeded. The new contract commit itself needs its own CI evidence; do not transfer PASS from prior SHA.

## Motivation and distinction from Stages 34–35

Stages 34–35 varied `CalculationDay` only in small positive offsets from the **foundation day** while the `TargetDay` crossed the year-5000 gates; Stage35 compared nonunit displacement scales. They did **not** jointly cross a normative year gate on both input axes. Stage36 studies the crossed local response at the year-5000 **open/close boundaries** when *both* `CalculationDay` and `TargetDay` vary. It makes no claim that any nonzero, sign-change, or distributional phenomenon exists before observation.

## Exact inputs and finite domain

Load the existing **on-branch** `src/MonsterSkeleton.ps1`, `oracle/NormativeScroll.ps1` and `tests/TestHarness.ps1`. Let `f = Get-NormFoundationDay`, `y = Get-NormYear5000 -CalculationDay f`, `O=y.OpenGateDay`, `C=y.CloseGateDay`; all ordinal arithmetic uses `System.Numerics.BigInteger`. Check `y.Number=5000`, `O<f<=C`, year length `252<=C-O<=5778`, and `C-O` has a positive gate span. The normative gate interval is **(O,C]**: `O` is excluded, `O+1` included; `C` included, `C+1` excluded.

Four independent **calculation-day** adjacent pairs `(c,c+1)`:
1. `(O,O+1)` (crosses open);
2. `(C,C+1)` (crosses close);
3. `(f-1,f)` (foundation control);
4. `(f+36525,f+36526)` (distant control).

Four **target-day** adjacent pairs `(t,t+1)` are **the same four explicitly derived pairs**. Take the Cartesian product: **16 labeled cubes** (4 calculation-pair labels × 4 target-pair labels), not a claim of 16 numerically unique behaviors. For each cube, evaluate four coordinates `(c+i,t+j)`, `i,j in {0,1}`, and `Seal in {1,2}`: **64 labeled contexts, 128 independent endpoint samples**, 64 seal edges, 32 seal-specific faces, 16 third-axis contrasts. Never infer independent statistical samples merely from distinct labels.

## System under test and independent expected value

For each endpoint, construct a fresh context (no cache shared across seal queries):
`ctx = Invoke-CalendarDateSpaghetti -CalculationDay (c+i) -TargetDay (t+j)`
then `got = Get-Discovery13AnswerStreamFromContext -Context ctx -QueriedBowlId 1 -Seal s`.
Separately compute `wanted = Get-NormAnswerStream -SauceResult (Invoke-NormSauce (c+i) (t+j)) -QueriedBowlId 1 -Seal s`. The oracle is the existing independent NormativeScroll implementation; **do not** derive wanted values by transforming production outputs, copy fixture data from another language branch, or use another branch's source.

For each endpoint assert `got.First == wanted.First`, `got.Step == wanted.Step`, `1 <= got.First <= M` (where `M = $script:Discovery01M`), `got.Step in {-1,+1}`, `ctx.legacyOrderMemoryWriteCount == 58`, `ctx.patch12InvocationCount == 1`.

For integer first answers define modular subtraction `sub_M(a,b)=((a-b)%M+M)%M`. For each seal `s` compute
`D_s = sub_M(sub_M(F(c+1,t+1,s),F(c+1,t,s)), sub_M(F(c,t+1,s),F(c,t,s)))`.
Let `Q_s = ((Step(c,t,s) != Step(c,t+1,s)) XOR (Step(c+1,t,s) != Step(c+1,t+1,s)))`.
Across seals define `E=sub_M(D_2,D_1)` and `R=Q_2 XOR Q_1`.
Compute *each* of these quantities independently for actual and normative results; compare them exactly. In addition, compare for each of four coordinates the modular seal difference in `First` and whether `Step` flipped across seals. **Do not assert `E!=0` or `R=True` in advance**; report empirical counts (zero/nonzero and flip/same) only after a successful run.

## Measurable assertion budget and acceptance

- Endpoint assertions: `16 cubes × 4 coordinates × 2 seals × 6 checks = 768`.
- Cross-seal edges: `16 × 4 × 2 (First & Step) = 128`.
- Within-seal mixed faces: `16 × 2 × 2 (D & Q) = 64`.
- Cross-seal third-axis: `16 × 2 (E & R) = 32`.
- **Core: 992 assertions**; plus **12 predeclared structural checks** (project/stage metadata, predecessor seal, historic expected-red, normative year identity, foundation containment, year-length bound, gate-span bound, pair counts on each axis, cube count, endpoint count, and nonzero modulus): **1004 planned assertions**, zero allowed failures. Count each assertion once; a later implementation may revise the declared total only with explicit explanation and aligned tests/CI.

Reject invalid `Seal`/`QueriedBowlId` only if corresponding strict input contracts are established in on-branch source; avoid inventing expected-red tests. Require exact SHA checkout, Windows PowerShell 5.1, `1004/1004`, zero failures, independent oracle parity, 9 prior jobs and canonical verify preserved (job count will increase if Stage36 is wired), and Stage23 finalizer twice with identical SHA256. Use bounded CI runtime, retain transcript, counts, job and artifact identifiers. The first run that implements this contract is **pending**, not accepted until completed logs. A later seal requires a separate exact-SHA successful run.

## State-transition policy

This contract-only step changes **only a research document and non-executable stage planning/evidence metadata**. Keep `CURRENT_STAGE=35`, `LAST_COMPLETED_STAGE=35`, `STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED` and all sealed predecessor flags unchanged. Do not touch production, oracle, CI workflows, main, merge or publication. Next step: implement `tests/Stage36.Tests.ps1`, add a bounded dedicated Windows job and only then change `CURRENT_STAGE=36`, `LAST_COMPLETED_STAGE=35`, `STAGE36_RUNTIME_VERIFICATION=PENDING_NATIVE`; inspect existing predecessor dispatch gates before changing them. 
