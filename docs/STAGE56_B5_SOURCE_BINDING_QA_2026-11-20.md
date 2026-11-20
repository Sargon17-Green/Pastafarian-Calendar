# Stage56 B5 — independent source-byte binding gate (QA only, 2026-11-20)

PROJECT_ID: `PC-BRANCH-PHP-MALAY`  
Working branch: `PHP+Bahasa-Melayu`  
Predecessor: exact SHA `21a778d2f45c72571306f916f1abfb7dcdd99737`.

## Verified predecessor

Canonical Actions run [#44701207736](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44701207736): 30 of 30 jobs returned `completed/success`, including B5 Native #136169759120 on PHP 8.3.37 (64-bit). B5 Native log: three PHP lints succeeded, structural synthetic preflight `16/16`, negative CLI tests `12/12`, `stderr` empty; artifact ID `14614134156`, run-log ZIP SHA-256 `39e26102c55630f01a3618c81880eb54208e47884c445d32cd39e1514f3561d7`. The new artifact has **not** been independently downloaded or byte-audited in this round. This run does **not** contain genuine-year profiles.

## Newly implemented scope

`tests/stage56_b5_source_binding_audit.py` is an **optional, read-only** pre-profile audit. It accepts eight CLI values: export JSON path; externally pinned SHA-256 of export bytes; repository path; externally pinned exact source commit; provider relative path; externally pinned provider SHA-256; anchor relative path; externally pinned anchor-file SHA-256. Both source files must be regular committed Git blobs at the exact checked-out source HEAD. Provider path must resolve to a `.php` file under `src/`; symlinks, traversal and test fixtures are disallowed. The anchor must be a source-committed UTF-8 JSON object with exactly `{number:5000, open_gate_day:int}`. The audit verifies the provider and anchor file bytes via `git show <commit>:<path>`, compares them to **out-of-band** pins, rejects duplicated JSON keys, and verifies source claims, Year5000 anchor and corresponding year-5000 record identity. It neither calls the provider nor generates years.

Example, **only after finding and independently reviewing authentic source and canonical anchor**, from clean repository checkout at exact source commit:

```bash
python3 tests/stage56_b5_source_binding_audit.py --self-test
python3 tests/stage56_b5_source_binding_audit.py \
  ACTUAL_EXPORT.json PINNED_EXPORT_SHA256 . SOURCE_COMMIT \
  src/REVIEWED_PROVIDER.php PINNED_PROVIDER_SHA256 \
  canonical/REVIEWED_YEAR5000_ANCHOR.json PINNED_ANCHOR_SHA256
```

Success reports `status=BYTE_BINDING_ONLY canonical_review=REQUIRED actual_year_profiles=0`. Exit `1` means failed integrity/rejection; `2` means bad CLI syntax. A successful byte-binding is **not proof of canonical authorization, provenance, algorithmic correctness, year-generation fidelity, or Stage56 acceptance**. Caller pins may themselves be malicious unless reviewed independently. This audit does not alter the pre-existing B5 PHP profiling contract and makes no claims about real-year behavior. It deliberately imposes the stronger source-committed anchor-file convention: if the actual canonical anchor exists in a different artifact format or repository, review and adjust this *QA-only* adapter before it is used; do not manufacture a substitute anchor.

## Checks performed this round

Python self-test: `15/15 PASS` (`1` synthetic positive; `14` deliberate negative cases including forged claims, altered claimed source bytes, path traversal, invalid source/anchor pins, missing tracked anchor, conflicting anchor year, and duplicate JSON keys). Python compilation: PASS. No PHP 8.3 Native execution of the new Python tool, no genuine-year production export and no source-provenance attestation. The positive synthetic Git repository exists only inside an automatically removed temporary directory during self-test and is never a production fixture.

## Remaining authorized NEXT

Locate and independently review a genuine production `YearStructureProvider` and canonical Year5000 anchor, including normative origin. Pin actual source SHA and three source-derived year exports for 4999/5000/5001. Apply this binding gate only where its source-commit convention is met. Then run three independent PHP 8.3 64-bit profiles under **external** `timeout 900s` and `memory_limit=512M`, with the existing `stage56_actual_year_profile.php` and independently pinned JSON bytes. Evaluate measured runtime/memory and correctness before any optimization. Do not treat the synthetic self-test or B5 native preflight as Stage56 full acceptance; no PATCH22/PATCH23 integration, main/merge, or publication.