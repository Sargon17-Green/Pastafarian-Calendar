# Stadio 31 — DISCOVERY 27: nombro de ne-malplenaj sinsekvaj fenestroj kun sumo en fermita intervalo

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. Stage30 estas akceptita. Stage31-produktkodo kaj la 12 publikaj testoj estas efektivigitaj en koda commit 8b9791afe997a5b1941215a00619e945203453f5 kaj trapasis la sam-SHA Native/Names-pordegojn. Ĉi tiu aparta dokumenta commit registras la efektivigon kaj la mezuritan akcepton; ĝi ne fermas la finan Stage31 metadata-pordegon. LAST_COMPLETED_STAGE restos 30 ĝis la aparta fina metadata commit kaj ĝiaj propraj CI-pruvoj estos akceptitaj.

## Kontrolita antaŭkondiĉo

Stage30 fina metadata commit: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/0c5b76c7c335f0f8daf51210bf2a964c9c419b43.
- Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44363714434, job 135011688330, completed/success, **334/334** pasis, neniuj malsukcesis, Gleam 1.18.1, OTP 28, ERTS 16.4.0.7, fontintegreco kaj formatter PASS. Artefakto 14455293117, GitHub-upload SHA256 274255b92368e164a03fa5d19d702c9e8004a3c2cb6d3c5c3b0d40a111024ab4.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44363714438, job 135011689754, completed/success sur ĝuste la sama HEAD.
Ĉi tiu pordego fermas Stage30. Ĝi ne pruvas aŭtomatan kalendaran sinsekvon, jarkalkulon aŭ plenan datkonverton.

## Preciza celo

Stage30 kalkulas C(t), la nombron de ĉiuj ne-malplenaj kontiguaj fenestroj de eksplicite petitaj pozitivaj Stage25-interspacoj kies sumo estas almenaŭ t. Stage31 kalkulu por ĉiu petita fermita intervalo [lower, upper] la nombron B(lower,upper) de tiaj fenestroj kies sumo plenumas lower <= sum <= upper. Petordo, duplikatoj kaj pozicioj de la petoj devas resti senŝanĝaj.

Por k eksplicitaj interspacoj g_0..g_(k-1), 42 <= g_i <= 963, kaj [a,b) kun 0 <= a < b <= k:
- Se lower > upper, B=0.
- Alie B(lower,upper) = C(lower) - C(upper+1), kie C venas de la **jam akceptita Stage30**.
- k=0: B=0 por ĉiu intervalo.
- lower <= 0 kaj upper >= sum(gaps): B=k*(k+1)/2.
- upper < 42 aŭ lower > sum(gaps): B=0.
- Ĉiuj limoj inkluzivas siajn egalecojn; la malplena fenestro ne estas kalkulata.
- Matematike 0 <= B <= k*(k+1)/2. Neniam saturu aŭ konvertu Gleam Int al fiks-larĝa entjero; upper+1 uzas la arbitran precizecon de BEAM Int.

## Publika API kaj semantiko

Produkta modulo: src/pastafari/discovery_27_sum_bands.gleam
Testmodulo: test/discovery_27_test.gleam
Publikaj tipoj: SumBand(lower: Int, upper: Int); SumBandCount(lower: Int, upper: Int, qualifying_windows: Int).
Publika funkcio: dispatch_discovery_27(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), bands: List(SumBand)) -> Result(List(SumBandCount), discovery_19_interval_value.Discovery19Error).

