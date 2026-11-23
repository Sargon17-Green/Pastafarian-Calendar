# DISCOVERY24 — Shared-group billing cross-check (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Authorized branch: \`Clojure+Nederlands\`
Scope: **TEST/QA ONLY**; unchanged production/API and search/cell budgets; no new CI or Native execution, no five-field differential or Stage2 acceptance.

## Source-locked preflight

- Branch HEAD before work \`ac39c1118b00360ea63919e5b79f918f470d3af5\`, not treated as a stale historical SHA.
- Production \`src/pastafari/maandrang.clj\` Git blob \`62f304dc013a9a9f70475bb0d34f186838b27318\`, read from the live branch and matched the prior accepted source identity.
- Literal source semantics: \`prefix-gedeelde-raming\` computes \`resterende-dagen = dec(sum(restvector))\` and returns \`1+(m-opened)*(1+resterende-dagen) = 1+(m-opened)*R\`. \`prefix-volgende-keuze\` bills this once for all legal active candidates; on skipping all active blocks, it bills the new month separately after incrementing \`opened\`.
- Completed historic CI run \`45065505365\`, exact \`ec0051ec6335fe178c03bcf3583b3dbfec1ffa84\`: verify job \`137340625261\` completed SUCCESS; isolated canonical DP job \`137340625561\` completed SUCCESS **with \`DP_FEASIBILITY_UNPROVEN\`**, and full Clojure Native job \`137340626593\` was SKIPPED. Job success is not a DP proof or Stage2 acceptance.
- Historical artifact \`14770898411\`, 12,468-byte ZIP with SHA-256 \`eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5\`, downloaded and digest-verified before unzipping.
- Previous independent suffix QA script \`discovery24_exact_insertion_qa.py\` Git blob \`a36fc46d80db5b4b14d979dc028bb654c9999364\`, prior report \`DISCOVERY24_EXACT_INSERTION_SUFFIX_PROOF_2026-11-23.md\` Git blob \`481a09a4289696df6317cf5d3a4c0fc108459dcd\`.

## New artifacts and executed checks

1. \`qa/clojure-dutch/discovery24_shared_group_bruteforce_qa.py\`: an independently implemented exhaustive **whole-word enumeration oracle**, no import of the production counter or the earlier QA counter. Git blob \`bc0eb6d0a60335e87bc92f5c37322d358b6c5307\`, local SHA-256 \`e4b35f0dc9d493e30d6e0766ad7097f40e571d5303b1bbab7cf3f374ee12e720\`, 4,174 bytes. Branch-only script commit \`e36ed29493fc039297f2dbc7c3e94e15a028f35e\`, \`[skip ci]\`, exact GitHub blob and contents readback.
2. \`qa/clojure-dutch/discovery24_shared_billing_canonical_crosscheck.py\`: a separately implemented exact combinatorial counter with normalized gap convolution, independently redoing the canonical lexicographic path and cost schedule. Git blob \`ddbf1c56c9a04964aa36131e486cb476d4a79ed5\`, local SHA-256 \`74bed3c4fbc61e5e0aa0716a13768724141aaf99b25448cfdd4c435390b7c572\`, 11,075 bytes. Branch-only commit \`f0fa3a86c344b6f25c4f6f5dc6d4147509c6af68\`, \`[skip ci]\`, exact GitHub contents and blob readback.
3. \`python -m py_compile\` on both scripts: **exit 0**. \`python qa/clojure-dutch/discovery24_shared_group_bruteforce_qa.py\`: **exit 0**. Twelve tiny profiles, 71 fully enumerated legal words, 494 rank-prefix cases, 422 exact-cost-minus-one refusal checks, 578 first-open transitions, 495 last-close transitions, 7 simultaneous first-open/last-close synthetic one-day cases, 1,412 charged active groups, 578 charged new groups, and 598 skipped candidate blocks. Single-day synthetic profiles test the abstract grammar and **are outside the production API profile minimum of four days per month**.
4. \`python qa/clojure-dutch/discovery24_shared_billing_canonical_crosscheck.py --artifact-zip <verified-14770898411.zip>\`: **exit 0**. Eight separate exhaustive small profiles: 67 full legal words, 480 prefix ranks and 413 cost-minus-one refusal checks. Canonical artifact: 33 months, 3,569 days, 5,288-digit rank, independent total equal to the frozen source-locked 5,288-digit count.
5. Independent canonical fingerprint: **81 positions** prior to refusal, comma-separated prefix SHA-256 \`2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a\`. At position 82, \`opened=31\`, \`closed=0\`, \`R=3488\`, hence **ACTIVE** charge \`1+(33-31)*3488=6977\`. Already billed \`4995675\`; required \`5002652>5000000\`. Rank candidate blocks tested \`1173\`, skipped \`1093\`; active group bills \`80\`, new group bills \`30\`. Both canonical targets p82 and p520 share this exact refusal before position 82.
6. SHA guard negative test: modified artifact ZIP rejected with **exit 1**, \`AssertionError: artifact digest mismatch\`. The negative sample is not a replacement for the canonical ZIP; canonical artifact is retained.

The brute oracle and the gap-convolution code are distinct implementations; the large canonical combinatorial counter and the earlier script use the same mathematical insertion identity. Thus this is independent implementation and exhaustive small-word verification, **not** an independent proof from a completely unrelated counting theorem. No Clojure executable was invoked in this round. The fingerprint is a Python model result, **not** observed Native behavior.

## Gates

| Gate | Result |
|---|---|
| Source/branch/artifact integrity | VERIFIED |
| Small-profile independent brute model and boundary checks | PASS — MODEL ONLY |
| Exact canonical rank prefix and shared bill to first refusal | PASS — MODEL ONLY |
| Production code/API/128N search/5000000N cell budget | UNCHANGED |
| New CI/Native on new SHAs | NOT_RUN |
| Real Clojure canonical p82/p520 refusal observation | NOT_RUN |
| Five-field differential | NOT_RUN |
| Stage2 DISCOVERY24 | OPEN |

## NEXT — QA only

Implement a **literal source-formula drift guard** tied to exact production blob and relevant \`prefix-gedeelde-raming\`, \`prefix-legale-kandidaten\`, \`prefix-volgende-keuze\` branch semantics. Test mutations of group charging, candidate legality and early/refusal boundaries; fail closed if the source changes and re-evaluate the model before any new Native experiment. Keep the existing canonical 81-symbol fingerprint and 4,995,675→5,002,652 witness frozen. No same-SHA duplicate CI, no production/API/128N/5000000N/main/merge/publication change. No pending-execution cleanup: no new user-machine run results arrived.
