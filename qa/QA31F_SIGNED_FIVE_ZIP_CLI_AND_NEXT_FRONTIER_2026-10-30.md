# QA31F — exact committed auditor against five signed historical ZIPs (2026-10-30)

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`. **Stage 1 only, offline evidence review.** This is neither a fresh Native run nor a Stage 1/Stage 2 acceptance.

## Exact source, artifacts, and method

- Verified branch: `qa-befunge98-stage1-order-isolation-20261008`, checked at HEAD `ec82fae46560ff1f3275e4f9bf8b03da0a4ffd12` before this report.
- Existing auditor: [`stage1_qa31f_qa30b_live_put_lineage.py`](stage1_qa31f_qa30b_live_put_lineage.py), Git blob SHA `619a687411ce38f70a2624616c19c3eef5226f26`. The exact file bytes used for this CLI were checked using `git hash-object` against that blob.
- Original immutable production `src/interleaved_work_counts.b98` blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`; it was not changed.
- QA20 signed originals: [run 39761821210](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210). Shard artifact IDs and independently verified ZIP SHA-256:
  - shard0 `12417714729`: `0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076`
  - shard1 `12418676466`: `0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea`
  - shard2 `12418536785`: `d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c`
  - shard3 `12417633980`: `d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07`
- QA30B original artifact `12725439728`, [run 40488476653](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40488476653): SHA-256 `dd84fea04224066bb60849c3d250df7f3059c630bea9bdf768300a5b7bcb0997`.
- All five ZIP archives were downloaded again for this **first full post-guard exact-committed five-input CLI**; all SHA-256 values matched and `ZipFile.testzip()` returned `None`. The auditor also checked the two pinned QA30B inner JSON hashes, the production blob, signed gzip STEP hashes and counts, actual physical `p` events and chronology, and original signed `g/j` successor.

Reproduction, with ZIP names in the order above:
```sh
python qa/stage1_qa31f_qa30b_live_put_lineage.py \
  shard0.zip shard1.zip shard2.zip shard3.zip qa30b.zip
```

### Actual locally executed CLI result: PASS

```json
{
  "schema": "qa31f-qa30b-pinned-real-put-lineage-v1",
  "source_blob": "560d6aa5807a7f766213a33835cce85eab0fa40c",
  "observed_original_native_cases": 2,
  "observed_original_native_steps": 18859,
  "recorded_original_put_events": 73,
  "historical_independent_negative_controls": 41,
  "new_native_executions": 0,
  "finite_lineage": {
    "invalid00": {
      "steps": 17187,
      "recorded_put_events": 68,
      "g_57_29_tick": 9437,
      "j_89_29_tick": 9462,
      "physical_writes_to_3_49": [
        [242, [202,2], 32,0], [1082,[248,14],0,1],
        [2504,[344,26],1,0], [3344,[248,14],0,1],
        [4766,[344,26],1,0], [5606,[248,14],0,1],
        [7028,[344,26],1,0], [7868,[248,14],0,1],
        [9290,[344,26],1,0]
      ],
      "last_recorded_value_before_g": 0
    },
    "invalid18": {
      "steps": 1672,
      "recorded_put_events": 5,
      "g_57_29_tick": 1285,
      "j_89_29_tick": 1310,
      "physical_writes_to_3_49": [
        [242,[202,2],32,0]
      ],
      "last_recorded_value_before_g": 0
    }
  },
  "naturally_reached_m1_at_j_proven": false,
  "global_unreachability_proven": false,
  "stage1_complete": false
}
```

The complete console JSON (expanded whitespace) had SHA-256 `60922526fe758d09d12378418caa7a10a70a81f1441032abb8df746c70b00415` and 2084 bytes. The historical 41 negative controls were checked **as a signed prior audit claim**; they were not re-executed in this session.

## Exact-head CI completed, not falsely treated as this CLI's CI acceptance

- [Native Regression run 41039922773](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41039922773) at `ec82fae46560ff1f3275e4f9bf8b03da0a4ffd12`: `completed/success`.
- [Canonical Names Lock run 41039931172](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41039931172) at the same SHA: `completed/success`.
- These existing workflows are successful, **but do not themselves establish that the new five-ZIP QA31F CLI was exercised in GitHub CI**. This report records an exact-code, locally executed five-ZIP PASS with historical original Native data.

## Finite frontier for a different original source coordinate

Next selected unresolved original opcode: `x(286,5)`, distinct from `>(10,32)` and `x(211,29)`. [QA27's signed frontier](QA27_ORIGINAL_NATIVE_DIRECTED_SOURCE_FRONTIER.md) identifies original `x(286,5)`, minimum Manhattan distance 3 from genuine `(286,8)` in QA20 valid03. The original source blob was fetched and confirms `x` at 0-based column 286 of row 5.

A fresh **read-only scan of the four SHA-verified QA20 ZIPs** checked compressed STEP digests, per-case STEP totals and strictly sequential ticks for all **48 actual original Native cases**. Findings: `(286,8)` was reached **768 times across 45/48 cases**, always with incoming direction `(1,0)` after `(285,8)`; `(286,5)` itself was visited **0 times**. This is *QA20-only* finite evidence; QA27 separately covers the larger 136-case original corpus. Being vertically three cells away does not establish an actual instruction-pointer transfer or executable original-byte ownership.

**NEXT:** analyze the immutable input-to-control predecessors and actual signed IP transitions to `x(286,5)`, using already signed QA20/QA27 evidence only. Formulate a valid natural-input candidate for an original-source Native run *only if* predecessor and memory/offset provenance support it. Do not force an IP, edit immutable program bytes, restart prior PASS runs, or open Stage 2.

Stage 1 remains OPEN: `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. No main/canonical branch update or PR merge.
