# Stage39 / Discovery24 — complete seal-by-context interaction (contract only)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Status: CONTRACT ONLY — NOT IMPLEMENTED; STAGE39 NATIVE NOT RUN; STAGE39 NOT ACTIVATED OR SEALED.
As of this contract, DEVELOPMENT_STAGE.md stays CURRENT_STAGE=38, LAST_COMPLETED_STAGE=38, CURRENT_DISCOVERY=23. No source, normative oracle, protected branch, merge or publication change is authorized.

## Evidence-first predecessor acceptance

Exact sealed-Stage38 GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187764495
Commit and branch HEAD at inspection: dec610f55fb67dc6abf55bbc243e5c3dcaacdf73 (PowerShell+Tagalog).
Run completed/success, 12 of 12 jobs completed/success, attempt 1; verify successful. Native Windows PowerShell 5.1 Stage38: 680/680, 0 failures, STAGE38_SEAL_RECHECK=PASS; Stage37: 516/516, 0 failures and seal recheck PASS; Stage36: 1004/1004, 0 failures and seal recheck PASS; Stage35: 896/896, 0 failures and seal recheck PASS. Stage28: 71/71, Stage30: 96/96, no failures. Windows Stage23 finalizer: first and second exit code 0, stderr length 0, ALREADY_FINALIZED=True, metadata SHA256 unchanged before/after both runs: 396599AC2B9872B763E03A0A062734E92F09F1F4CE1D6C97481C10325117247E.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187764495/artifacts/13488143271 (Stage38 native); https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187764495/artifacts/13488027583 (Stage23 finalizer).
This establishes Stage38 exact-seal acceptance on THAT SHA only. A new contract-only commit does not inherit new-SHA Native evidence. Do not rerun the prior SHA unnecessarily.

## Independent question, deliberately not a predicted bug

Stage38 tested every seal 1..10 independently inside each of four calculation/target contexts, including within-context pairs and triples. Stage37 tested mixed calculation/target gate faces only for separated seals 1,5,10. Stage39 investigates the **full seal response of the mixed calculation-by-target face** across all 10 legal seals at foundation and distant-day contexts. This interaction is not covered by the Stage38 within-context assertions. No nonzero difference, collision absence, smoothness, distributional law, or Gregorian date mapping is assumed. Research must report observed values and cannot label an expected-red result without a reproducible mismatch.

## Bounded exact input and independent oracle

Dot-source only the same branch's src/MonsterSkeleton.ps1, oracle/NormativeScroll.ps1 and tests/TestHarness.ps1. Define f = [BigInteger](Get-NormFoundationDay), M = [BigInteger]$script:Discovery01M, and d=f+[BigInteger]36525. Verify Get-NormYear5000(f) has Number=5000 and OpenGateDay < f <= CloseGateDay; M>0. Calculation days c in {f,d}, target days t in {f,d}. Four DISTINCT numeric (c,t) contexts. Seals s in integer 1..10. QueriedBowlId=1, patch12QueriedBowlId=1; do not expand bowl IDs beyond the known precondition.

For each of exactly 4 x 10 = 40 endpoints, build a FRESH production context with Invoke-CalendarDateSpaghetti(c,t) and evaluate Get-Discovery13AnswerStreamFromContext(Context,QueriedBowlId=1,Seal=s). Separately evaluate Get-NormAnswerStream(SauceResult=Invoke-NormSauce(c,t),QueriedBowlId=1,Seal=s), using the branch's independent normative oracle. Do not reuse mutable production state across seals or derive expected outputs from actual output, and do not copy oracle code/fixtures from another branch.

Let F_00(s) correspond to c=f,t=f; F_01(s) to c=f,t=d; F_10(s) to c=d,t=f; F_11(s) to c=d,t=d. S_ij(s) is the corresponding Step. All modular values use nonnegative modulo M: modM(x)=((x%M)+M)%M. Define the mixed face per seal:
D_s=modM(F_11(s)-F_10(s)-F_01(s)+F_00(s)).
Q_s=(S_00(s)!=S_01(s)) XOR (S_10(s)!=S_11(s)).
Compute D_s and Q_s independently from actual and normative streams; compare them without assuming D_s!=0 or Q_s=true.

