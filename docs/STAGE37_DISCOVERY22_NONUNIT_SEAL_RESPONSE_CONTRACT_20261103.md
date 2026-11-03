# Stage37 / Discovery22 — nonunit seal-response differences across year-5000 gates

Project: `PC-BRANCH-POWERSHELL-TAGALOG`; branch: `PowerShell+Tagalog`.
Status: **CONTRACT ONLY; NOT IMPLEMENTED; NATIVE NOT RUN; NO STAGE37 PASS**.
No source/oracle/production or protected-branch changes are authorized by this contract.

## Evidence-first predecessor gate

At contract preparation, branch HEAD `dc219effb23b22d73bfc33a4de8a5a96f3e0f22e` was read directly from GitHub, and automatic run
[41688986669](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41688986669)
had completed/success on the identical commit and branch: **10/10 jobs**.
Actual logs: Stage36 1004/1004 and STAGE36_SEAL_RECHECK=PASS;
Stage35 896/896 and seal recheck PASS; Stage32 239/239; Stage30 96/96;
Stage28 71/71; canonical verify SUCCESS. Native Windows PowerShell 5.1
Stage23 finalizer: run 1/run 2 exit=0, stderr length=0, already finalized=True;
SHA256 before and after both runs equal
`BE46F878D5B35BA8BED423F19CD6E5624DEB044C6514DDC04937576B148475C3`.
This evidence proves the Stage36 exact-SHA seal, **not** Stage37.
No rerun of 41688986669 is required.

## New independent question

Stages 34–36 vary calculation day, target day and the seal **only between 1 and 2**.
The on-branch production function `Get-Discovery13AnswerStreamFromContext`
permits Seal integers 1..10, but requires `QueriedBowlId=1` and
`patch12QueriedBowlId=1`. Therefore an apparent extension to bowl IDs 2..6
would violate a known precondition. The independent unexplored dimension is
**nonunit seal displacement**: compare seals 1, 5 and 10 across normative
year-5000 open/close gate crossings. This is a bounded research question, not
a prediction of a defect, a nonzero contrast, or a distributional law.

## Exact finite domain

Dot-source **this branch's** `src/MonsterSkeleton.ps1`,
`oracle/NormativeScroll.ps1`, `tests/TestHarness.ps1`.
Let `f=Get-NormFoundationDay`, `year=Get-NormYear5000 -CalculationDay f`,
`O=year.OpenGateDay`, `C=year.CloseGateDay`, and `M=$script:Discovery01M`,
all converted to `System.Numerics.BigInteger`.
Require year.Number=5000, O<f<=C, 252<=C-O<=5778, and M>0.

Calculation-day axis: `O,O+1,C,C+1`; target-day axis:
`O,O+1,C,C+1`. Their Cartesian product has exactly **16 numerical
(c,t) contexts**, arranged as **four labeled 2x2 gate cubes**
(OPEN×OPEN, OPEN×CLOSE, CLOSE×OPEN, CLOSE×CLOSE).
At each context evaluate exactly **three seals 1,5,10**, giving **48
fresh independent production contexts and 48 separately evaluated
normative oracle streams**. No cache or mutable Context may be shared
between seal queries. Query bowl ID **1 only**.

`got=Get-Discovery13AnswerStreamFromContext -Context
(Invoke-CalendarDateSpaghetti -CalculationDay c -TargetDay t)
-QueriedBowlId 1 -Seal s`.
`want=Get-NormAnswerStream -SauceResult (Invoke-NormSauce c t)
-QueriedBowlId 1 -Seal s`. Do not derive `want` from `got`
or reuse another branch's fixtures or code.

## Observable mathematics and oracle comparisons

For every `(c,t,s)` assert six endpoint conditions: actual First=normative
First; actual Step=normative Step; 1<=First<=M; Step in {-1,+1};
`legacyOrderMemoryWriteCount=58`; `patch12InvocationCount=1`.

