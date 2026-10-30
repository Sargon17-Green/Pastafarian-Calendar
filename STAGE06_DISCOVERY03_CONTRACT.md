# Stadio 6 — DISCOVERY 03: inkluziva distanco inter du tagoj

**Stato:** difinita esplorkontrakto, ne efektivigita nek Native-kontrolita. Antaŭa SHA: `040400609df78f61016a876dca413496d7f1795a`; Stadio 5 estas GREEN (43/43 Native). La uzanto rajtigis sendependan kontrakto-difinon je 2026-10-30. Ne tuŝu `main`.

## Sendependa normiga bazo
La ekzistanta nur-testa `test/reference/core.gleam` eksplicite difinas:
`work_counts(calculation_day, target_day).distance = abs(target_day - calculation_day) + 1`.
Do la distanco inkluzivas ambaŭ finojn; ĝi ne estas la kutima ekskluziva diferenco. Ne enkonduku sesan datokomponanton.

Por DISCOVERY03 difinu diagnozan malnovan formulon
`old_distance(calculation_day, target_day) = abs(target_day - calculation_day)`.
Ĝi estas **intence kreita modelo de historia eraro por ĉi tiu nova esploro**, ne pruvo ke ekzistanta produktkodo jam havas tiun eraron. La normiga orakolo devas resti nur en `test/reference/`.

## Sendependaj atestoj
Kun `F = -15_055_671`:
- `(F,F)`: legacy 0, normigo 1 — EXPECTED_RED
- `(F,F+1)`: legacy 1, normigo 2 — EXPECTED_RED
- `(F+1,F)`: legacy 1, normigo 2 — EXPECTED_RED
La aritmetiko estas kontrolita sendepende. Tio ne estas Gleam/OTP Native-atesto.

## Aceptokondiĉoj por efektivigo
1. Kreu nur `discovery_03_distance.gleam` en la produktvojo, uzante la realan `MonsterContext`-validigon kaj dissendadon; redonu la historian valoron sen korekti ĝin. Neniun PATCH03, Stadio07 aŭ plenan daton.
2. Konservu ĉiujn 43 jam pasintajn testojn de Stadio 5. Aldonu tri precizajn normigajn EXPECTED_RED-testojn (supre) plus du pozitivajn diagnozajn ecojn (simetrio kaj nenegativeco de la malnova distanco). Celo, se neniuj aliaj testoj aldoniĝas: **45 PASS + 3 intencaj FAIL**. Reala nombro devas veni de Native.
3. Aldonu test-only orakolon kiu uzas la ekzistantan `work_counts` sen importaĵo en produktkodo; kontrolu nulon, ambaŭ direktojn, grandegajn pozitivajn/negativajn entjerojn, ŝtatan izolitecon kaj erarajn kuntekstojn.
4. Rulu `gleam format --check src test`, `gleam test` sur Gleam 1.18.1/OTP 28 kaj Canonical Names Lock ĉe unu preciza commit. La ordinara workflow povas finiĝi `failure` pro atestita EXPECTED_RED; ĝi **ne** estas ĝenerala CI-PASS.
5. Fermu Stadio 6 nur kiam ekzakte la antaŭviditaj normigaj diferencoj estas atestitaj kaj neniu regressio troviĝas. Se la kodvojo aŭ orakolo kontraŭdiras la kontrakton, ne inventu sukceson; korektu la kontrakton per aparta pruvo.
