# Stage37 / Discovery22 — pending native verification

Project: `PC-BRANCH-POWERSHELL-TAGALOG`; branch: `PowerShell+Tagalog`.
This activation is **PENDING_NATIVE**, not a Stage37 acceptance or seal.

The exact predecessor [CI run 41712776177](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712776177)
completed/success **11/11** on `8b1406b93be046cdd5f55aa94b3e3c9f8d857fad`.
Stage37 preflight job 126184865891: **516/516**, zero failed,
4 cubes, 16 distinct numeric contexts, 48 independent endpoints,
seals 1, 5, 10, queried bowl 1, K nonzero 16/16, P true 10/16.
[Retained preflight artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712776177/artifacts/13268701837).
Stage36 recheck 1004/1004; Stage35 896/896; predecessor jobs and canonical verify green.
Stage23 finalizer twice preserved metadata SHA256
`BE46F878D5B35BA8BED423F19CD6E5624DEB044C6514DDC04937576B148475C3`.

The next SHA activates exactly `CURRENT_STAGE=37`,
`LAST_COMPLETED_STAGE=36`, `STAGE37_RUNTIME_VERIFICATION=PENDING_NATIVE`,
retains prior seals, and extends precise predecessor metadata gates. It does
not alter source code, oracle, or main. Its 516-check algorithm is unchanged
except for metadata and result label; old preflight PASS is not transferred.

Acceptance: the **new SHA** must complete all 11 jobs successfully,
Stage37 516/516, Stage36 1004/1004, Stage35 896/896, all prior tests,
canonical verify, and two idempotent Stage23 finalizer runs with identical
SHA256, using Windows PowerShell 5.1. Retain and inspect
`powershell-tagalog-stage37-nonunit-seal-native` artifact.
Then, only after those logs, make a separate evidence-only Stage37 seal
commit and check its own exact-SHA CI. No main/merge/publish.
