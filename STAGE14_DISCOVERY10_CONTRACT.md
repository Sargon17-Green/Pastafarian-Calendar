# Stadio 14 — DISCOVERY 10: ses komencaj bovloj

**Stato (2026-10-31):** nur preciza kontrakto, sen produktkodo, novaj testoj aŭ Stage14 Native PASS.

## API kaj amplekso

Post akcepto de Stage13 ĉe `eb843f263062adb3f61fd6b47f1fe4bf20b2c718`, konstrui ses komencajn bovlajn valorojn kiel interna parto de la saŭco, ne kiel novaj datokomponentoj. Sendepende efektivigi `src/pastafari/discovery_10_initial_bowls.gleam` kun `initial_bowls_for_days(calculation_day: Int,target_day: Int) -> List(Int)`, kaj `dispatch_discovery_10(context: bootstrap.MonsterContext) -> Result(Discovery10Output,bootstrap.BootstrapError)`. Eligo enhavu kompletigitan validan kuntekston kaj liston de **6** bovloj laŭ identigilo 1..6. Ne reuzi testan/orakolan kodon en produktado, ne tuŝi main aŭ la kvin datokomponentojn.

## Matematika kontrakto

Por `a` kaj `b`, apliku proprajn antaŭajn laborajn kalkulojn: `action=day_tag_patch(a)`, `target=day_tag_patch(b)`, `distance=abs(b-a)+1`, `connection=action+target`, `direction=(1 se b<a; 2 se b=a; 3 se b>a)`. Elektu `P=[17,19,23,29,31,37]` kaj por bovla identigilo `j=1..6` difinu `S_j=action+j*target+distance+connection+direction+P_j^2`, `B_j=save(S_j^2+j)`. `save(z)=1+mod(z-1,M)`, `M=170141183460469231731687303715884105727`, kun restaĵo en [0,M-1] kaj senlimaj entjeroj. La sola eligo estas `[B_1,...,B_6]`; neniu stira fazo, neniuj 46 gutoj ree aplikataj ĉi-stadie.

## Testa sendependeco kaj fiksitaj valoroj

La test-orakolo estas sole `test/reference/sauce.gleam::initial_bowls(core.work_counts(a,b))`. Senreferenca Python BigInt-kalkulo ĉe `a=b=foundation_day=-15055671` donis la ses bovlojn `[87617,136163,289447,724205,944789,1907167]`. Ĉe `a=11,b=21`: `[14507191460314810,22667488538707602,32641219990828972,44428423395860104,58028962890760230,73443063950500870]`. Tiuj estas pruvaj enir/elig-fiksaĵoj, NE Gleam Native PASS.

En `test/discovery_10_test.gleam` planu **12** novajn testajn funkciojn: listo-longo; funda kompleta fiksilo; funda orakolo; ordinara antaŭen; ordinara inverso; sama tago ekster fundamento; fundamento -1/+1; tre grandaj pozitivaj kaj negativaj tagoj; ĉiuj valoroj en [1,M]; determinisma ripeto; du interplektitaj validaj kuntekstoj kaj konservitaj diagnozoj; malvalidaj retry/recovery kun retry-prioritato. Reteni antaŭajn **130** testojn; kalkulita celo estas **142** sukcesoj, ankoraŭ ne mezuritaj.

## Pordegoj

1. Stage13 kodkapo `eb843f263062adb3f61fd6b47f1fe4bf20b2c718`: Native run 41211914142, job 124568501138, 130/130 kaj formato PASS, artifact 13046900606, SHA256 65cdf9f66a82747b32e132b1a58c3726f5416a754a9718ae34ba9115c84e40a0; Names Lock 41211914159 job 124568501120 SUCCESS.
2. Post ĉi tiu dokumenta commit, kontroli ĝian propran HEAD kaj CI antaŭ Stage14-kodakcepto.
3. Nova Stage14 kodkapo: `gleam format --check src test`; `gleam test` celas 142/142; source integrity; Names Lock `completed/success` ĉe la sama SHA, kun job, artifact kaj digest. Kiam eraro aperas, korekti nur reproduktitan logan diferencon.
4. Neniu `main`/merge, publikigo aŭ tuta datokonverto; neniuj falsaj `PASS` asertoj.
