# Stage02 DISCOVERY01 — WasmKit Native evidence verification (2026-11-21)

**PROJECT_ID:** `PC-BRANCH-WAT-SPANISH`  
**Branch:** `WAT+Español`  
**Scope:** QA and CI evidence for the already-authorized Stage02 DISCOVERY01; no new phase, source change, merge, or release.

## Source and provenance locks

| Field | Verified value |
| --- | --- |
| QA workflow commit / GitHub event SHA | `d509e9b24a22bb4ab60b2f40cb9da1d699911502` |
| Immutable source checkout inside WasmKit job | `871f9b70216c16c57abcd552ec6fb0ed1010e305` |
| `tests/normative_selector.wat` SHA-256 | `18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980` |
| WasmKit release | `0.1.6` Linux x86_64-musl |
| Official release archive SHA-256 | `57085becd37769ed618a9057dee6d70303195e31d3b46d09dac1cfb5d477aa24` |
| WasmKit executable SHA-256 (manifest) | `5d96c83deba94ade402e26e35a466b6e74bc8c5888fb346b0f1c5e180aae65c9` |
| WABT version | `1.0.34` |
| Compiled `source.wasm` SHA-256 (artifact recalculated) | `b333825348af7f83137a9184dde8fb13a69885e5a81c8639ac834234dea6f251` |

## Completed GitHub Actions evidence

[Run 44923220858, attempt 1](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923220858) is **completed/success**, event `push`, head branch `WAT+Español`, event SHA `d509e9b24a22bb4ab60b2f40cb9da1d699911502`.

- Canonical names lock: [job 136903552858](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923220858/job/136903552858), completed/success, checkout exactly the event SHA.
- Node WebAssembly semantics: [job 136903553082](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923220858/job/136903553082), completed/success, checkout exactly the event SHA, **111/111 Native WAT cases and 83 independent BigInt oracles**; the job's JSON report has total=111, passed=111, failed=0, matching the locked WAT SHA.
- Independent WasmKit runtime: [job 136903553258](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923220858/job/136903553258), completed/success; checks out the immutable **source SHA** above (not the QA event SHA), confirms the WAT SHA, validates/compiles with WABT, verifies the release SHA before extraction, records version `0.1.6`, and runs a successful smoke test: exact `[WasmTypes.Value.i32(1)]`, exit 0.

## Downloaded artifact and independent review of contents

[Artifact 14714581950](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923220858/artifacts/14714581950), `wat-stage02-wasmkit-exact-871f9b7-44923220858-1`:
- ZIP size: **30,745 bytes**, locally recalculated SHA-256 **`51ba91e192a661947fa343125f82d7c1dd14709eef8c2863752e668d853b1bfa`**, equal to the upload job's reported digest.
- ZIP integrity: **no CRC errors**; **122 files**. Required files present: `manifest.tsv`, `exports.txt`, `cases.tsv`, `summary.txt`, `smoke.stdout`, `smoke.stderr`, `source.wasm`, `source-wasm.sha256`, and individual export logs.
- The manifest matches the exact PROJECT_ID, source commit, QA event SHA, run ID/attempt, WAT hash, WasmKit 0.1.6, runner OS Linux/arch X64, and smoke exit 0.
- Export inventory: **111 unique parameterless i32 exports**, including the **6 original Stage02 contract cases and 105 additional regressions**.
- `cases.tsv`: **111 rows, 111 PASS, 0 FAIL, 111 exit code 0**; export order exactly equals `exports.txt`.
- Independently read and checked **all 111 per-export logs**, not merely the run conclusion: **111/111 contain only `[WasmTypes.Value.i32(1)]` (after whitespace trimming), zero invalid output**.
- `summary.txt`: `EXPECTED=111`, `EXECUTED=111`, `PASSED=111`, `FAILED=0`, `COMPLETE=yes`.

## Gates and limits

**ACCEPTED for this exact source/QA pair:** Node WebAssembly 111/111, independent BigInt checks as recorded by CI, canonical names lock, and WasmKit 0.1.6 Native 111/111 with a verified artifact. This clears the previously unverified **WasmKit Native runtime** gate.

**NOT ACCEPTED:** the entire historical Stage02 delivery. The originally approved Stage02 ZIP/manifest have not been recovered/authenticated; do not assert equivalence, provenance, or global Stage02 completion. Neither a successful WasmKit export self-test returning i32(1) nor this QA report establishes that historical equivalence. Do not mix QA-event HEAD with immutable source SHA.

**Next authorized work:** review the remaining Stage02 contract/evidence gates specifically, locate/authenticate original ZIP/manifest if available via narrow evidence links, and conduct an independent bounded differential check for any uncovered contract assertion. No re-run of 44923220858 or the same tests at an unchanged source SHA without new justification. Remain `פתוחה / READY`.

This report records results already produced and independently inspected; it does not claim an additional native execution on a user machine.
