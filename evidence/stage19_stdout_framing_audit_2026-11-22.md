# Stage19 original-FALSE stdout framing audit — 2026-11-22

PROJECT_ID: PC-BRANCH-FALSE-ARABIC  
Authorized branch: `FALSE+العربية`  
Last accepted stage: **Stage18 BOUNDED**  
Stage19: **NOT_ACCEPTED** (CI follow-up pending).

## Completed post-production-fix Native run

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997190903 — completed/failure.
- Run/source SHA: `56b3647a5ad5821bbd1adc964398a63d94a99a75`.
- Native job: `137130662630` — completed/failure; canonical-name verify job `137130662494` — success, **not** Native acceptance.
- Original interpreter lock: `eb3135565a8670cced3f6bbca4dbf7b014c45634`; compile and Unicode preflight passed.
- Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997190903/artifacts/14744622195
- Downloaded ZIP SHA-256 `328c97a2df1376ab4e7fbff951a82d37c5da74293eb6bee7217ef5a110b81b91`, 48 entries, `ZipFile.testzip() == None` (all CRC checks passed).

## Independent byte-level review of archived stdout

The Native receipt reported first chunk `exit_code=0`, empty stderr, 716 recognized case labels/720, 120 order markers/120, and `passed=false`. No `_FAIL` marker appeared. This is a genuine **gate failure**, not an accepted Native test.

Direct inspection of `stage19_native/positive_0.stdout.txt` (17,661 characters) found five newline-only runs, at offsets/lengths: `0/204`, `4300/205`, `8601/205`, `12902/205`, `17203/22`. Four inserted runs interrupt labels `STAGE19_CASE_0175_OK`, `0351`, `0527`, `0702`. This explains why the original regex found 716 rather than 720.

Removing **only** carriage returns and line feeds produced 16,820 characters, **byte-for-byte equal** to the expected ordered concatenation of:
- all 720 sequential `STAGE19_CASE_XXXX_OK` labels;
- 120 interleaved `STAGE19_ORDER_XXX_OK` labels, one per six case labels;
- final `STAGE19_CHUNK_000_OK` exactly once.

The 12-probe stdout also normalized to its full expected marker stream (257 characters), with no extraneous text. Both deliberately wrong expected-value mutations exited 1 with the required sentinel, and invalid table headers 5 and 7 exited 1 with `E_BOWL_POSITION_LENGTH`, as recorded by the completed Native receipt. No separate acceptance is inferred from these partial passes.

Six independently constructed adversarial variants of the first chunk's normalized stdout were all rejected by exact-stream comparison: missing case label, wrong case label, duplicated label, extra text, wrong order label, and missing final marker.

## Scoped correction and repeat gate

- QA-only patch: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/cab8ae7e2be3735e431a5547eb2ac149f02df438
- File changed: `tools/stage19_bowl_position_ci.py` only. No production FALSE operation was changed.
- Normalize only CR/LF in marker parsing, preserve raw stdout and stderr in the artifact, require **exact equality** to the full interleaved marker stream for each positive chunk and the complete 12-probe stream; mutant sentinel checks normalize only CR/LF while preserving raw evidence.
- Confirmed GitHub file blob after patch: `300b4501190a8eb47af589585f8ecd10862e5e30`; checked live HEAD after the patch was the exact patch commit.
- Auto-push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065591190 — observed `queued`, conclusion null, on exact patch SHA at initial read. It is neither Native PASS nor a blocker; **do not dispatch a duplicate**.

## Next acceptance gates

Wait for the new run to be `completed`, inspect actual job logs and artifact before any conclusion. Require six positive chunks totaling 4,320 cases, 12 probes, two intentional mutants, two invalid-header controls, original interpreter and exact source locks. Download and independently check the resulting artifact SHA-256, every ZIP CRC, raw parsed input/output and oracle agreement. Neither the earlier partial run nor the current stdout-framing repair can accept Stage19 by itself.

No merge/main, no Stage20, no claim of physical bad-pointer safety.
