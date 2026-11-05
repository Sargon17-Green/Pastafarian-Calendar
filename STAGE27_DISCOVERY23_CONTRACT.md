# Stadio 27 — DISCOVERY 23: sumoj por eksplicitaj duonmalfermitaj fenestroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj; Stadio 26 akceptita. Ĉi tiu dokumento estas la **kontrakto** de Stadio 27, ne ĝia realigita kodo aŭ Native PASS.
Antaŭa akceptita HEAD: `8579f9a326b87ebf4560f7d621171df2a96dbf61`.
Stadio 26: [Native 41978485087](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41978485087), job 127082826982: Gleam 1.18.1, OTP 28, formato kaj fontintegreco sukcesis, **286/286**; [Names Lock 41978485080](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41978485080), job 127082826874: SUCCESS sur la sama SHA. Native-artefakto 13392806764, sha256 a3d098e67d15d59e8b2c4e52ce204f80d1df52227e99324c041a5cb0271738a3.

## Motivo, limo kaj sendependeco

Stadio 26 konservas `prefix_total` por **eksplicita, ordigita** listo de petataj bovlaj ID-oj. Tial la sekva determinisma kunmeta operacio estas pridemandado de **eksplicite petita** intervala sumo en tiu listo, sen imagi aŭtomatan kanonan pordegoserion. Stadio 27 ne kalkulas jaron, la tutan kalendaron aŭ datkonverton. Neniuj fontoj, programoj, fiksaĵoj aŭ orakoloj el aliaj lingvo-branĉoj.

## Preciza kontrakto de enigo/eligo

- Nova modulo: `src/pastafari/discovery_23_gap_windows.gleam`; nova testdosiero: `test/discovery_23_test.gleam`. Ne ŝanĝu akceptitan produktan logikon de Stage25/26, `CANONICAL_NAMES_LOCK.sha256`, aŭ la sendependan `test/reference/sauce.gleam`.
- Nova tipo `WindowTotal`: `WindowTotal(start: Int, end: Int, total: Int)`. Nova erartipo `Discovery23Error`: `Upstream(discovery_19_interval_value.Discovery19Error)` kaj `InvalidWindow(start: Int, end: Int, size: Int)`.
- Publika funkcio `dispatch_discovery_23(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), windows: List(#(Int, Int))) -> Result(List(WindowTotal), Discovery23Error)`.
- Voku `discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)` **precize unufoje**, sen rean analizon de individuaj bovloj. Ĝia unua eraro estas `Error(Upstream(e))`, sen anstataŭigo per posta eraro de fenestro.
- Por `k` specimenoj la valora prefiksa tabelo estas `s_0=0`, `s_i=prefix_total` de la i-a `GapPrefix`. Por ĉiu eniga fenestro `#(a,b)` la validiga kondiĉo estas `0 <= a <= b <= k`; kiam valida, eligu `WindowTotal(start:a,end:b,total:s_b-s_a)`. Duonmalfermita semantiko: la specimenoj ĉe pozicioj `a,a+1,...,b-1` kontribuas, sed ne la pozicio `b`.
- Konservu precizan ordon, longon kaj duplikatojn de `windows`. Nenio estas ordigita, malduobligita aŭ silently clipped. La unua malvalida fenestro laŭ eniga ordo redonu `Error(InvalidWindow(a,b,k))`. La valoro `a=b` estas valida kun `total=0`, inkluzive `#(k,k)`. Por `k=0` nur `#(0,0)` validas.
- Se `requested_bowl_ids=[]`, la Stage26-voko restas `Ok` eĉ se la neuzata kunteksto estas malvalida; poste nur la eksplicitaj fenestroj validiĝas. Se `windows=[]`, redonu `Ok([])` **nur post** la sola Stage26-voko: ne subpremu erarojn de malvalidaj ne-malplenaj bovlaj petoj.
- Sen konvertado al 64-bita entjero. Neniu artefarita limo je ses bovloj. Rekta finkondiĉa algoritmo por finhavaj listoj; neniu senfina orakola serĉo. Permesata supra tempolimo por simpla referenc-indeksado: `O(k + kq)` por `q` fenestroj; plenaj Stage25/Stage26 rekalkuloj **ne** okazu por ĉiu fenestro.

