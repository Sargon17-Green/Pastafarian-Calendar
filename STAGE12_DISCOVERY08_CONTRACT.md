# Stadio 12 — DISCOVERY 08: sep kaŝitaj gutoj

**Stato (2026-10-31):** produktkodo kaj 14 testoj planitaj por nova HEAD. CI ankoraŭ ne mezurita; nenia Stage12 PASS.

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
