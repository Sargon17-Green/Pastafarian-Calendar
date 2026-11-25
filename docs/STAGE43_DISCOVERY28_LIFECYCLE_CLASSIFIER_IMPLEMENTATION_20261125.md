# Stage43 lifecycle classifier and predecessor integration

Date: 2026-11-25  
Branch: \`PowerShell+Tagalog\`  
Scope: executable Stage43 lifecycle integration, compatibility gates, and fail-closed regression coverage.

## Status and non-goals

This change integrates the Stage43 lifecycle classifier into the existing branch workflow. It does **not** edit \`DEVELOPMENT_STAGE.md\`, activate Stage43, claim a Stage43 Native acceptance, create a Stage43 seal, modify production sources or the independent oracle, merge to \`main\`, or change branch policy.

The current live metadata remains the frozen Stage42 research state. The immutable Stage42 fixture remains Git blob \`a3f53b67e4445bdc835179cd484fe27b3e2648f7\`, exactly 728 keys.

## Exact metadata model

\`src/StageMetadataState.ps1\` uses the existing strict byte parser and \`FrozenStage42MetadataComparator.ps1\`. It compares every predecessor key/value against the immutable Stage42 blob. Only the three lifecycle pointers may differ for Stage43:

- \`CURRENT_STAGE=43\`
- \`CURRENT_DISCOVERY=28\`
- \`LAST_COMPLETED_STAGE=42\` or \`43\`, according to phase

All other 728 predecessor entries remain byte-parsed and value-identical. The classifier rejects unknown Stage43 keys, unapproved extra keys, missing predecessor keys, altered predecessor values, duplicate metadata keys, invalid UTF-8, and invalid phase transitions.

The Stage43 whitelist contains exactly 68 keys in four append-only groups:

| Group | Keys | Purpose |
|---|---:|---|
| Core lifecycle | 17 | Discovery plan and phase discriminators |
| Completed preflight | 16 | Exact-SHA research/compatibility evidence |
| Native implementation | 22 | A distinct implementing-SHA Native run |
| Seal recheck | 13 | A distinct seal-SHA full CI recheck |

The classifier accepts only these profiles:

1. \`RESEARCH_ONLY\`: the exact frozen Stage42 728-key state; no Stage43 lifecycle keys.
2. \`PENDING_SHAPE_ONLY\`: complete Stage43 core plus complete preflight evidence; \`LAST_COMPLETED_STAGE=42\`; no Native or seal fields; activation and Native acceptance remain pending/unclaimed.
3. \`IMPLEMENTING_SHA_SHAPE_ONLY\`: complete preflight and Native field sets; \`LAST_COMPLETED_STAGE=43\`; seal evidence absent; seal recheck remains \`PENDING_NEW_SHA\`.
4. \`SEALED_SHAPE_ONLY\`: complete preflight, Native, and seal field sets; all three CI phases have distinct run IDs and SHAs; seal recheck is marked \`PASS\`.

No phase may skip another. A missing preflight ledger and a partial preflight ledger are distinguished; partial Native and seal ledgers are rejected. The Native run must differ from the preflight run/SHA; the seal recheck must differ from both earlier runs/SHAs. These are **shape checks**, not proof that an external run or artifact exists. CI adjudication still requires independent inspection of the exact run, jobs, logs, SHA, artifact IDs, and artifact digests.

## Preflight provenance recorded by the schema

The current completed research preflight is GitHub Actions run \`45671193548\`, attempt 1, exact SHA \`781f63850cef28f000d696d3b77878b5cf282804\`, with 17/17 jobs successful. The completed evidence includes:

- Stage43 bounded oracle: 2,215 passed, 0 failed; 240 endpoints, 160 target pairs, 216 seal pairs, 23 structural guards.
- Stage42 sealed recheck: \`SEALED_RECHECK_PASS\`, 1,657 assertions.
- Stage41 seal recheck: \`PASS\`, 481 assertions.
- Stage40 seal recheck: \`PASS\`, 425 assertions.
- Stage30: 96 assertions.
- Canonical verify: \`SUCCESS\`.
- Stage23 finalizer idempotency: \`PASS\`; two invocations exit 0, stderr length 0, unchanged metadata SHA-256 \`0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF\`.
- Stage43 artifact 15050865689; downloaded ZIP SHA-256 matched the upload log: \`1cdb1f2783c132131f30e809413f08bbf03c08baf9d8e4abbf25162f24b25f00\`.
- Stage23 finalizer artifact 15049662294.

These are research/predecessor evidence only. They do not constitute Stage43 activation, Native acceptance, or seal acceptance.

## Regression integration

- \`tests/StageMetadataState.Tests.ps1\` exercises 38 positive/negative classifier cases, including the forbidden \`STAGE43_ACTIVATION_CI_RUN\` alias, incomplete phase sets, pointer errors, changed Stage42 provenance, malformed UTF-8, duplicate keys, and repeated phase SHA/run IDs.
- \`tests/StrictUtf8StageMetadata.Tests.ps1\` now tests live metadata separately from the immutable Stage42 blob. It verifies the pinned blob remains exactly 728 keys and contains no Stage43 keys.
- \`tests/Stage01.Tests.ps1\` runs the new classifier suite.
- Stage23–30 tests invoke the classifier and explicitly admit Stage43 as a successor where the existing metadata predicates require it.
- Stage35–42 tests and workflow gates admit Stage43 only when the classifier returns a valid Stage43 profile. Their predecessor assertions remain active.
- The Stage43 job is profile-aware: it distinguishes research-only, pending Native, implementing-SHA, and sealed-state regression outputs. It validates the metadata, transcript, and source evidence files; a missing file or artifact fails the job.
- All jobs invoking the pinned Stage42 blob reader use full-history checkout so the historical Git object remains available after the live metadata file eventually advances.
- The Stage23 finalizer is read-only for all Stage43 profiles. The idempotency runner checks both exit codes and zero stderr, while preserving the metadata hash.
- No Stage43 lifecycle evidence is written to the live metadata by these tests.

## Acceptance boundaries

A successful run of the new workflow will establish code/compatibility regression results for its exact commit SHA. It will not itself activate Stage43 or write Native/seal evidence into \`DEVELOPMENT_STAGE.md\`. Any later metadata transition must use a separate evidence-only commit, the exact phase-specific CI run, and a new-SHA recheck. The frozen Stage42 fixture must remain unchanged throughout.
