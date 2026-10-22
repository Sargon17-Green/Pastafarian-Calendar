# QA24 planning checkpoint — 15 not-yet-naturally-reached original source glyphs

**Planning only, no new Native coverage claim and no dead-code finding.** The accepted QA18 original Native source-glyph role receipt is `qa18_glyph_roles.json`, SHA-256 `263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7`, from run `39423789058`. The accepted QA20 full 48-input aggregate is `qa20_native_48_aggregate.json`, SHA-256 `75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117`, from run `39761821210`. The native original source Git blob is `560d6aa5807a7f766213a33835cce85eab0fa40c`.

These **15 source byte cells**, and only these 15, were not naturally executed in the frozen 48-case QA20 corpus (source glyph followed by the minimum observed Manhattan/L1 distance):

| Cell | Source opcode | Min observed L1 distance |
| --- | --- | ---: |
| (10,32) | `>` | 3 |
| (10,35) | `>` | 3 |
| (57,32) | `g` | 3 |
| (57,35) | `g` | 3 |
| (127,35) | `g` | 3 |
| (152,35) | `p` | 3 |
| (211,29) | `x` | 3 |
| (235,23) | `x` | 3 |
| (286,5) | `x` | 3 |
| (113,32) | `j` | 4 |
| (199,35) | `g` | 4 |
| (174,32) | `x` | 6 |
| (235,32) | `x` | 6 |
| (248,35) | `p` | 9 |
| (309,35) | `x` | 9 |

**Distance is not causality.** Minimum L1=3, for example, means that at least one sampled ordinary Native route passed within three grid cells of the source coordinate. It neither means that the route can be steered there using legal input nor that the original byte would still be present upon an eventual visit (an earlier `p` may overwrite it). Similarly, a STEP at the coordinate while in stringmode does not establish opcode execution.

## Next native gate design (not yet started)

1. Freeze the original 21 QA18 locations and the six accepted QA20 natural hits. Generate a **new disjoint deterministic input corpus**, including valid signed zero/neighbor/magnitude patterns and malformed lexical variants not present in QA20. Do not move IPs, mutate Funge-space, choose inputs based on post-hoc successes, or change production source.
2. Run actual original PyFunge 0.5-rc2 Native programs on every selected input. For all valid entries, require independent native Befunge reference output parity; for every invalid entry, require seven `-1` rejection fields. Never skip a difficult valid case: raise a justified per-case Native budget or record an explicit unresolved/RED result rather than silently dropping it.
3. Capture original source-byte fetched at each Native STEP, current stringmode, position and delta, plus physical `g/p` events where source-byte ownership matters. Preserve complete source-anchored compressed route files or equivalent independently replayable original receipts, not just derived booleans.
4. Require a separate fail-closed receipt auditor for all selected inputs, SHA-pinned predecessor artifacts, exact 21 cells, step counts, natural hits and controls against synthetic missing/duplicated, relocated, overwritten or fabricated source-opcode encounters.
5. Certify only *finite natural reachability* of any newly observed cell and scoped execution results; retain each still-unseen source cell as **unresolved**, never dead. This is not the full geometric or state-ownership acceptance criterion.

**Other active work:** QA23B original Native run `39838384673` must finish and have its downloadable original artifact audited independently; do not prematurely sign QA23B. Stage 1 remains open: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No Stage 2, canonical source, main or PR #17 merge.
