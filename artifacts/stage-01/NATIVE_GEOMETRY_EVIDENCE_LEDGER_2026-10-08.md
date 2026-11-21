# Stage 1 — Native geometry evidence ledger (QA branch, 2026-10-08)

## Кайсы далил текшерилген

Канондук repo: `Sargon17-Green/Pastafarian-Calendar`.
Булак: [Native Actions run 37835677064](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37835677064), HEAD `8002a5d959e1a4f0d0b586974ba0bdae22ad57f6`; **7/7 jobs PASS**.
Raw native trace artifact: GitHub Actions artifact ID `11575187608`, `befunge-kyrgyz-native-write-audit`.
Test-only PyFunge instrumentation: `qa/sitecustomize.py`.
Original Funge-space: `qa/interleaved_work_counts_pre_lexical_baseline.b98`.
Native-qualified QA production: `src/interleaved_work_counts.b98`.

Бул таблица **чыныгы Native PyFunge** `STEP` окуяларын гана эсептейт.
Лексикалык сканер токендерди толук окуп, баштапкы арифметикага
`(x=5, y=0, delta=(1,0))` чекитинде өткөндөн кийинки
2D trace алынган. Демек scanner'дин кошумча багыттары жана
opcode'дору бул таблицага кошулган жок.

| Native-after-handoff көрсөткүч | Valid `1 15055672 1 15055670` | Invalid `2 10 0 10` |
|---|---:|---:|
| Executed instruction steps | 25,982 | 11,902 |
| Executed distinct (x,y) cells | 9,532 | 9,408 |
| Cardinal-delta steps | 25,314 | 11,594 |
| Non-cardinal/dynamic-delta steps | 668 | 308 |
| Executed `x` dynamic-vector opcodes | 668 | 308 |
| Executed `p` writes | 128 | 56 |
| Executed `g` reads | 235 | 90 |
| Distinct coordinates visited under multiple distinct deltas | 1 | 1 |
| Native `_` and `|` conditionals | 0 | 0 |
| Native `[` `]` `r` `w` `k` `j` opcodes | 0 | 0 |
| Native `{` `}` `u` stack-stack opcodes | 0 | 0 |
| Executed min/max X | 5..1528 | 5..1530 |
| Executed min/max Y | 0..2014 | 0..1860 |

**Тастыкталган башка нерселер:** source blob `e2b39b066d1d47bcb8ce4f234b093fca94cb21d1` Native-PASS candidate менен так бирдей. Original blob `e06d8f75d6502b2771d6a76b00397c6b6dbee543` immutable baseline катары сакталган. Native post-handoff IP/delta/opcode/stack-depth жана `g`/`p` окуялары оригинал менен жаңы версияда 26,708 valid, 12,194 invalid окуя боюнча толук дал келди. Кайра аткарылган `p` gate writes valid=10, invalid=4; executable opcode өзгөргөн жана кийин аткарылган учурлар экөөндө тең үчтөн.

## Натыйжанын так чеги

Native 7/7 CI PASS — **функционалдык тесттердин** белгилүү чегинде чыныгы PASS.
Бирок эки trace бардык possible input боюнча геометриянын абсолюттук
кабыл алуусу эмес. Аткарылган source геометриясы эки өлчөмдүү
жана `x`, `p`, `g` динамикалык башкаруусу иш жүзүндө бар.
Ошентсе да ушул эки трассада кошумча advanced opcode'дор
(`_`, `|`, `w`, `r`, `k`, `j`, `[`, `]`, `{`, `}`, `u`)
**аткарылган эмес**. Бул бардык input үчүн жок экенин далилдебейт;
бирок алар үчүн acceptance далили ушул trace'терден алынбайт.

Милдеттүү кийинки иш: эки башка gate'ти өз-өзүнчө жабуу —
`FULL_FUNCTIONAL_QA_PASS` жана
`GEOMETRIC_SPAGHETTI_QA_PASS`. Геометриялык gate үчүн
так source map, маршруттун багыттуу graph'ы,
текшериле турган кесилиш/цикл, динамикалык execution-cell
version lifecycle, anti-dead-code көзөмөлү жана
көп варианттуу input coverage талап кылынат.
Мурдагыдай эле `SEMANTIC_STATE_OWNER_VALIDATED=NO_FINAL_AUDIT`;
16 explicit-reset реplay PASS жалпы бүт өзөктөр үчүн бардык
state-owner эрежелеринин далили эмес.

