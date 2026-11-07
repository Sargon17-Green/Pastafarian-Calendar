# QA31AM — exact-source finite counter-address algebra acceptance (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Original source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Accepted code SHA: ac0b814b4080d7403dade82aafd73064ad8689c1
Production source unchanged. QA-only review [skip ci], no main/merge/Stage2.

## Completed exact-code-SHA CI evidence

Final run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42350179391
Status completed/success on SHA ac0b814b4080d7403dade82aafd73064ad8689c1.
Job 128336440708 completed/success: original source SHA, Python syntax,
forward affine source interpreter, separate polynomial-monomial source oracle,
all contract acceptance assertions and artifact upload succeeded.

Prior first attempt:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42350109695
Completed/failure because synthetic hostile mutation #3 used "^p", exactly
matching the original first ray; the purported mutation was a NO-OP.
This is a harness fault, NOT an original program defect. The sole correction
replaced the test mutant with "^pp". Do not count first run as PASS.

Exact run artifact:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42350179391/artifacts/13565366073
CI ZIP SHA256:
34c81db90cb222c00b1ef0b2a8909cd2a5bd81d7e3fb95fe050cdc15a111f975
ZIP 2674 bytes, four members forward.json, forward.log, inverse.json,
inverse.log. Download independently inspected: SHA256 exact, ZIP CRC 4/4,
32 ray records, 22 affine impossibility proofs, eight affine-feasible rays,
two nonlinear-feasible rays, 20 source-conditional stack address witnesses,
15/15 independent corrupted-report rejections and zero Native runs.
Permanent independent evidence mirror in ChatGPT Library:
 /Befunge_QA_Artifacts/QA31AM_BEFUNGE98_KYRGYZ_COUNTER_ADDRESS_EVIDENCE_20261107.zip

## Bounded source facts

The prior QA31AL found 11 sites with a constant source-ray y != 49,
32 source-ray sites with y depending on incoming stack, and one site
(369,575) without a *pure* arrow-to-put corridor.

For all 32 original source-ray y expressions, the forward interpreter
modelled eight arbitrary incoming stack integer values with symbolic affine
arithmetic. A separate polynomial oracle reconstructed the exact original
source rays and checked their integer polynomials independently.

Twenty-two affine rays have y=c+sum(a_i*u_i) with
gcd(abs(a_i)) NOT dividing (49-c), so their specified unchanged-source
straight ray CANNOT write to y=49 under arbitrary integer incoming stack.
Eight other affine rays permit y=49; two nonlinear rays additionally have
source-checked integer solutions. For each of these TEN ray sites, the
CI artifact contains two *hypothetical* explicit stack witnesses that
write to (1,49) or (3,49) if the exact source ray is entered with that stack.
That is 20 checked conditional address witnesses, NOT a natural-input or
runtime IP reachability witness.

The exceptional source sequence from (385,575) westward:
  <p71a*6+a*9+a*2+p
contains first p(384,575), then p(369,575). In the unchanged-source
straight sequence the *second* p has fixed target (7,1692), proven by
source-level simulation with two different first-put stacks that do not
overwrite the traversed corridor. The *first* p can write elsewhere and
might overwrite source code. Alternative vector ingress is not ruled out.

Thus 11 prior fixed-y exclusions + 22 new modular exclusions + one
compound second-put local exclusion = 34 *conditional local path*
counter exclusions, and 10 conditional counter-address constructible
paths. ALL 44 globally physical outer-p targets remain UNKNOWN without
proving their incoming IP paths, stacks, and self-modification history.
This arithmetic result is NOT global exclusion, is NOT a signed Native
run, and is NOT Stage1 functional/geometric/global PASS.

Raw original source cells near (10,20),(10,23),(10,29),(10,32)
were boundedly inspected in north/south/west directions through 12
source cells each. They document possible raw-source vector corridors,
but not natural-input physical reachability.

## NEXT: QA31AN

Use the ten stack-constructible outer p ray sites and the exceptional
compound site as *conditional sinks*. Investigate bounded backwards
source predecessor/stack-production evidence, comparing original signed
Native traces when available to determine whether any natural input can
realize one of the 20 specific hypothetical q/m target stack states.
Include possible self-modification and noncanonical IP entries.
Independent source/oracle verification and hostile checks remain mandatory.
If no natural-input candidate is produced, retain UNKNOWN; do not run
another Native experiment or invent expected-red. For a future genuine
candidate, cap original Native to <=25000 STEP per case, preserve logs.
No Stage2/main/merge. Stage1 global/functional/geometric OPEN.
