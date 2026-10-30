# Kontra Stage 36 — DISCOVERY 18: pòtay negatif an chèn (PENDING_NATIVE_STAGE35)

**Pwojè:** PC-BRANCH-LUA-HAITIAN  
**Branch:** Lua+Kreyòl-ayisyen  
**Desizyon pwopriyetè:** 2026-10-30: ajan an gen otorizasyon pou defini kontni, kontra ak tès Stage 36 dapre orak kanonik la, san okenn demann apwobasyon seremonyèl ankò.  
**Estati:** CONTRACT_DEFINED_ONLY — **STAGE 36 PA LOUVRI** jouk QA Native Stage35 sou branch kòd ki koresponn lan verifye.

## Poukisa chwazi pòtay negatif anvan postStir12

Stage 35/PATCH17 konplete seri pòtay pozitif yo: F + total tout gap pozitif yo, san rebati règ ansyen yo; li pa t janm fè seri pòtay negatif oswa lojik postStir12 kòm nouvo kouch pwodiksyon. Orak Lua `test/normative_oracle.lua` defini toude seri yo. Chèn negatif la se kontrepati dirèk pou premye seri pozitif la, se poutèt sa Stage36 ap kòmanse ak **DISCOVERY18 / NEGATIVE_GATE_LAST_GAP_ONLY**, epi Stage37/PATCH18 ap kapab korije akimilasyon an. `postStir12` rete yon kouch pita; pa gen okenn aplikasyon Stage36 ki ka eseye li san nouvo kontra ak QA.

Sa a se yon **chwa sou lòd devlopman**, pa yon deklarasyon ke kòd Lua aktyèl la deja gen yon bug negatif. Bug istorik pozitif Stage34 te verifye; istwa negatif kap vini an se yon konpòtman legacy yo dwe enplemante eksplisitman, teste ak de prèv endepandan, epi konsève l kòm yon mak erè pou PATCH18.

## Definisyon kanonik

F = `FOUNDATION_DAY=-15055671`. Pou endis negatif `-n` avèk n pozitif:

```
r_n = sauce(F, F-n)
s_n = askBowl(r_n, 1, SEAL_GATE_GAP)
gapNeg(n) = 41 + chooseRank(s_n, 922)       // nan 42..963
Gate(0) = F
Gate(-n) = Gate(-(n-1)) - gapNeg(n)
         = F - sum_{i=1..n} gapNeg(i)
```

Orak ekzekitab: `test/normative_oracle.lua`, `negativeGateGap(n)`, `ensureGateIndex(-n)`, `resetGateCache()` (kalkil test sèlman). `chooseRank` pran endis 1..922 e fè aritmetik BigInt presi; pa entèprete sòt sa yo kòm nimewo desimal nan float.

Premye konpòtman legacy ki dwe prezève kòm **intentionally wrong** nan Discovery18:

```
oldNegativeGate(-n) = F - gapNeg(n)
```

N=1 se temwen ki mache pa aksidan; pou tout n>=2 ak gapNeg(i)>=42, ansyen rezilta a manke sòm gap avan yo. Egzanp diferans egzak pou n=2: `oldNegativeGate(-2) - Gate(-2) = gapNeg(1)` (>0). Pa janm korije pwodiksyon Stage36; Stage37 ap fè sa sèlman apre verifye ke ansyen mak la rete.

## API / limit Stage36, apre ouvèti otorize

