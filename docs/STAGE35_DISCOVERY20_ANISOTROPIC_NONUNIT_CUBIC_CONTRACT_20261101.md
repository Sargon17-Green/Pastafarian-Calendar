# Stage35 / Discovery20 — anisotropic nonunit cubic contrast (contract-first, not executed)

Project: PC-BRANCH-POWERSHELL-TAGALOG
Branch: `PowerShell+Tagalog`
Status: CONTRACT ONLY; `CURRENT_STAGE=34`, `LAST_COMPLETED_STAGE=34` remain unchanged. Stage35 is **not** opened as implementation, and 896 below is a planned, not executed, assertion count.

## Gate and independent research question

Stage34 exact-seal run [41246559244](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41246559244) completed/success on `682dcb21a164ebfd924a48a565f6e90ac63dd314`: 8/8 successful jobs, Stage34 448/448, Stage33 560/560, Stage32 239/239, Stage31 835/835, predecessor 664/664, verify and Stage23 finalizer idempotency passed.

Stage34 used unit calculation and target offsets. Stage35 asks a **new, falsifiable question**: how does the seal-dependent third mixed difference change when a *two-day displacement* applies to the calculation axis rather than to the target axis? This is not an assertion of a bug, probability law, uniformity, or specific numerical values.

Let `M=2^127-1`, `f=Get-NormFoundationDay()`, and for each seal `s in {1,2}` let `F(c,t,s)`, `S(c,t,s)` be independently obtained first and signed step of bowl 1.

For base `d`, define two displacement vectors: `A=(a,b)=(2,1)` and `B=(a,b)=(1,2)`. For each vector and `i,j in {0,1}`, query `(c=f+a*i, t=d+b*j, s)`. Define:
- `D_s(a,b;d) = [F(f+a,d+b,s) - F(f+a,d,s) - F(f,d+b,s) + F(f,d,s)] mod M` (canonical nonnegative residue).
- `Q_s(a,b;d) = (S(f,d,s) != S(f,d+b,s)) XOR (S(f+a,d,s) != S(f+a,d+b,s))`.
- `E(a,b;d) = [D_2(a,b;d)-D_1(a,b;d)] mod M`, `R(a,b;d)=Q_1 XOR Q_2`.
- **Scale-anisotropy contrasts** `G(d)=[E(2,1;d)-E(1,2;d)] mod M`, `H(d)=R(2,1;d) XOR R(1,2;d)`.

Never substitute an observed Stage34 result as an oracle. For every query independently compute `Invoke-NormSauce(c,t)` followed by `Get-NormAnswerStream(..., QueriedBowlId=1, Seal=s)`; compare actual `Invoke-CalendarDateSpaghetti` + `Get-Discovery13AnswerStreamFromContext` to this oracle at endpoint First/Step, four seal edges, two faces, E/R, then G/H. No cross-branch fixtures or implementation copied from another language.

## Exactly bounded domain

Eight **labeled** target bases: `OpenGateDay-1`, `OpenGateDay`, `CloseGateDay-1`, `CloseGateDay`, `f-1`, `f`, `f+1`, `f+36525`; open/close from `Get-NormYear5000 -CalculationDay f`. Offset 36525 is ordinal, not a Gregorian conversion. Two displacement vectors per base, four corners, two seals, so:
- 8 bases, 2 vectors, **16 cubes**; 64 labeled context instances, 128 seal-specific endpoints, 64 seal edges, 32 faces, 8 paired G/H contrasts.
- Labeled numeric pairs can overlap; report actual distinct numeric pairs separately, and never assert they must equal 64.
- On each labeled context, assert 58 legacy writes and exactly one Patch12 invocation. Materialize contexts independently per seal (or prove immutability before any reuse); do not make assertions about unexamined input days, bowls or seals.

## Measurable implementation contract

Add `tests/Stage35.Tests.ps1` with Windows PowerShell 5.1, `Set-StrictMode -Version Latest`, the existing native independent oracle, exactly one new 20-minute bounded canonical CI job, exact `git rev-parse HEAD == GITHUB_SHA` gate, transcript, metadata and retained artifact. Before the test is runnable, extend Stage31–34 and predecessor metadata gates to accept **only** the precise Stage35 pending pair `CURRENT_STAGE=35; LAST_COMPLETED_STAGE=34; STAGE35_RUNTIME_VERIFICATION=PENDING_NATIVE`, preserving every historical expected-red and sealed-stage assertion. Never weaken previous gates by accepting arbitrary future stages.

**Exactly 896 planned assertions**, derived without invoking Native:
- 4 stage-metadata + 4 normative-year preflight = 8.
- Per cube: 4 contexts × 2 legacy invariants = 8; 8 endpoints × 4 First/Step/domain assertions = 32; 4 seal edges × 2 comparisons = 8; 2 faces × 2 comparisons = 4; E and R = 2. **54 assertions/cube × 16 = 864**.
- 8 bases × 2 comparisons for G and H = 16.
- Eight aggregate conservation checks (bases, vectors, cubes, labeled contexts, endpoints, seal edges, faces, G/H pair count) = 8.
- Total `8 + 864 + 16 + 8 = 896`, required failures `0`. Assertions must be counted by the runtime test harness, never by static code-site enumeration.

Print `STAGE35_ASSERTIONS_PASSED`, `STAGE35_ASSERTIONS_FAILED`, `STAGE35_CUBES`, `STAGE35_SCALE_PAIRS`, counts of G zero/nonzero and H flip/same, and bounded per-base records. Observations cannot become hypothesized expected outputs. Gate requires Stage34 exact seal and all historical regressions; the separate Stage35 Windows job must be completed on its **own** implementing SHA with a successful log before `LAST_COMPLETED_STAGE=35` or a Stage35 PASS claim. Then produce an evidence-only seal and separately recheck that exact SHA.

## Scope restrictions

No src/oracle/production edits, global statistical inference, Gregorian mapping, main merge, protected branch changes, publication or forced ref update. A queued/in_progress CI is neither an acceptance nor a blocker; continue independent permitted work rather than re-dispatching the same run.
