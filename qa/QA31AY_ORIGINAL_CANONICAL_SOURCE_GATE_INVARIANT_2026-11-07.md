# QA31AY — bounded canonical parser invariant from the original source (2026-11-07)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ. QA branch: qa-befunge98-stage1-order-isolation-20261008. Incoming verified HEAD: 57932bdf2e7ba3fbd2dd290964c6672ec3ad305a.

Original immutable Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c. Prior signed QA31AI archive SHA256: 9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49. QA31AI original 200 receipts were accepted in earlier QA but are NOT re-downloaded or re-executed by this test.

## Checked conditional source routes

The standalone source-only auditor runs original Funge-98 RPN g/p/j/x source ray logic and compares eight real input/counter j gates independently against their mathematical predicates: y8 ASCII digit byte48..57; y17 delimiter bytes9/10/13/32; y11/y23/y32 q>3; y20/y29 61*m; y38 q==4. Gate checks: 24,576 (8 rows × 6 q × 2 m × 256 byte values). Fourteen exact x-vector ingress cases, 112 actual original-source digit/delimiter/EOF p-ray tests, one negative-q (-9) alias control, and 16 distinct non-no-op hostile gate-source mutations. The SHA1 of the *complete* source file is rechecked using exact Git blob object semantics.

For canonical stdin dispatch with original unchanged rays and ordinary empty-stack ingress:
- digit → y8→y11; q<=3 reaches y14, updating n=10*n+(b-48), m=1 and returning to the input loop; q>3 instead reaches y44 rejection.
- delimiter → y8→y17→y20; m=0 returns to the input loop; m=1 enters y23; q<=3 reaches y26, stores n to (10+q,49), updates q=q+1,n=0,m=0, returns to the input loop; q>3 reaches y44 rejection.
- EOF reflection → y29; m=0 enters y38, whereas m=1 enters y32; when q<=3 the latter reaches y35 and increments q only AFTER the row32 gate; q>3 would reject.

The 16-input-read bounded state-class exploration starting at (q,m)=(0,0) reaches exactly nine canonical boundary states: (0,0),(0,1),(1,0),(1,1),(2,0),(2,1),(3,0),(3,1),(4,0). In this *conditional* model row32 is only entered with m=1 and q in 0..3. The q=-9 staging-address alias deliberately breaks an overly broad q'=q+1 formula and is asserted as a negative test.

## Reproduction and evidence boundary

Execute from a checked-out exact QA branch: node qa/stage1_qa31ay_canonical_gate_audit.mjs. A 5-minute bounded source-only GitHub Actions job is provided in .github/workflows/befunge-qa31ay-source-gates.yml. Do not declare its CI PASS until the exact-sha run is completed with success and logs checked.

The previous signed original 200-case corpus (3,628,390 STEPs) was NOT rerun here. There is no new original Native execution, no full-corpus CI, and no new authentic natural stdin witnessing q>3,m=1 at row32. These QA31AY tests prove only the original-source *canonical parser route under their premises*. Dynamic self-modification, other IP ingress with nonempty stack, source writes outside the finite signed corpus, and global functional/geometric acceptance remain UNKNOWN/OPEN.

NEXT QA31AZ: inspect original-source noncanonical ingress into y14/y32 and the upstream gate regions, and possible dynamically written source targets; enumerate source-pinned x/p/j entries with separate independent check and existing signed receipt comparison. Do not invent input witnesses or claim unreachability from the finite canonical invariant. Only consider new Native for a separately verified concrete raw stdin with <=25000 STEPs. No main/merge/production edits/Stage2.