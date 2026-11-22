# Stage56 B5 — opt-in source-coordinate boundary (not stage acceptance)

Date: 2026-11-23 Asia/Jerusalem
PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Input HEAD: ceb8a3dd6363407b578b7c9a7f0fd59d35af8c06
Independent source: Sargon17-Green/pastafari-calendar@cc2cf0b422757a5e7c33218ce30cffa8f99c6786

## Verified completed result before change
Actions #45068985923: completed/failure; exact source branch SHA above; 29 success / 1 failed job (external-reference-differential #137351453600). Source SHA is unchanged.
Artifact #14772417703 has 37/37 ZIP member CRC valid, 32505 bytes, SHA256
7b4928a01e6608010bdd96b021e9f90953952b600604e90a2509f5b100b5dd3f
matching Actions artifact metadata and upload log. PHP sauce probe exit=0, stderr empty.
Raw sauce comparison MISMATCH for 4999, 5000, 5001, but the diagnostic
source-coordinate-translated comparison PASS for ALL three. Exact fields compared:
six bowls, drop46 order, first response, step, and next bowl. This is a narrow
parity witness for the tested inputs, NOT a universal proof or Stage56 acceptance.
The existing raw mismatch remains a failing CI gate; real-year profiles are
intentionally skipped.

## Input/output contract
New *opt-in* \`src/Patches/CanonicalJdnBoundary56.php\`:
- Inputs: explicit pinned external commit string + int source calculation/target JDNs.
- Only accepted commit: cc2cf0b422757a5e7c33218ce30cffa8f99c6786.
- Coordinate mapping: PHP = external + (-1721425); inverse exact when in range.
- Underflow/overflow and source mismatch reject before kernel execution.
- \`sauceOrder\` and \`askBowl\` delegate to the existing BootstrapKernel AFTER
  mapping both dates. Bowl IDs and seal keep their existing meaning.
- Does NOT alter the kernel, legacy day tags, or raw PHP-native entrypoints.
- Source SHA comparison here only gates the selected contract; it is NOT byte
  provenance. Exact checkout cleanliness, blob hashes and external semantics
  remain separate prerequisites in the established CI.

## QA and gate distinction
The existing fast QA probe uses the new opt-in bridge only for its translated
record set. The raw record set still calls the unchanged BootstrapKernel.
The independent Python comparator still exits 1 for raw mismatch even if
translated records pass. New native test verifies: three artifact-pinned
regression witnesses; calculation/target distance invariant; two-sided JDN
roundtrips; arithmetic boundary guards; explicit source mismatch rejection;
unchanged PHP foundation and day-count behavior.

Pre-commit local PHP 8.4 arithmetic smoke is NOT PHP8.3 CI/Native.
After commit, require exact-new-SHA completed CI, job steps/log, zip CRC/digest
and the new native test result. Do NOT label any queued run PASS; do NOT
dispatch duplicate CI or accept Stage56 solely from adapter evidence.

## NEXT
If the boundary tests pass: define and prove the source-bound sauce parity gate
without hiding the raw legacy mismatch. Only then resume PHP production
year 4999/5000/5001 month profile and the count/rank/unrank performance
constraints (900 seconds and 512 MiB per year). Investigate any remaining
month weaving mismatch independently. No main, merge, or publication.

Links:
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068985923
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068985923/job/137351453600
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45068985923/artifacts/14772417703