- Konstruu la ordigitan sojloliston [lower_0,upper_0+1,lower_1,upper_1+1,...] el bands; por inversaj intervaloj oni povas kalkuli sojlojn sed ne uzi negativan diferencon.
- Voku discovery_26_window_count.dispatch_discovery_26(context, requested_bowl_ids, thresholds) **precize unufoje por ĉiu publika voko**, ankaŭ kiam bands=[] aŭ ĉiuj intervaloj estas inversaj. Ĝi mem vokas Stage26 precize unufoje. Ne voku Stage25, Stage26 aŭ Stage30 aparte por ĉiu intervalo; ne preterlasu validigon por inversa intervalo.
- Propagu la originan Error(error) de la Stage30-voko sen ŝanĝo. Validigo de ne-malplenaj idoj/kunteksto antaŭas la enhavon de bands, inkluzive de bands=[] kaj inversaj intervaloj.
- Ĉe Ok(counts) parigu sinsekvajn sojlokalkulojn laŭ ordo. Por lower <= upper redonu C(lower)-C(upper+1); por lower > upper redonu 0. Redonu precize unu SumBandCount por ĉiu petita intervalo en sama ordo kaj kun sama multoblo. Neniu ordigo/deduplikigo.
- Malplena id-listo kun neuzata nevalida kunteksto konservas la antaŭan Stage30/26-Ok-konduton. Nekonvena ne-malplena id-listo/kunteksto liveras la saman eraron seninterrompe.
- Tempo O(k*q+k), memoro O(k+q) por k interspacoj kaj q intervaloj. Nek limigu la liston al ses petoj nek faru senliman serĉadon. Ne ŝanĝu jam akceptitajn modulojn, orakolojn, testojn, nomojn aŭ CI-workflow.

## Sendependa testa oracle, invariantoj kaj limoj

La test-orakolo rekte uzu discovery_21_gate_batch.dispatch_discovery_21(context, ids), ekprenu sample.gap laŭ ordo, konfirmu 42..963 kaj per **du nestitaj finiaj bukloj** enumeraciu ĉiun ne-malplenan [a,b). Por ĉiu fenestro rekte akumulu ĝian sumon kaj aldonu 1 nur se lower <= sum <= upper. Ne voku Stage26/27/29/30-produktan funkcion por kalkuli atendatajn rezultojn. Komparu la kompletan ordigitan liston de SumBandCount.

Invariantoj: B >= 0; B <= k(k+1)/2; B(lower,upper)=0 kiam lower>upper; larĝigo de valida intervalo ne malpliigas B; suma particio B(lo,hi)+B(hi+1,hi2)=B(lo,hi2) por lo<=hi<hi2; egalecoj ĉe precizaj fenestrosumoj devas inkluzivi la fenestron. Kun ripetataj petoj, la sama gap aperas en ĉiu pozicio aparte. Granda negativa/pozitiva konteksto kaj arbitre grandaj Int-limoj restu precizaj.

## Precize dek du efektivigitaj publikaj gleeunit-testoj

1. Malplenaj idoj kaj malplenaj bands -> Ok([]), post unu valida Stage30-dispatch.
2. Malplenaj idoj, neuzata nevalida kunteksto, bands [-1,0], [0,0], [1,10] -> tri nuloj.
3. Unu valida gap g: intervaloj [g,g], [g-1,g-1], [g+1,g+1], [g-1,g] kontraŭ oracle.
4. Pluraj petoj: [total,total], [total+1,total+1], [1,total] kaj sumaj egalecoj.
5. Internaj ne-prefiksaj fenestroj kun intervaloj el Stage25-gapaj sumoj, inkluzive de unuelementa kaj duelementa fenestro.
6. Duplikataj bovlo-identigiloj kaj malsamaj pozicioj: kontraŭ la sendependa oracle.
7. Neordigitaj duplikataj bands: konservu la plenan respondordon kaj multoblon.
8. Nur negativaj/tre malaltaj intervaloj: nulaj kvantoj, ankaŭ ĉe inversa intervalo.
9. Larĝa intervalo [-big,+big] inkluzivas precize k(k+1)/2 nemalplenajn fenestrojn.
10. Nevalida bovlo propagas Stage30/26-eraron eĉ kiam bands=[].
11. Nevalida ne-malplena kunteksto propagas originan eraron eĉ kiam ĉiu band estas inversa.
12. Grandaj tagoj, tre grandaj Int-limoj, multaj limigitaj duplikataj petoj; ampleksa oracle, monotoneco, particio kaj maksimuma limo.

## Senzorga sinteza preflight (NE Gleam Native)

