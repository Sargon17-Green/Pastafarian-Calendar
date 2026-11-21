# Rust+Azərbaycan-dili Stage04 — exact-SHA count correction CI and independent artifact QA

- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Authored: 2026-11-21
- Tested branch: `Rust+Azərbaycan-dili`
- Exact tested code/test SHA: `da1365bb6a2d369a2c97c40f86cd11013aeac0d8`
- Parent code/test SHA: `3e8981bef3399351be9f105f7aadad04b1753030`
- Stage: `CURRENT_STAGE=4`, `LAST_COMPLETED_STAGE=3`, `Stage04 OPEN/NOT_CLAIMED`.

## Verified GitHub execution (no dispatch/re-run)

Branch-to-tested-SHA comparison at inspection: `identical`, ahead=0, behind=0.

1. Stage04 CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876488347 ; job `136762205022`, `completed/success`. Decoded job logs confirm checkout of exact SHA above. All 10 normal steps, including provenance, callability, TSV, bounded Rust native and Python–Rust differential, succeeded.
2. Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876488361 ; job `136762205014`, `completed/success`. Decoded logs confirm the same exact checkout and canonical names verification success.

## Independently downloaded artifact

- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876488347/artifacts/14695419099
- Name: `rust-az-stage04-discovery02-baseline`; **20,515 bytes**.
- SHA-256 of downloaded ZIP: `bd7d0cf0de1f2a6d42cb17c045fcbe43df2eddb3c6a88365daa7aa8c30bcc067`; equals GitHub artifact digest.
- **17/17** ZIP entries decompressed and CRC validated; no corrupt members.
- `sha.txt` equals project ID and exact tested SHA; `exit.txt=0`.
- `stage04_callability_result.txt`: **19_PASS**, correcting previously stale `16_PASS` wording.
- Independently parsed test transcripts: callability **19/19**, provenance **16/16**, four-column TSV protocol **6/6** (`OK` for each).
- `stdout.txt`: Rust Native groups `[0,0,16,3,4,2,3,3,3]`; **34/34**, zero failures; runner `rustc 1.100.0`.
- Independently parsed the 15 indexed TSV records and 15 JSON cases. With foundation `F=-15055671`, compute arbitrary-precision `delta=day-F`; independent oracle: `tag=-2*delta` when `delta<0`, otherwise `tag=2*delta+1`. All **15/15** TSV oracle+candidate and **15/15** JSON oracle+patched+candidate values match; 8 archived Python `RED` and 7 `CONTROL` classifications independently verified.
- This arithmetic recomputation used no imported archived function and no Rust production code. Archived Python `RED` labels are **not** historical Rust runtime RED.

## Explicit gate distinction

- Stage04 CI on **exact tested SHA**: PASS.
- Canonical Names Lock on **exact tested SHA**: PASS.
- Synthetic source/callability and provenance qualification: PASS in the bounded checks above.
- Native Rust regression and direct differential: PASS as scoped above.
- Historical pre-Stage04 production Rust direct callable day-tag and observed historical Rust numeric RED: **NOT_PROVEN**. The pinned production `src/lib.rs` function is `BootstrapOnly` and does not establish the required witness.
- **Stage04 remains OPEN/NOT_CLAIMED**; no Stage05, merge, protected/main changes or historical Rust RED acceptance is inferred.

This is a permanent **audit-only report** of already completed runs. Adding it does not alter tested Rust source, tests or CI workflow, and any automatically triggered workflow on this report-only HEAD must be evaluated separately, without duplicate dispatch.
