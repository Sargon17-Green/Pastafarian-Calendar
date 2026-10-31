# Stadio 12 — DISCOVERY 08: sep kaŝitaj gutoj

**Stato (2026-10-31):** Stage12-kodkapo verifita: Native 116/116, formato PASS, kompilado PASS, kanona Names Lock SUCCESS; dokumenta kapo ankoraŭ bezonos apartan CI.

## Kontrakto kaj algoritmo

La kanona orakolo estas `test/reference/sauce.gleam::build_hidden_drops(core.work_counts(a,b), core.build_stones())`. Produktkodo havas propran iteracian kuiradon de sep kaŝitaj gutoj kaj reuzas nur lokajn Stage05/07/08/10 funkciojn, ne importas testajn referencojn aŭ fremdbranĉan kodon. Enigo: `bootstrap.MonsterContext`; eligo: `Result(Discovery08Output(context, hidden: List(Int)), BootstrapError)` kun precize **7** gutoj. Por nevalida kunteksto `InvalidRetryBudget` antaŭ `InvalidRecoveryDepth`. La kaŝitaj gutoj estas internaj intervaloroj, ne sesa datokomponanto.

La laboraj kalkuloj estas `action=day_tag_patch(a)`, `target=day_tag_patch(b)`, `distance=abs(b-a)+1`, `connection=action+target`, `direction=1/2/3` laŭ b kompare al a. La 46 ŝtonoj devenas de la propra Stage10 generatoro; uzataj nur la unuaj sep. Difinu `save(x)=1+mod(x-1,M)`, `M=170141183460469231731687303715884105727` kun pozitiva restaĵo, kaj precizaj senlimaj entjeroj.

Por k=1..7 elektu `(A,B,C,D)` respektive `(3,4,6,8),(5,7,10,12),(7,10,14,16),(9,13,18,20),(11,16,22,24),(13,19,26,28),(15,22,30,32)`. Komencu `x=save(action+A*target+B*distance+C*connection+D*direction+sum(five stone fields))`. Ripetu j=1..7: `x=save(x*x+3*x+stone_field(kind[j])+j)`, `kind=[1,2,3,4,5,1,2]`. Konservu la finan x por ĉiu k, en kanona ordo.

## Sendependa orakolo kaj nombraj atestoj

La referenca `reference/sauce` kodaro estas nur test-orakolo. Aparte Python-BigInt kontrolis ekz. `a=b=-15055671`: unua guto 119390830530032782664128530203002080344, lasta 6164285870955721082771365327359496898; `a=11,b=21`: unua 110999856267053877951849425695516070833, lasta 145647172008119639517043497637223485446. Tiuj nombroj ne anstataŭas Native-testojn.

14 novaj unit-testoj: longo, du fiksaj randoj, kompleta 7/7 orakolo ĉe fundamento, ordinara paro, inversa paro, fondolimo ambaŭdirekte, BigInt ambaŭdirekte, modulo-invarianto, ripetebleco, kunteksta izolado, retry-eraroj, recovery-eraroj kaj ambaŭ malvalidaj kun prioritato. 102 konfirmitaj antaŭaj testoj + 14 novaj = **116 prognozitaj**, ne efektive mezuritaj. Ne ŝanĝu referencajn modulojn, frozen-nomlistojn, main, aŭ kvin datumkomponentojn.

## Akceptopordegoj

1. Stage11 HEAD 7c12a4a8eeff8f4c68371e2373a8d9ca62b92205: Native run 41199740784, job 124533006663, formato PASS kaj 102/102, artifact 13042089676 SHA256 ceae21269bb7e5498b794bbee1a908716a7efd68d7c16f7786e048902444a245; Names Lock 41199740794, job 124533006857 SUCCESS; sama HEAD.
2. Nova Stage12 commit kun unu produktmodulo, 14 testoj kaj statusa kontrakto.
3. Nur `completed` sur tiu sama nova SHA: `gleam format --check src test`, `gleam test` celo 116/116, Names Lock SUCCESS, head-verify, artifact ID/SHA256. Se eraro, riparu nur laŭ efektiva log-diferenco; neniu supozita PASS.
4. Neniu ŝanĝo al main, neniu full-date aŭ eldonado.

## Mezurita akcepto kaj riparhistorio (2026-10-31)

- Origina SHA `b102dbf535f769c573af005753d13b41f9ccb238`: Native 41203279989 / job 124543192488 `completed/failure`, nur pro du nekonformaj formatitaj dosieroj; testoj ne ekrulis. Names Lock 41203279990 / job 124543192425 `completed/success`.
- Formata riparo `c9437da6a2c936201044d015284ab7615473eb4c`: nur la kanonaj ŝanĝoj el la Native-logoj; Native 41211277712 / job 124566621506 `completed/failure` ĉe tipo-kontrolado de unu test-esprimo (`==` kaj `|>`), post sukcesa formato. Names Lock 41211277686 SUCCESS.
- Fina kodkapo `ff9077bb56f36f3ee92943cd5ab36ece36447e1b`: izolita test-aserta prioritat-riparo. Native run [41211388485](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211388485), job `124566951587`, `completed/success`: Gleam 1.18.1 / OTP 28; `gleam format --check src test` PASS, kompilado PASS, **116 passed, 0 failures**, git HEAD/source-integrity PASS. Artefakto `13046555792`, SHA256 `2bc30dfa56e7b46fb556f5623c89f0a3dc52cb7745097e3d77c2d8bc16c50e1f`.
- Names Lock run [41211388470](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211388470), job `124566951854`, `completed/success` sur precize la sama SHA.
- Stage12 akceptita nur por kaŝitaj gutoj (nek plena dato nek ĉefbranĉa kunfando); la nova dokumenta HEAD postulas proprajn kontrolrezultojn. La sekva contrato estas `STAGE13_DISCOVERY09_CONTRACT.md`.
