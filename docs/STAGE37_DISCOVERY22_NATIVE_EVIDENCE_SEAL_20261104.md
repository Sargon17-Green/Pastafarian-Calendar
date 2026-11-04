# Stage37 / Discovery22 — exact-SHA bounded Native evidence seal

Project: `PC-BRANCH-POWERSHELL-TAGALOG`; existing branch: `PowerShell+Tagalog`.

## Verified implementing commit (not the new seal commit)

- Commit `ac3299d536adffc83dea07e2ec8b5c24db45dea5` passed [GitHub Actions run 41776632142](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41776632142) **11/11** completed/success, including canonical verify.
- Stage37 native PowerShell 5.1 job **126398401196** passed **516/516**, zero failures, with a distinct on-branch normative oracle; four year-5000 gate cubes, 16 unique contexts, 48 fresh endpoints, seals 1,5,10 (bowl ID 1). K nonzero 16/16, parity P true 10/16. [Stage37 artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41776632142/artifacts/13297935441).
- Prior research/regression assertions from the same exact run: Stage36 1004, Stage35 896, Stage34 448, Stage33 560, Stage32 239, Stage31 309+441+85, earlier stages 664. Total **5162** together with Stage37; all observed assertions passed.
- Stage23 Windows finalizer job **126398401388**: twice exit 0, stderr 0, already finalized=True and metadata SHA256 unchanged: `18FAD461E1882764945B5B0A621C4BF265DCD931F3C8A73ADEBD50A4118C06FF`. [Finalizer evidence](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41776632142/artifacts/13297033491).
- Superseded activation run 41776072697 had six failed parser jobs; these are **not accepted evidence**. Corrected implementation run above is accepted.

## Exact-seal recheck requirement

This evidence-only commit sets `CURRENT_STAGE=LAST_COMPLETED_STAGE=37`,
`STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED` and extends
precise predecessor gates for the stage37 sealed pair. No `src/`, `oracle/`,
`main`, canonical lock, protected branch or merge modification.

The **new seal commit SHA requires its own 11/11 completed/success run**,
Stage37 516/516 and `STAGE37_SEAL_RECHECK=PASS`, prior stage seals,
canonical verify, twice-idempotent Stage23 finalizer with stable SHA256.
Until then `STAGE37_SEAL_COMMIT_NATIVE_RECHECK=PENDING`; do not claim
that the seal is accepted solely by the implementing-SHA pass.
Bounded evidence does not establish statistical uniformity, civil date
mapping, or performance outside the contract's finite inputs.
