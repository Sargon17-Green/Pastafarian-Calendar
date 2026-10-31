# Stadio 13 — DISCOVERY 09: kvardek ses videblaj gutoj

**Stato (2026-10-31):** produktkodo kaj 14 Stage13-testoj preparitaj por nova HEAD; ankoraŭ neniu Stage13 Native PASS. La dokumenta Stage12 HEAD estis verdita per 116/116 kaj Names Lock.

## Origino, celo kaj sendependeco

Nur post la verdigita Stage12-kodkapo `ff9077bb56f36f3ee92943cd5ab36ece36447e1b`. La nova etapo devas eligi precize **46 videblajn gutojn** en determinisma ordo, sen aldonado de datokomponantoj. La testorakolo estas la jam ekzistanta `test/reference/sauce.gleam::build_visible_drops(counts, stones, hidden)`; ĝi estas nur por testoj. Produktkodo devas efektivigi propran iteracian ripetadon en `src/pastafari/discovery_09_visible.gleam`, ne importi `test/reference`, ne kopii iun alian branĉon. Aparte aldoni `test/discovery_09_test.gleam`.

Proponita API: `visible_drops_for_days(calculation_day: Int, target_day: Int) -> List(Int)`; kaj `dispatch_discovery_09(context: bootstrap.MonsterContext) -> Result(Discovery09Output, bootstrap.BootstrapError)`. `Discovery09Output` enhavas la validigitan kompletigitan kuntekston kaj `visible: List(Int)`. Ne ŝanĝi ekzistantajn publikajn interfacojn, nomlistojn aŭ kvin datokomponentojn.

## Preciza matematika algoritmo

Prenu `counts` de la lokaj Stage05/07/08/09 kalkuloj, la 46 ŝtonojn el Stage10 kaj sep internajn gutojn el Stage12. Por i = 1,...,46 kalkulu tri antaŭaĵojn `p_b(i)` por b en {1,3,7}: se `i-b >= 1`, prenu la jam kalkulitan `V_(i-b)`; alie prenu la kaŝitan guton `H_(1-i+b)`. Ĉiu indekso estas 1-baza kaj devas esti ene de la respektiva listo.

Por ŝtono `S_i=(w_i,b_i,s_i,t_i,r_i)`, difinu

`x_0 = save(w_i*action + b_i*target + s_i*distance + t_i*connection + r_i*direction + p_1 + 3*p_3 + 5*p_7 + i)`.

Apliku ĉi-sekvence **11** mueladojn kun `(A,B,C,D,kind)`:
`(3,5,7,11,1)`, `(5,7,11,13,2)`, `(7,11,13,17,3)`, `(11,13,17,19,4)`, `(13,17,19,23,5)`, `(17,19,23,29,1)`, `(19,23,29,31,2)`, `(23,29,31,37,3)`, `(29,31,37,41,4)`, `(31,37,41,43,5)`, `(37,41,43,47,1)`.

Por ĉiu muelado, `x <- save(x² + A*x + B*p_1 + C*p_3 + D*p_7 + stone_field(S_i,kind))`. La fina x estas `V_i`. `save(z)=1+mod(z-1,M)`, `M=170141183460469231731687303715884105727`, kun ne-negativa restaĵo kaj senlimaj entjeroj. Eligo: listo `[V_1,...,V_46]`, ĉiuj en la fermita intervalo `[1,M]`.

## Sendependa kontrolo kaj minimumaj testoj

Komparoj al la referenca `sauce.build_visible_drops(core.work_counts(a,b),core.build_stones(),sauce.build_hidden_drops(...))` okazu nur en testoj. Preskribi **14** novajn testajn funkciojn: (1) longo 46; (2) unua funda guto; (3) lasta funda guto; (4) plena funda orakolo; (5) ordinara antaŭen; (6) ordinara inverso; (7) transiro ĉe `foundation_day-1`; (8) transiro ĉe `foundation_day+1`; (9) grandaj pozitivaj/negativaj BigInt; (10) modulo [1,M] por ĉiuj 46; (11) determinisma ripeto; (12) sendependaj interplektitaj kuntekstoj kaj diagnozoj; (13) nevalida retry; (14) nevalida recovery kaj prioritato kiam ambaŭ malvalidaj. Konservi **116** ekzistantajn regresiojn: celataj entute **130** pasoj, nur prognozo, ne mezurita rezulto. Neniu fabrikita expected-red; oni povas aldoni ateston nur post reala reprodukto.

## Akceptopordegoj kaj limoj

1. Stage12 kodkapo: Native run 41211388485 / job 124566951587: 116/116; Names Lock run 41211388470 / job 124566951854: SUCCESS. Por ĉi tiu nova dokumenta HEAD, postuli proprajn `completed/log` antaŭ atribui dokumentan PASS.
2. Verifi aktualan `Gleam+Esperanto` HEAD kaj la test-orakolon antaŭ kreado de Stage13-modulo.
3. `gleam format --check src test`, `gleam test` celo 130/130, source integrity kaj Names Lock `completed/success` sur identa nova SHA; registri run/job/artifact kaj SHA256. Neniu dueca rerun.
4. Neniu `main` ŝanĝo, merge, publikigo aŭ plena data algoritmo. Suba etapo estas interne evolua, ne sesa datokomponanto.

## Ekster-Gleam antaŭkalkulo

Sendependa Python BigInt-kalkulo (ne Native) donis ĉe fundamento F=-15055671: `V1=56644603826892212324764499696091907135`, `V46=141872771689426650819909896585756512282`; ĉe (11,21): `V1=60158691871357745200742433447203949263`, `V46=101264927043934815149790611409871558037`. Nova kodo uzas inversan akumulilon por antaŭaj gutoj; referenco uzas antaŭenan liston. Fiksaĵoj ne anstataŭas la 130 Native testojn.