## Sendependa orakolo kaj 12 mezureblaj testoj

La orakolo en `test/discovery_23_test.gleam` voku rekte la akceptitan `discovery_21_gate_batch.dispatch_discovery_21` (ne la novan produktan funkcion, nek Stage26-prefiksojn). Por ĉiu valida `#(a,b)`, sendepende faldu `sample.gap` en `list.take(list.drop(samples,a),b-a)`, komparu kun la nova rezulto, kaj kontrolu `total=s_b-s_a` nur kiel dua, metamorfisma kontrolo. `reference/sauce` rajtas esti uzata nur por apartaj specimenoj kies antaŭkondiĉo de maksimume 8 rifuzoj estis sendepende montrita. Por `m=b-a>0`, la acceptita Stage24-kontrakto disponigas `42*m <= total <= 963*m`; por `m=0`, `total=0`.

Ĉiu el la jenaj estas aparta `pub fn ..._test()` (12 novaj; la ekzistantaj 286 ne ŝanĝiĝu):

1. Malplenaj bovloj kaj malplenaj fenestroj donas `Ok([])`.
2. Malplena bovlolisto kun neuzebla kunteksto kaj `#(0,0)` donas totalon 0.
3. `#(0,0)` kaj `#(k,k)` sur ne-malplena listo estas precize nulaj.
4. `#(0,k)` egalas sendependan plenan sumon de la enigitaj specimenoj.
5. Ĉiu unu-elementa `#(i,i+1)` egalas la respektivan `sample.gap`.
6. Du sinsekvaj disaj fenestroj: sumo de rezultoj egalas la kunigitan fenestron.
7. Interkovrantaj, inversorde **listigitaj** fenestroj konservas enigan ordon.
8. Ripetitaj samaj fenestroj ne estas malduobligitaj.
9. Negativa `start` donas ĝustan `InvalidWindow` kun `k`.
10. `end>k` kaj `start>end` donas la **unuan** malvalidan fenestron, sen tondado.
11. Malvalida bovla ID kaj malvalida fenestro samtempe: Stage26/Stage25 `Upstream`-eraro havas prioritaton.
12. Ekstremaj pozitivaj/negativaj tagoj kaj negativaj validigaj buĝetoj: sama Stage25-eraro aŭ egala orakola sumo; almenaŭ unu senkulpa `reference/sauce` kontrolo se la 8-rifuza kondiĉo estas konfirmita.

Loku limigitajn specimenojn; ne aldonu novajn normajn kalendarajn regulojn, arbitrajn testajn por ĉiam validajn buĝetojn aŭ "expected red" sen pruvita historia kontraŭekzemplo.

## Same-SHA CI-pordegoj kaj stato

1. Kontrakta commit devas esti **atomika du-dosiera** ŝanĝo: ĉi tiu dokumento kaj `DEVELOPMENT_STAGE.md`, kun lasta kompletigita stadio 26. Por ĉi tiu kontrakta SHA postulu Native **286/286**, `gleam format --check src test`, kontrolon de fontintegreco kaj Names Lock SUCCESS sur la sama SHA.
2. Nur post tiuj `completed`-logoj efektivigu la unu novan Gleam-modulon, la 12 testojn kaj aktualan metadata en aparta koda commit. La **298** testoj estas antaŭdiro, **ne** jam mezurita Native-rezulto.
3. Dokumenta fermo kaj fina metadata devas esti apartaj commit-oj, ĉiu postulanta sam-SHA Native/Names pordegojn antaŭ ol Stage27 akcepteblas.
4. `queued` kaj `in_progress` estas nek PASS nek blokado. Neniu `main`-merge, publika eldono aŭ supozita kronologia jaro.

