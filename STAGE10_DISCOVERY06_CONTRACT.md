# Stadio 10 — DISCOVERY 06: la kanona ĉeno de 46 ŝtonoj

**Stato (2026-10-31):** la kodaj Stage10 CI-pordegoj finiĝis sukcese ĉe `58416104124eb0cef33876ee2b6ebcd51a8a509c`: Native 90/90, formatter PASS kaj Names Lock SUCCESS. Ĉi tiu dokumenta HEAD ankoraŭ bezonas propran CI-verifikon.

## Deveno kaj nura amplekso

La kanona referenco `test/reference/core.gleam::build_stones()` difinas 46 ordigitajn ŝtonojn. Ĉiu ŝtono enhavas kvin nombrojn: `wheat`, `barley`, `salt`, `bitter`, `red`. Ĉi tiuj estas **internaj ŝtonkampoj**, NE la kvin finaj datokomponantoj. La ref-modulo estas nur testa orakolo; produktkodo ne importu ĝin aŭ reuzu ĝian implementon.

La komenca ŝtono (numero 1) estas (17, 29, 43, 71, 101). Por indekso `i=2..46`, el antaŭa ŝtono `(w,b,s,k,r)`, kalkulu

- `w' = save(w*w + 3*b + i)`
- `b' = save(b*b + 5*s + w)`
- `s' = save(s*s + 7*k + b)`
- `k' = save(k*k + 11*r + s)`
- `r' = save(r*r + 13*w + k)`

kie `M=170141183460469231731687303715884105727` kaj `save(x)=1+mod(x-1,M)`, kun matematike pozitiva resto `0..M-1`. Produktmodulo estu aparta vostrekursia aŭ fold-bazita generatoro, ne kopio de la referenca rekursia konstruo. Ĉiuj operacioj estu precizaj grandaj entjeroj.

## Enigo kaj eligo

Enigo: `bootstrap.MonsterContext`, uzata por valideco kaj izolado sed ne por ŝanĝi la ŝtonvalorojn. Eligo je valida kunteksto: `Ok(Discovery06Output(context, stones))`, kun ekzakte 46 ŝtonoj en ordo 1..46, ĉiu kun kvin kampoj. Je malvalida kunteksto, reproduktu la validigordon de `bootstrap.dispatch_context`: `InvalidRetryBudget` antaŭ `InvalidRecoveryDepth`. Neniu mutacio de `main`, ekzistantaj nomlistoj, kvin datokomponantoj, aŭ `test/reference/core.gleam`.

## Sendependa orakolo, testoj kaj limoj

Orakolo: `core.build_stones()` el la frosta testa referenco; por antaŭatendataj datumoj neniam alvoku la novan produktmodulon. Planu **12** novajn Gleam unit-testojn: (1) 46 ŝtonoj, (2) unua ŝtono, (3) dua ŝtono, (4) tria ŝtono, (5) lasta ŝtono, (6) ĉiuj 46×5 kampoj kontraŭ la orakolo, (7) ĉiuj 230 kampoj en `1..M`, (8) ripetebleco, (9) izolado de du validaj kuntekstoj, (10) nevalida retry-budget, (11) nevalida recovery-depth, (12) ambaŭ nevalidaj kun ĝusta prioritato.

Sendependa Python-BigInt-kontrolkalkulo (nur matematika antaŭkontrolo, **ne** Gleam Native):
- Ŝtono 2 = (378, 1073, 2375, 6195, 10493).
- Ŝtono 3 = (146106, 1163582, 5685063, 38495823, 110114158).
- Ŝtono 46 = (73799454308499791987382386781055001470, 147925408106533232424672641008220632365, 94499522601819303005579577099149028685, 108473647672201258090947028490673028834, 137131922036975206684616468948804344042).

## Akceptaj pordegoj

1. Konfirmu Stage09 fina dokumenta HEAD per `completed` CI-logoj por Native kaj Names Lock; neniu `queued`/`in_progress` rezulto estas PASS aŭ blokilo.
2. Aldonu unu produktmodulon, 12 unit-testojn kaj ĝisdatigu `DEVELOPMENT_STAGE.md`; konservu la referencon netuŝita. Pasinta mezurita regresobazo: 78; celata nombro post aldono: **90 PASS / 0 FAIL (nur prognozo)**.
3. `gleam format --check src test`, `gleam test`, kaj Canonical Names Lock sur la **sama nova SHA**, kun fakte kontrolitaj job-logoj.
4. Testu la kompletan 46×5-ŝtonan tabelon kontraŭ la aparta orakolo; raportu nombrojn, SHA, run/job ID kaj artifact SHA256. Neniam asertu `STAGE10_COMPLETED_GREEN` antaŭ la du efektivaj pordegoj.
5. Sen `main`-merge, publika eldono, sesa datokomponanto, aŭ ŝanĝo de la kanona fonto.

## Malfermo de la efektiva koda etapo

Enmetitaj vojoj: `src/pastafari/discovery_06_stones.gleam` kaj `test/discovery_06_test.gleam`. 12 apartaj unit-testaj funkcioj planitaj/kreitaj; la totala celo de 90 estas ankoraŭ prognozo, ne mezurita Native. La rekursia produktgeneratoro uzas sian propran `Stone`-tipon kaj lokan modulon `normalized_save`; testoj komparas aparte kun `reference/core`. Nek `main` nek la kanona fonto estas ŝanĝita.

## Fakta Stage10 koda fermo — 2026-10-31

- Unua koda SHA `eff34cf0146335739320f82bf383b59f3ca728a4`: Native 41193460881 malsukcesis **nur** en `gleam format --check` por `test/discovery_06_test.gleam`, antaŭ la testoj; Names Lock 41193460844 sukceso. Neniu funkcia malsukceso estas atribuita al tiu rulado.
- Ekzakta formato-diferenco estis aplikita sen ŝanĝi semantikon; nova SHA `58416104124eb0cef33876ee2b6ebcd51a8a509c` (patro eff34cf...).
- Native run 41193532282, job 124514999793: `completed/success`, Gleam 1.18.1 / OTP 28, formato PASS, **90 passed, no failures**.
- Canonical Names Lock run 41193532343, job 124514999949: `completed/success` ĉe la sama SHA.
- Evidenta artifact ID 13040066752, GitHub-raportita SHA256 `66501129c9fea0898b15b1891ace00da9c3bae2f797d01f63e12d6f93fc8de7f`.
- 78 antaŭaj regresaj testoj + 12 novaj `DISCOVERY06` testoj; la kompleta 46×5-ŝtona komparo estas unu el la 12. Ĉi tio ne pruvas kompletan pastafarian datkalkulon.
