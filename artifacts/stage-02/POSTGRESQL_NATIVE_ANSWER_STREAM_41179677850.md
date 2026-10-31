# SQL+தமிழ் Stage 2 Slice 9 — PostgreSQL Native answer-stream evidence

## Provenance
- Branch: `SQL+தமிழ்`.
- Source/workflow commit: [`6f10dc43171db6ab0989a15b661de47a29a1a3cd`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/6f10dc43171db6ab0989a15b661de47a29a1a3cd); branch HEAD verified on 2026-10-31 before evidence write.
- [GitHub Actions run 41179677850](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41179677850): completed/success; job `answer-slice9` ID `124474326091` completed/success.
- Runtime: PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2), confirmed in the extracted `versions.txt`.
- [Artifact 13034088958](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41179677850/artifacts/13034088958), `sql-tamil-slice9-answer`; downloaded and opened ZIP with exactly four files: `native.txt`, `isolation.txt`, `differential.txt`, `versions.txt`.
- Local SHA-256 of downloaded ZIP: `5afaa86ec2875cb28dd0862c3b562970ef09a6a6e776156c3af3b88ae8459498`, equal to GitHub artifact digest.

## Verified gates from completed logs

| Gate | Count observed in ZIP | Final SQL assertion |
| --- | ---: | ---: |
| Native answer-stream | 44/44 | `native_44_of_44 = 1` |
| Production-only isolation | 4/4 | `isolation_4_of_4 = 1` |
| Differential with separate reference database | 28/28 | `differential_28_of_28 = 1` |
| **Total** | **76/76** | All three gates passed |

The job starts PostgreSQL in a network-isolated container, loads production code and Native tests, separately checks that production does not depend on the reference schema, then creates `sql_tamil_answer_differential` and loads the normative reference for differential verification. The source SHA recorded inside `versions.txt` matches the workflow head SHA.

## Scope
Source: [`sql/11_stage02_answer_stream.sql`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/6f10dc43171db6ab0989a15b661de47a29a1a3cd/sql/11_stage02_answer_stream.sql).
The new production functions are `next_bowl_in_drop46_order`, `ask_bowl`, and `answer_at`. Earlier independent exact-arithmetic checks cross-validated 21 golden numbers, but those checks are not counted as PostgreSQL Native results. A previous pre-fix workflow run (41179635371) failed due to YAML formatting; the corrected run above is the one supporting this acceptance.

**Acceptance:** Slice 9 Native, isolation, differential PASS only. No Stage 2 aggregate PASS, no `calendar_date_spaghetti` PASS, no full-calendar PASS, no main merge.

## NEXT
Continue the documented Stage 2 sequence with the production `choose_rank_short` and `choose_rank_wide` semantics. Derive a measurable contract from the existing normative reference, implement algorithmically independent production SQL, and add bounded Native, production-isolation, and differential gates. Do not rerun Slice 9 on unchanged SHA.
