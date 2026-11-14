# Pastafarian converter whole-year soak — readiness work

**Protected branch:** The `main` branch of `Sargon17-Green/Pastafarian-Calendar` MUST NEVER be changed by this project. This is a dedicated QA branch; do not merge it into `main`.

**Authoritative task contract:** [SOAK MASTER issue #27](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/27) (2026-11-14).

## Scope

The final acceptance is **not** a sample differential test. For each configured, pinned calculation day `c`, run each original converter from its frozen GitHub commit and build it separately. For every one of 10,000 selected canonical years, enumerate every target day `t` in that full year while keeping `c` fixed, then compare complete years one converter at a time. Stop scheduling at the first mismatch, preserve first-day evidence, and investigate it before continuing.

* The two ordered inputs are `F(c,t)`. In the normative engine-day coordinate, foundation is `-15055671`. JDN conversion is `JDN = engine_day + 1721425`.
* A completed **comparison** means all five canonical fields matched for every day in the entire year. A completed calculation by one engine alone does not increase the comparison counter.
* Different original-language name strings must be retained, with verified canonical name-to-index tables. Different translations are not themselves errors; unsupported mappings BLOCK certification.
* 58 reference rows + 20 production/candidate rows + 10 language triage rows are **overlapping catalogues**, not 88 distinct engines. Each existing engine and each wrapper must be accounted for explicitly.
* Two active logical workers: `normal` and `slow`, at most two converter processes. Slow jobs must NEVER be killed/restarted merely for taking longer; when possible, transfer logical lane ownership while retaining the original process. Prevent a third process when slow lane is occupied.
* Dynamic classification based on comparable historical durations; no blind fixed wall-time kill for heavy computations. Use resource priority/affinity, safe disk spool, checkpointing and recovery.
* Display `verified_comparisons_completed` continuously. Also maintain `contiguous_verified_years` to prevent out-of-order slow work from being mistaken for certified contiguous coverage.
* On first mismatch or malformed evidence, stop dispatch, preserve original source output, normalized output, comparison JSON, hashes, full input pair and compilation provenance. Never claim PASS on a partial year, build-only CI run or engine wrapper.
* Preserve all work in one Windows location: `%USERPROFILE%\Pastafarian-Converter-Soak`. No global installs, long-running watchers, reboot, or modification of unrelated projects. Use the existing Drive single-Python bridge and Gmail receipts once preflight is verified.

## Gates

1. Independent year-boundary proof for each calculation day, 10,000 years, no missing years.
2. Per-engine SHA locks (original source + toolchain + binary), exact two-input adapter and raw output.
3. Canonical name resolver and five-field transport for every engine, including boundaries/negative dates.
4. Local Windows preflight (CPU/RAM/disk, toolchains, Drive execution + Gmail return). Harden runtime/cleanup per `WINDOWS-EXEC-PACK/3.0`.
5. Deterministic two-lane scheduler, first-difference halt and durable evidence / resume.
6. Real native two-engine, **full-year** pilot.
7. Only then activate the 10,000-year soak, and publish verified results outside `main`.

**Status as of 2026-11-14:** readiness design, not complete engine adapter implementation, not a full soak, no 10,000-year certification. A short Codesh arithmetic CI PASS does not certify Codesh's full-date output; the earlier 45-minute full-date CI run was cancelled.

## Artifacts and current implementation

The initial offline prototype contains:
- Strict streaming year validator and first-difference evidence contract.
- Deterministic two-lane no-kill scheduling state machine.
- Native source-candidate registry seed with all 88 overlapping catalog records, disabled until qualified.
- One-file Windows preflight for Drive bridge, with no converter execution, no installation and one evidence ZIP.
- Unit tests for year completeness, mismatch halt, process caps and no-kill classification.

**This prototype is being validated outside the repository before production activation.** Its tests on Linux do not count as verified native Windows operation. This README and the JSON schema below do not authorize starting the heavy soak or modifying `main`.
