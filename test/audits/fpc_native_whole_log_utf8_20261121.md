# Object Pascal Stage 1: full-log UTF-8 boundary audit (2026-11-21)

## Evidence / independently reproduced before change

- Authorized branch: `Object-Pascal+Português`.
- Baseline commit: `12154d881a5f8547dec425497b8e6ac5dd5552c5` (not `main`).
- Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928207669
- Native job: 136918861215, completed success.
- Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928207637, job 136918860761, completed success at the same baseline SHA.
- Actual native ZIP artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928207669/artifacts/14716592756
- Artifact length: 4,085 bytes; independently measured ZIP SHA-256: `1253a5c6c1d0e2c49a64927304e9c6b8fd970256f6593d4bdb03a3535176fe94` (equal to GitHub metadata and uploader output); CRC passed.
- Extracted `stage01-native-fpc.log`: 29,898 bytes, SHA-256 `3c8e649d76d69690f26a0a954b7f7947fb8e5725082ae5c5e6d923d505e84446`.
- Independent verification: 30/30 suite EXIT=0; 22,977/22,977 checks passed, zero failures. Existing independent 12 dynamic Portuguese label oracle: all exact UTF-8 lines occur exactly once; zero Latin-1 duplicates.
- **Distinct gap:** strict decoding of the *whole log* fails at byte offset 9392 (zero-based), single offending `E9` byte in `Resumo aritm\xE9tica com sinal:`. Exactly one invalid UTF-8 byte was measured in the otherwise valid decoded log. The offending source is `test/bigint_signed_arithmetic_regression.pas`; this old fixed output line predates the label-specific gate.
- Synthetic positive control: replacing that one `E9` with its correct UTF-8 encoding `C3 A9` yields a fully strict-decodable log. This positive control is **not** a native result.

## Bounded corrective contract

Input: one raw unmodified native log from the exact current commit, not GitHub's decoded job-log page.

Output criteria, scoped to test harness / QA only:
1. Strict UTF-8 decode of all bytes succeeds; no replacement or lenient decoding.
2. Preserve prior oracle: 12 exact dynamic Portuguese lines each occur once as UTF-8 and do not occur as Latin-1.
3. All 30 existing suite process exits remain zero, total verified checks 22,977 and failures zero.
4. Check exact commit SHA, run/job, and actual ZIP SHA-256 plus ZIP CRC against upload metadata.

Implementation change is limited to explicit Unicode to UTF-8 conversion for the one fixed Portuguese summary and extending the existing Python byte oracle. No changes to production implementation, fixtures, calendar algorithms, or stage policy.

## Acceptance boundary

The bounded old-SHA native and Names Lock gates are already verified. This new, stronger whole-log gate requires a fresh native artifact for the newly committed SHA; **no new PASS is claimed by this audit**. Overall Stage 1 cannot be accepted without historical October 12/13 original source-patch provenance; earlier provenance search was exhausted and must not be repeated without new leads. No merge/main.