# Stage38 / Discovery23 — complete 1..10 seal sweep at foundation and distant-day contexts

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Existing branch: PowerShell+Tagalog
Status at authoring: EXECUTABLE PREFLIGHT IMPLEMENTED; NATIVE NOT YET VERIFIED; STAGE38 NOT ACTIVATED OR SEALED.

## Predecessor gate

Stage37 exact-seal run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41791419778 completed/success 11/11 on f8cb181f3ce4da45c2ca096d51d0592d72bbbaac. Windows PowerShell 5.1 Stage37 516/516, failed 0, STAGE37_SEAL_RECHECK=PASS; Stage36 1004 and Stage35 896 with seal rechecks; Stage34 448; Stage32 239; canonical verify success; Stage23 finalizer ran twice with exit code 0, stderr 0, identical metadata SHA256 231F8F42420A6866A93378D8D64D124CC28C3E5568485CF7FBDA4342E825A42A. Stage37 evidence artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41791419778/artifacts/13303807176.

This is Stage37 accepted evidence only, not Stage38 PASS. The implementation commit for this preflight MUST receive its own exact-SHA Windows CI result.

## Independent question

Stage37 measured the separated seals {1,5,10} over four year-5000 gate cubes. Stage38 asks what the **entire legal seal domain 1..10** does to First and Step, including pairwise differences, second finite differences and observable stream collisions, at another finite context family: foundation day and a distant day. No defect, monotonicity, period, nonzero curvature, absence of collisions, statistical law or mapping to civil dates is presumed.

## Exact finite input

Dot-source the same branch's src/MonsterSkeleton.ps1, oracle/NormativeScroll.ps1 and tests/TestHarness.ps1. Let f=Get-NormFoundationDay, M=$script:Discovery01M (BigInteger), d=f+36525 (BigInteger). Derive normative year5000 via Get-NormYear5000 -CalculationDay f; assert year=5000 and O<f<=C. Require M>0. Calculation days {f,d}; target days {f,d}; Cartesian 4 DISTINCT (c,t) contexts, exactly 10 seals s in [1,10] per context, bowl id EXACTLY 1, 40 fresh production contexts and 40 separately computed normative answers.

Per endpoint invoke independently:
- actual: Invoke-CalendarDateSpaghetti(c,t), then Get-Discovery13AnswerStreamFromContext(Context, QueriedBowlId=1, Seal=s).
- expected: Get-NormAnswerStream(SauceResult=Invoke-NormSauce(c,t), QueriedBowlId=1, Seal=s).
Never share mutable production contexts between seal samples, compute expected from actual, or copy oracle/fixtures from another branch.

For each endpoint assert First and Step equal independent normative oracle; 1<=First<=M; Step in {-1,1}; legacyOrderMemoryWriteCount=58; patch12InvocationCount=1. For each of the 45 unordered distinct seal pairs i<j in every context, compare modulo-M First delta δ(F_i,F_j)=((F_j-F_i)%M+M)%M and Step flip (S_i!=S_j) against separately materialized normative equivalents. Count unordered First collisions and full stream (First,Step) collisions; compare the latter count with normative separately (not assumed zero). For eight consecutive seal triples (i,i+1,i+2) with i=1..8 per context, compare curvature δ(δ(F_i,F_(i+1)),δ(F_(i+1),F_(i+2))) and two-edge Step XOR parity with the independent oracle. Report empirical zero/nonzero curvature, parity and collision counts without constraining their values.

## Exact assertion budget

- 12 metadata/structural/normative guards.
- 40 endpoints x 6 = 240.
- 4 contexts x C(10,2) x 2 pairwise First/Step comparisons = 360.
- 4 contexts x 8 triples x 2 curvature/parity comparisons = 64.
- 4 independently compared collision counts = 4.
- TOTAL = 12+240+360+64+4 = **680**; pass requires 680/680, failure=0, context count=4, endpoint count=40, all pairs=180, triples=32, collision comparisons=4.

Counts refer to executed TestHarness assertions, not merely source-site counts.

## Activation and acceptance

The preflight changes only this contract, the standalone tests/Stage38.Tests.ps1, a branch-scoped Windows PowerShell 5.1 CI job with retained artifact, and Stage37 exact-seal evidence metadata. CURRENT_STAGE and LAST_COMPLETED_STAGE remain 37; no Stage38 runtime state is promoted; no production, normative oracle, canonical lock, main, merge or publication change.

Check the automatically triggered new-SHA run (do not dispatch a duplicate). Accept **preflight only** if it completes successfully with 12 prior jobs (existing 11 + new Stage38), Stage38 680/680 and zero failures, all Stage37 exact-seal/predecessor jobs successful, canonical verify and twice-idempotent finalizer. Only after reading full completed logs and artifact may Stage38 pending activation and predecessor gate changes be considered. Follow with a new exact-SHA full CI and separate evidence seal/recheck; do not treat the preflight as Stage38 accepted. No claim about statistical uniformity or unbounded inputs.