For all 45 unordered seal pairs 1<=a<b<=10, compute the mixed-face seal displacement E_ab=modM(D_b-D_a) and flip R_ab=(Q_a XOR Q_b), for actual and normative separately. Compare both values. For all eight consecutive seal triples (a,a+1,a+2), a=1..8, compute mixed-face second finite difference K_a=modM(modM(D_(a+2)-D_(a+1))-modM(D_(a+1)-D_a)) and mixed-face flip parity T_a=(Q_a!=Q_(a+1)) XOR (Q_(a+1)!=Q_(a+2)); compare both with normative separately.

Count unordered equal (D_s,Q_s) mixed-face states among all 45 seal pairs, separately for actual and normative, and compare counts. Report D=0/nonzero, Q=true/false, distinct D values, mixed-face pair collisions, K=0/nonzero and T=true/false. Do not assert particular observational counts or an unbounded theorem.

## Measurable acceptance budget (executed TestHarness assertions)

1. Twelve structural guards: Stage38 sealed state, Stage37 evidence, Stage36 evidence, Stage35 evidence, Stage26 historical expected-red retained (5); normative year 5000, foundation inside open/close gates, positive M, distant offset exactly 36525 (4); calculation-axis cardinality 2, target-axis cardinality 2, seal-axis cardinality 10 (3). Total 12.
2. Forty separately created endpoints x six checks: First matches normative, Step matches normative, First in [1,M], Step in {-1,+1}, legacyOrderMemoryWriteCount=58, patch12InvocationCount=1. Total 240.
3. Ten mixed calculation-target faces x two independent oracle comparisons (D_s,Q_s). Total 20.
4. C(10,2)=45 mixed-face seal pairs x two independent oracle comparisons (E_ab,R_ab). Total 90.
5. Eight consecutive mixed-face triples x two independent oracle comparisons (K_a,T_a). Total 16.
6. One independently compared count of identical mixed-face (D_s,Q_s) states. Total 1.

EXACT PLANNED ASSERTIONS = 12+240+20+90+16+1 = **379**, failure allowance = 0. Require contexts=4; endpoints=40; seals=10; mixed faces=10; pair count=45; triple count=8; collision-count comparisons=1. These are planned counts, not passed tests. Verify counts at runtime, and include a retained log/artifact documenting each count.

## Stage39 execution plan and immutable gates

A. **Contract-only (this step):** add this one independent research contract to docs/, no code/test/workflow/metadata transition. Its commit is not Stage39 Native PASS. Record source SHA, document blob SHA, single-path compare and HEAD readback.
B. **Executable preflight:** independently implement tests/Stage39.Tests.ps1 with the 379 assertion budget and exact oracle separation. Add one Windows PowerShell 5.1 CI job and retained Stage39 evidence artifact. Keep CURRENT_STAGE=LAST_COMPLETED_STAGE=38 and Stage38 exact seal. Before commit inspect branch HEAD, predecessor tests, workflow gates and metadata; use a bounded static preflight. Auto CI on the new SHA must be completed/success, with 379/379 and every predecessor job successful, canonical verify and Stage23 twice-idempotent finalizer. A successful Stage39 preflight is NOT an activated or sealed Stage39.
C. **Pending activation only after preflight acceptance:** with evidence, prepare exact Stage39 pending state (CURRENT_STAGE=39, LAST_COMPLETED_STAGE=38, STAGE39_RUNTIME_VERIFICATION=PENDING_NATIVE), update only required predecessor metadata guards, and require a separate completed/success exact-SHA Windows CI. No Stage39 status is promoted based on an earlier SHA.
D. **Evidence-only seal and exact-seal recheck:** after implementing-SHA completed Native success, seal Stage39 with documented artifacts, then verify another exact-seal SHA with all mandatory historical jobs and twice-idempotent Stage23 finalizer. Do not call a seal PASS while any job is queued/in_progress, and do not auto-merge.

No edits to src/, oracle/, CANONICAL_NAMES_LOCK.sha256, main, historical expected-red evidence, or public releases. The predecessor Stage38 acceptance is evidence-bound to dec610f55fb67dc6abf55bbc243e5c3dcaacdf73.
