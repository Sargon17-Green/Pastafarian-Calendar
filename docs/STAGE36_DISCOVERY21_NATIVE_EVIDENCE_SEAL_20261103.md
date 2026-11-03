# Stage36 / Discovery21 — exact-SHA Native evidence seal

Project: `PC-BRANCH-POWERSHELL-TAGALOG`; existing branch: `PowerShell+Tagalog`.

## Verified implementing SHA
- Commit `9cdd1d0c1f51df0fb6fac260e7352066d932192a`; [Actions run 41536470914](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536470914) completed/success on exact SHA and branch: **10/10 jobs**.
- Stage36 Windows PowerShell 5.1 job 125589454971: **1004/1004**, zero failures; 16 cubes, 64 labeled and 64 distinct numeric contexts, 128 independent endpoints, 64 seal edges, 32 faces; E nonzero in 16/16 with 16 distinct E; R flips 7/16. [Stage36 artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536470914/artifacts/13185111211).
- Stage35 job 125589454889: **896/896**, zero failures and Stage35 seal recheck PASS. [Artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536470914/artifacts/13184952446).
- Predecessor regression and research jobs succeeded on exact SHA. Retained baseline is 2746/2746 (664+309+441+85+239+560+448). **Overall suite: 4646/4646** (2746+896+1004). Canonical Names Lock job 125589454851 succeeded.
- Native Windows job 125589455232: Stage23 finalizer invoked twice, both exit 0, both ALREADY_FINALIZED=True, both stderr lengths 0; metadata SHA256 before, after first, and after second unchanged: `8638E773DAD2FA8FF882EEEF2338AFA3955686979653F0AAE4D5A69D1867966D`. RESULT=PASS. [Finalizer artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536470914/artifacts/13183538499).
- Prior automatic runs 41506414037 and 41523287631 were *failed*, not PASS, because Stage23 metadata gates rejected Stage36 pending state. The exact-SHA repair is now verified.

## Bounded interpretation and new-seal gate
The study is an independent normative-oracle comparison over the contract's finite calculation/target gate pairs. It does not prove global uniformity, statistical independence, a Gregorian mapping, or behavior outside this domain. Historical expected-red and predecessor seals are retained.

This evidence-only commit sets `CURRENT_STAGE=36`, `LAST_COMPLETED_STAGE=36`, and `STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED`; adjusts bounded test/CI metadata compatibility and adds no production-source/oracle change. No main merge or publication.

**The new seal SHA must pass its own automatic CI** with all 10 jobs, Stage36 1004/1004, Stage35 896/896, predecessors 2746/2746, `STAGE36_SEAL_RECHECK=PASS`, canonical verify, and two identical finalizer hashes. Until then `STAGE36_SEAL_COMMIT_NATIVE_RECHECK=PENDING`; do not open Stage37 or duplicate dispatch.
