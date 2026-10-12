# टप्पा 20 पूर्ण — Stage 21 PATCH 10 साठी HANDOFF

## प्रमाणित अवस्था

- Repository `Sargon17-Green/Pastafarian-Calendar`, **फक्त `TypeScript+मराठी` branch**; `main` किंवा इतर language branches बदलू नका.
- Total stages 55; **LAST_COMPLETED_STAGE=20**, current stage **20 DISCOVERY 10**. Next **21 PATCH 10**, one reply = exactly one stage. Stage 22 आणि पुढील काम आगाऊ नको.
- Tested Stage20 source commit: `57deea966018d29384ea2ad954e100f7d66a0fb5`.
- [GitHub Actions 38214265315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214265315): `verify` व `stage20-typescript-marathi` दोन्ही **SUCCESS**. `npm run typecheck`, Stages 1–20 entire npm tests, ten archived independently expected-red scripts, canonical names lock all PASS.
- Source language Marathi, implementation pure TypeScript. Frozen `SourceLanguageCatalog`, `CANONICAL_NAMES_LOCK.sha256`, no foreign implementation or oracle imports into production. `calendarDateSpaghetti` Stage54 पूर्वी intentionally throws `MonsterStageError`.

## DISCOVERY 10 मधील जुना दोष

`src/discovery10LegacyInPlaceStir.ts`:
- `LegacyInPlaceBowlStirAdapter.stirInPlace(c,t,i,d,stone,order,pour,workingBowls)` हा **मूळ in-place दोष असलेला कार्यरत helper**; position 1..6 साठी `workingBowls[bowlId-1]` ताबडतोब overwrite करतो.
- `Discovery10InPlaceStirHandler` Stage19 `patch09Pours` ची correctly aliased पहिली तीन pours घेतो, उरलेल्या शून्य; input bowls ची फक्त ownership-copy working array तयार करतो, पण **त्या आत सर्व reads/writes मूळ mutable working array वरच होतात**. Input snapshot arithmetic साठी वापरत नाही.
- प्रत्येक step मध्ये previous/next read values, previousAlreadyWritten/nextAlreadyWritten, immediate output, real bowl IDs आणि क्रम यांचे frozen observations. 6 old writes; 5 contaminated positions; 6 overwritten-neighbor read slots per drop. Per-call context metrics/branchTrace आणि invalid input failure safeguards.
- Stage19 व Stage18 historical sources, 10 expected-red historical tests बदललेले नाहीत.

`test/discovery10Reference.ts`: test-only `normativeSingleStir(i,d,b,stone)` मध्ये सर्व सहा outputs **एकाच सुरुवातीच्या** bowl values वरून गणना होतात; त्याचा production source मध्ये import नाही. Normative complete 46-drop oracle `test/normativeOracle.ts:applyVisibleDropsToBowls`.

## GitHub CI पुरावे

```text
STAGE_20_DISCOVERY_10_GUARDS_PASS witnesses=8 positions=48 mismatches=40 matches=8 overwrittenReads=48 contaminatedPositions=40
STAGE_20_DISCOVERY_10_PROPERTIES_PASS orders=720 rankCells=4320 rankMismatches=3600 rankMatches=720 cases=2304 cells=13824 mismatches=11520 matches=2304 overwritten=13824 realPairs=12 realDrops=552 realErrors=2760 evolvingPairs=12 evolvingDrops=552 evolvingMismatches=72 seeded=1024 giant=8
DISCOVERY_10_EXPECTED_RED mismatches=40 matches=8 witnesses=8 positions=48
```

- 720 permutations ×6 = 4320 positions, legacy 3600 wrong /720 coincident first-position matches.
- 12 day pairs ×46 visible real drops=552 single-drop tests: legacy 2760 wrong; 12 complete 46-drop evolving sequences: **all 72 final bowl IDs wrong**; full normative reference self-consistent.
- 1024 deterministic signed cases, 8 giant signed bigint cases. Overall 2304 single-drop datasets / 13824 bowl cells: 11520 historical mismatches, 2304 matches; overwritten-read slots 13824.
- All ten archival intentional expected-red scripts exit nonzero as independently required by CI.
- During Stage20 two runs had QA-only mistakes: first `38213861079` TS typing in test files, then `38214091054` wrong argument index in test instrumentation (pour array instead of working bowl array). Fixes only tests; `src/discovery10LegacyInPlaceStir.ts` unchanged. Final `38214265315` all PASS.

## Stage 21 — पुढील एकमेव काम

मूळ 55-stage authoritative contract व नवीन live branch state तपासा, `HANDOFF_STAGE_20.md` आणि `docs/STAGE20_DISCOVERY10_VERIFICATION.md` पूर्ण वाचा. Stage 21 `PATCH 10` ची अनिवार्य shadow path:

```text
vaultOld = clone(B)
pending = clone(B)
for position = 1..6:
    bowlId = order[position]
    previous = order[wrap6(position-1)]
    next = order[wrap6(position+1)]
    s = vaultOld[bowlId] + 2*vaultOld[previous]
      + 3*vaultOld[next] + pour[position] + drop
      + stone[i][stoneKindByPosition[position]]
    pending[bowlId] = savePatch(s*s
      + 5*vaultOld[previous]*vaultOld[next] + i*position)
for bowlId = 1..6: B[bowlId] = pending[bowlId]
```

- TypeScript array index zero-based: `vaultOld[bowlId-1]`. All reads 반드시 vaultOld; all six writes pending; final explicit commit after six positions.
- **DO NOT remove/alter** `LegacyInPlaceBowlStirAdapter.stirInPlace`, `test/discovery10Red.ts` or Stage20 intentionally wrong path. Patched handler independently reuses historical mechanisms, preserving meaningful old shadow traces/calls rather than replacing history. Call counts, snapshot isolation, input-owner integrity, deterministic reentrancy, negative/huge bigint coverage.
- Stage 19 corrected pours and Stage 17 permutation order are prerequisites. Independent test-only normative reference and complete real 46-step evolution; 720 orders, 552 actual visible drops, 1024 seeded values, 8 giant cases, zero corrected differences. Historical mismatches and tenth red remain.
- Stage 22 discovery must **not** be started in Stage21. CI must prove Stages1–21 regressions, all 10 archived expected-red scripts, full TypeScript typecheck and canonical lock; mark LAST_COMPLETED_STAGE=21 **only after GitHub Actions verification**.
- Avoid starting from scratch. Fetch live HEAD first to detect parallel work; optimistic SHA lease on GitHub write. No user local action needed.