Жаңыланган Native structural corpus'тар
`qa/stage1_native_structural_corpus.py` жана
`qa/stage1_native_structural_properties.py` боюнча акыркы
GitHub CI дагы өзүнчө текшерилүүгө тийиш.

**Stage 1 OPEN, LAST_COMPLETED_STAGE=0, Stage 2 NOT STARTED.**
PR #17 QA only, canonical branch өзгөртүлгөн эмес.


## 2026-10-08 — Ten native day-input geometry proofs (QA-only)

**Native evidence**: run
[37840062911](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37840062911),
job \`native-diverse-production-geometry\`, 10/10 native oracle/trace/
versioned Funge-space checks PASS. The **entire workflow** may still be in
progress; only this job's PASS is asserted here.

\`qa/stage1_native_diverse_geometry.py\` runs eight valid and two invalid
signed-day pairs in **native PyFunge-98** (not a Python calendar engine).
Eight valid expected outputs are assembled from independent native
\`reference/work_counts.b98\` and two \`reference/save.b98\` executions.
Invalid numeric input must produce seven \`-1\` outputs. Each sample's
native \`STEP\`, \`READ_BEFORE/AFTER\`, \`WRITE_BEFORE/AFTER\` evidence is retained.
\`qa/stage1_native_diverse_geometry_audit.py\` verifies the source-cell
version lifecycle and saves each actual directed route graph.

| Native signed-day input case | Real post-handoff IP steps | Executed, changed code gates |
|---|---:|---:|
| equal zero | 7,374 | 2 |
| crosses Foundation | 25,982 | 3 |
| forward adjacent | 9,700 | 3 |
| reverse adjacent | 9,700 | 3 |
| small mixed sign | 9,700 | 3 |
| positive → negative | 28,308 | 3 |
| negative → positive | 28,308 | 3 |
| values around 2^127 | 98,088 | 3 |
| noncanonical minus-zero sign | 7,250 | 2 |
| sign outside 0/1 | 11,902 | 3 |

**Input-dependent geometry**: 7 native route fingerprints.
The union of native **arithmetic-only** edges (lexical scanner excluded)
exhibits 2 distinct fork nodes, 1 distinct join node, and **zero nodes
that are both fork and join**. A per-case directed merge-and-fork count
of zero also holds for all 10 cases. The 14 watched advanced opcodes
\`(\`, \`)\`, \`[\`, \`]\`, \`_\`, \`j\`, \`k\`, \`r\`, \`t\`,
\`u\`, \`w\`, \`{\`, \`|\`, \`}\` were each executed **zero
times** across all ten traces.

This is a **concrete acceptance gap**, not a false Native regression:
native results and runtime mutable-space integrity are PASS within the
sampled families; the stronger, intentionally difficult, nontrivial 2D
spaghetti architecture still lacks some required types of route/data
entanglement and executed control operators. In particular, adding inert
operators or unused routes would not satisfy the contract.

**Next implementation work in Stage 1:**

1. Design a real arithmetic-influencing input-dependent branch with
   nontrivial dynamic rejoin/reentry in production Befunge-98, not a
   test-only or decorative route.
2. Exercise it with actual Funge directional/stack-stack instructions
   under explicit IP, stack and mutable-cell ownership invariants.
3. Keep the native independent-reference oracle, exact output contract,
   negative lexical controls, versioned source map and anti-dead-code
   route analysis mandatory.
4. Run **all** Native regression and diverse geometry jobs at exact
   post-change SHA, then separately adjudicate \`FULL_FUNCTIONAL_QA_PASS\`
   and \`GEOMETRIC_SPAGHETTI_QA_PASS\`.

This does not permit reimplementation or fallback in Python. The
Befunge calendar algorithm and canonical branch remain untouched.
\`CURRENT_STAGE=1\`, \`LAST_COMPLETED_STAGE=0\`.