- `src/legacy_negative_gate_position.lua`: `LegacyNegativeGatePosition.execute(n, streams)`, `1<=n<=32`; `streams[i]` gen rèspons `first` ak `directionStep` kolekte pa caller a, pa orak test nan pwodiksyon.
- Yon nouvo wout fasad `S.legacyNegativeGateProbe(n, streams)` nan `src/spaghetti.lua`; appelle dispatcher + boundary aktyèl pou chak etap, revandike kontèks pou chak invocation. Li dwe konsève tout eta etap 1–35, san ekri nan tab global oswa cache orak.
- Retounen `oldNegativeGate` raw, ak `historicalNegativeGateDayDecimal`, `negativeGateIndex=-n`, `missingPreviousGaps=true`, kontè ak branchTrace. **Pa gen PATCH18 nan Stage36.**
- Si stream pa gen longè oswa siy nòmal, rejte li avan mutasyon; gwo valè itilize `src/bigint.lua` sèlman. `n=0`, n neg, >32, mwens/mwens twòp stream, tip mal ak entèferans kontèks rejte.
- Prod pa import `test/normative_oracle.lua`; `postStir12` rete sèlman fonksyon endepandan orak pou pwodwi repons otantik test, li pa tounen nouvo modil pwodiksyon Stage36.

## Native / differential / acceptance

**Pòt obligatwa anvan nenpòt kòd Stage36:** rantre nan SHA ki koresponn ak suite Stage35, verifye `lua5.3 test/stage35_tests.lua .` nan yon runner otorize, anrejistre `git rev-parse HEAD`, `lua5.3 -v`, stdout, stderr, exit, tou suite Stage1–35, pozitif n=1/32, fault injection, reentrancy, BigInt, 3 sauce otantik; rezilta Native PASS se kondisyon pou ouvè `CURRENT_STAGE=36`. Yon ansyen CI Stage35 sou menm kòd pwodiksyon an bay baseline valab, men pa fè kòm si QA lokal nouvo a te kouri: `evidence/stage35-native-qa-not-run-2026-10-27.md` rete dokiman onèt.

Apre ouvèti:
1. Tès endepandan orak `O.resetGateCache(); O.ensureGateIndex(-n)` pou n=1..32, ak `O.negativeGateGap(n)`. Pwouve diferans `0` pou n=1, pozitif pou n=2..32; se EXACT `1 MATCH + 31 EXPECTED_RED` pou seri n=1..32, san erè siplemantè.
2. Ankouraje plizyè suite stream sentetik ki gen gap nan 42..963 ak gwo bigint, repetisyon ak chanjman nan prefix gap. Tès yo dwe montre old(-n) pa depann de gap(1..n-1), tandiske orak fè sa.
3. Tès n invalid, malformed stream, duplicate/nested contexts, ownership, deterministic retry apre fault, absent oracle import, 1..32 range, ak pwodiksyon Stage35 unchanged.
4. Pwodiksyon va refize final `calendarDateSpaghetti` si kouch ki nesesè yo poko egziste. Sa pa konfime senk konpozan dat yo ni yon motè konplè.
5. CI Lua Native sou menm commit SHA ak canonical names lock; rapòte egzak count de red, kontrol, stdout/stderr, exit, audit; failure unexpected oubyen red diferan = FAIL. Stage36 pa close si CI pa GREEN, Stage37 pa kòmanse avan.

## Gate pou chanje estati

Anvan prèv nouvo QA Native Stage35, `CURRENT_STAGE=35`, `LAST_COMPLETED_STAGE=35`, `STAGE36=DEFERRED_NATIVE_PREREQUISITE`. Nenpòt travay konsepsyon/dokiman oswa workflow Stage35 kapab ajoute nan branch, men li pa ouvè Stage36. Lè evidence Native otorize complete/success ak endepandans kòd verifye: ouvè Stage36 san kestyon itilizatè; sèlman lè sa a kòd Discovery18 ak tès li yo gen dwa antre.

## Referans imuiab

- [Stage35 source baseline / checkpoint](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38)
- [Stage35 istorik CI ki te reyisi](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890588880)
- [Stage35 QA recheck NOT_RUN](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/6bbf17891c0773d89a76287daba932c1f0e77a44/evidence/stage35-native-qa-not-run-2026-10-27.md)
- [Oracle / negative gate source](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38/test/normative_oracle.lua)