Define `δ(a,b) = ((b-a)%M+M)%M`. For each (c,t) and ordered seal pair
`(1,5),(5,10),(1,10)`, independently compute from actual and normative:
`U_ab=δ(F_a,F_b)` and `V_ab=(Step_a != Step_b)`;
compare both actual and normative. Also assert for both actual and normative
the composition `U_1,10 = (U_1,5 + U_5,10) mod M`, and
`V_1,10 = V_1,5 XOR V_5,10`.
Compare their nonunit-seal curvature
`K = [4*δ(F_5,F_10)-5*δ(F_1,F_5)] mod M`
and ternary step parity `P=(Step_1!=Step_5) XOR (Step_5!=Step_10)`
against separately computed oracle quantities.
Do not impose `K!=0` or `P=True` before observation.

Within each of the four gate cubes, at each seal, form the mixed
first-answer difference
`D_s=[F_11,s-F_10,s-F_01,s+F_00,s] mod M`
and the step XOR mixed face
`Q_s=(S_00,s!=S_01,s) XOR (S_10,s!=S_11,s)`.
Compute separately from actual and normative and compare.
For the three seal pairs compare `δ(D_a,D_b)` and `Q_a XOR Q_b`
(actual vs normative). Finally compare the 1→10 compositions of these
differences and flip parity using the 1→5 and 5→10 increments.

In printed evidence report K zero/nonzero, P true/false, gate-face contrasts
by seal, unique numeric contexts, endpoint counts and runtime. Observations
are evidence, never pre-inserted expected answers.

## Precisely counted assertions

- 48 fresh endpoints × 6 independent checks = **288**.
- 16 contexts × 3 seal pairs × 2 first/step difference checks = **96**.
- 16 contexts × 2 seal-composition checks = **32**.
- 16 contexts × 2 curvature/parity oracle comparisons = **32**.
- 4 gate cubes × 3 seals × 2 mixed-face checks = **24**.
- 4 gate cubes × 3 seal pairs × 2 mixed contrast checks = **24**.
- 4 gate cubes × 2 seal-composition checks = **8**.
- 12 structural/stage/year/domain/cardinality checks = **12**.
- TOTAL = **516 planned assertions**, allowed failures = **0**.
A counted assertion is one runtime TestHarness assertion, not an unverified
code-site estimate. Verify the arithmetic independently before wiring CI.

## Stage transition and gate policy

This **contract-only** commit does not change `DEVELOPMENT_STAGE.md`,
`CURRENT_STAGE=36`, `LAST_COMPLETED_STAGE=36`, the Stage36 seal,
or any historical expected-red claim. Its automatic CI result must not be
conflated with the Stage36 predecessor run.

Next: implement `tests/Stage37.Tests.ps1` using a distinct, independent
test-side algorithm for the mathematical contrasts; add one bounded Windows
PowerShell 5.1 job and retained artifact; extend predecessor gates *only* for
the exact Stage37 pending pair `CURRENT_STAGE=37`,
`LAST_COMPLETED_STAGE=36`, `STAGE37_RUNTIME_VERIFICATION=PENDING_NATIVE`.
Do not add guessed acceptance states to past tests.
Before moving state, read the exact HEAD and current workflow file and run
bounded static preflight. On implementing SHA, require completed/success,
516/516, all historical 10 jobs successful, canonical verify, and twice
idempotent finalizer with unchanged metadata SHA256. A later evidence seal
requires a separate exact-SHA completed/success CI run.
No main/merge/publish/force update and no statistical uniformity or
Gregorian mapping claim.


## Addendum: independent executable preflight before stage activation

Implementation is deliberately split into two verifiable steps. First,
`tests/Stage37.Tests.ps1` and a dedicated `stage37-nonunit-seal-preflight`
job run the finite 516-assertion research **while the canonical metadata
remain sealed at Stage36**. This is a safe independent preflight, NOT an
activation, NOT an accepted Stage37 Native stage, and NOT an evidence seal.
A completed/success preflight with the recorded exact SHA is necessary
but insufficient for advancing the canonical development stage.
Second, only after reading its logs, update the exact Stage37 pending
stage pair and predecessor compatibility gates, repeat Native on that
new SHA, and subsequently evidence-seal/recheck the new seal SHA.
No completed run's PASS may be transferred to a different commit.
