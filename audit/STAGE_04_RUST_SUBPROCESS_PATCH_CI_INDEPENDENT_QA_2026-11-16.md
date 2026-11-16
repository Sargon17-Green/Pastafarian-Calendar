# Rust+Azərbaycan-dili — Stage04 subprocess error patch: completed CI and independent artifact QA (2026-11-16)

## Immutable scope
- PROJECT_ID: `PC-BRANCH-RUST-AZERBAIJANI`
- Branch: `Rust+Azərbaycan-dili`
- Exact **code** commit SHA: `7dcf4a8af35fc6d5d619cf656c386cc68469396d`, a four-file change (CLI handling, two added tests, CI count gate, regression contract).
- Before the code patch, audit-only Names Lock run [43939523031](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43939523031) completed/success on parent `2892696ff749504d552d7169b33283ac21d4a8a3`.
- Code Stage04 workflow [43960377710](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960377710): `completed/success`, attempt 1, exact code SHA, native job `133625858235` completed/success.
- Code Names Lock [43960377763](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960377763): `completed/success`, attempt 1, exact code SHA, verify job `133625858249` completed/success; checkout log showed exact SHA.
- No manual workflow dispatch was made.

## Code-level failure and correction
The historical callability CLI formerly caught only `ProvenanceError` and `RuntimeUnverified` in `main`. Direct `subprocess.TimeoutExpired` and `OSError` from its underlying provenance Git commands escaped without a machine-readable JSON gate outcome. A bounded source-equivalent local try/except reproduction confirmed both exception classes escaped (2/2). The patch maps these failures to `RUNTIME_UNVERIFIED`, exit code 3, `source_pin_eligible=false`, both callable fields false, `observed_runtime_red=false`, `stage04_closure=NOT_CLAIMED`. Two newly added injected-error CLI regressions are part of the 15 test callability gate. This fix does NOT demonstrate historical Rust runtime RED.

## Completed exact-SHA CI
Fetched completed job steps and decoded job log:
- Callability controls: **15/15**, including both new OS-error regressions; no skipped/failed.
- Rust source provenance controls: **13/13**.
- TSV protocol controls: **6/6**.
- Rust Native tests: **34 passed**, zero failed/ignored across nine result lines, including two zero-test targets.
- Differential: **15 cases**; archived Python legacy `RED=8`, `CONTROL=7`, `UNEXPECTED=0`; patched and candidate both 15/15.
- Completion signals preserve `STAGE04_CLOSURE=NOT_CLAIMED` and historical Rust `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`.

## Independent downloaded artifact verification
- Artifact: [14273069889](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960377710/artifacts/14273069889), `rust-az-stage04-discovery02-baseline`.
- Downloaded ZIP length: **20,297 bytes**.
- Independently calculated SHA-256: `026b12dcee746efb289620e1ca1e3a84e321b8492f591eb7b9ef187662c89e7d`; matches the GitHub artifact digest exactly.
- **17 entries**, unique flat safe names, all ZIP CRCs passed, bounded file sizes.
- Independent local Python QA: **245/245 assertions PASS**, process exit 0; source verifier SHA-256 `31bc53b916268dfe8b4c57441dc0633d472a9fe09f8cd53b6c21737a6d457162`.
- Checks included exact project and code identity, Native exit 0, test counts and two new test names, nine Rust result lines, all 15 TSV indexes and columns, day/offset alignment, oracle and candidate cross-source equality, pass flags, independent recount 8 RED/7 CONTROL from `legacy != oracle`, non-closure and historical witness flags.
- **Limit:** ZIP integrity and cross-evidence consistency are independently checked; not an independent re-execution of the underlying mathematical calendar oracle or an authentic historical Rust production runtime. The eight legacy RED cases are archived **Python**, not historical Rust RED.

## Gate decision and NEXT
**Stage04 OPEN / NOT_CLAIMED. CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3.**

The earlier and newly patched code CI are green and the new audit artifact has passed independent consistency QA. Closure still requires a genuinely **new, independently authenticated pre-Stage04 callable Rust production day-tag route** and observed Rust runtime RED against an independent oracle. Do not infer Rust RED from old Python, rescan exhausted history, open Stage05, or merge/main. This is an audit-only report; no production or stage policy change.