Por ĉiu el 364 listoj de longo 0..5 kun eroj en {42,43,963}, komparu 18 intervalojn (inkluzive de inversa, negativa, preciza limo, [0,42], [42,42], [963,1926] kaj tre larĝaj +-10^12): kalkulo per du Stage30-stilaj monotonaj sojloskanoj kontraŭ rekta nesta fenestro-enumeracio. **6,552/6,552 JS-komparoj egalis; nul diferencoj**, ĉiuj limoj 0..k(k+1)/2. La du JS-funkcioj kalkulis sendepende; tio estas dezajna preflight, **ne** Gleam-kompilo, Native-testoj aŭ sendependeco de Stage25-datumoj.

## Efektivigita kodo kaj mezurita akcepto

- Koda komito: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/8b9791afe997a5b1941215a00619e945203453f5 (komenca koda komito 94f6bb412e016d76c54d44ac60c90b9c2288bda3; posta korekto estis nur la kanona Gleam-formatado en du dosieroj).
- Produkta modulo: `src/pastafari/discovery_27_sum_bands.gleam`; testmodulo: `test/discovery_27_test.gleam`; precize 12 unikaj publikaj testfunkcioj.
- Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392284045 — job 135112832721, completed/success, HEAD ekzakte 8b9791afe997a5b1941215a00619e945203453f5, 346 passed/0 failures, Gleam 1.18.1, OTP 28, ERTS 16.4.0.7.
- La Native job sukcese plenumis `gleam format --check src test`, `gleam test`, `git diff --exit-code`, `git diff --cached --exit-code`, la kontrolon pri neniuj ne-spuritaj `src/test` dosieroj kaj la duoblan HEAD/GITHUB_SHA egalec-kontrolon.
- Artifact: ID 14467707863, SHA256 `2b423a3b7d9ce3ee3c1bc42edb6c017f374d5c0b0490fed27b7fa0ceef9e7184`.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392284017 — job 135112828266, completed/success, sur la sama SHA.
- Ĉi tiuj pruvoj akceptas nur la koda SHA. Ĉi tiu dokumenta SHA kaj la posta fina metadata SHA bezonas apartajn novajn CI-pordegojn.

## Akceptopordegoj (ĉiu bezonas propran sam-SHA completed/log-pruvon)

1. **Kontrakto**: nur ĉi tiu kontraktdosiero + DEVELOPMENT_STAGE.md en unu commit; Native 334/334, formatter kaj fontintegreco PASS, Canonical Names Lock SUCCESS. Ĝis ambaŭ rezultoj estas completed, kontrakto estas PENDING, ne PASS.
2. **Kodo (AKCEPTITA)**: koda SHA 8b9791afe997a5b1941215a00619e945203453f5; unu produkta modulo + precize 12 sendependaj publikaj gleeunit-testoj. Native run 44392284045/job135112832721 completed/success, **346 passed, 0 failures**, Gleam 1.18.1, OTP 28, ERTS 16.4.0.7; formatter kaj source-integrity guard-oj PASS. Artifact 14467707863, SHA256 2b423a3b7d9ce3ee3c1bc42edb6c017f374d5c0b0490fed27b7fa0ceef9e7184. Canonical Names Lock run 44392284017/job135112828266 completed/success sur la sama SHA.
3. **Dokumenta fermo**: ĉi tiu aparta commit enhavas nur la ĝisdatigitan kontrakton kaj DEVELOPMENT_STAGE.md; ĝi bezonas siajn proprajn sam-SHA 346/346 Native, formatter/source-integrity kaj Names SUCCESS antaŭ la fina metadata commit.
4. **Fina metadata**: post akceptita dokumenta fermo, aparta commit nur por la fina metadata, kun propraj sam-SHA 346/346 Native, formatter/source-integrity kaj Names SUCCESS; nur tiam agordu LAST_COMPLETED_STAGE=31.
5. queued/in_progress nek PASS nek bloko. Neniu mana duobla CI-dispatch; neniu main, merge aŭ publikigo.
