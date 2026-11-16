# Stadio 30 — DISCOVERY 26: nombro de ne-malplenaj sinsekvaj fenestroj atingantaj sojlon

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj; LAST_COMPLETED_STAGE=29. **Nur mezurebla kontrakto; Stage30-produktkodo kaj Stage30 Native ankoraŭ ne ekzistas.**
Antaŭa akceptita branĉa HEAD: `23385ae6aafffee997dbc01e1f7f63aac330ebfc`. Native [43766933050](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43766933050), job `132974063249`, completed/success **322/322**, Gleam 1.18.1 / OTP 28, formatter/fontintegreco PASS; artefakto `14182895963`, SHA256 `67f6831d7dc2647123f317f1fe7dad7f355bec30adfccbef2f8fa911380819fa`. Names Lock [43766933034](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43766933034), job `132974063242`, completed/success sur la sama SHA. Ne faru novan Stage30-kodon antaŭ sam-SHA sukceso de la kontraktaj CI-pordegoj.

## Celo kaj elektita algoritmo

Stage29 trovas la *plej mallongan* kontiguan fenestron de la eksplicite petitaj pozitivaj interspacoj kun sumo almenaŭ sojlo. Stage30 mezuru malsaman sed komplementan kvanton: **kiom da ĉiuj ne-malplenaj kontiguaj fenestroj atingas ĉiun sojlon**. La ordo de petoj restu senŝanĝa; tio ne estas laŭkalendaraj pordegoj, jarkalkulo aŭ kompleta datkonverto.

Por `k` interspacoj `g_0,...,g_(k-1)`, kun `42 <= g_i <= 963`, fenestro estas duonmalfermita `[a,b)` kun `0 <= a < b <= k`. Difinu `S(a,b)=sum(g_i, a<=i<b)` kaj `C(t)=sum(1 kiam S(a,b)>=t por ĉiuj 0<=a<b<=k)`. La malplena fenestro `[a,a)` **neniam** estas kalkulata (malsame ol la Stage29-konvencio por `t<=0`).

- `k=0`: `C(t)=0` por ĉiu `t`.
- `t<=0`: ĉiuj ne-malplenaj fenestroj validas, do `C(t)=k*(k+1)/2`.
- `t>sum(g_i)`: `C(t)=0`.
- `t>0`: por ĉiu starto `a` trovu la minimuman ekskluzivan finon `r(a)` kies sumo estas almenaŭ `t`; tiam `k-r(a)+1` finaj pozicioj kvalifikiĝas. Se tia fino ne ekzistas, la posta pli granda starto ankaŭ ne havos solvon pro strikta pozitiveco. Ambaŭ montriloj moviĝas nur antaŭen: `O(k)` po sojlo.

## Preciza API, erarordo kaj limoj

- Produktmodulo: `src/pastafari/discovery_26_window_count.gleam`; testmodulo: `test/discovery_26_test.gleam`. Ne modifu la antaŭajn 322 testojn, produktmodulojn, referencajn orakolojn aŭ frostigitajn nomojn.
- Publika tipo: `ThresholdWindowCount(threshold: Int, qualifying_windows: Int)`.
- Publika funkcio:
  `dispatch_discovery_26(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), thresholds: List(Int)) -> Result(List(ThresholdWindowCount), discovery_19_interval_value.Discovery19Error)`.
- Alvoku `discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)` **precize unufoje**, antaŭ prilabori `thresholds`, ankaŭ kiam `thresholds=[]`. Propagu la originan `Error(error)` sen ŝanĝo. Validigo de ne-malplenaj petoj kaj kunteksto antaŭas negativajn, nulajn kaj malplenajn sojllistojn.
- Por sukcesa Stage26-voko, legu `batch.entries` kaj la pozitivajn `entry.sample.gap`; ne alvoku Stage25/26/29 aparte po sojlo. Antaŭe validigita Stage26-ordigo estas la sola produktdatumfonto.
- Responda listo konservas ekzakte ordon, nombron kaj multoblon de `thresholds`. Eĉ ripetitaj `requested_bowl_ids` okupas malsamajn poziciojn, sen ordigo aŭ deduplikigo.
- Malplena petolisto kun eĉ neuzata nevalida kunteksto sekvas la ekzistantan Stage26-konduton (sukceso). Ne-malplena nevalida petolisto/kunteksto propagas la saman eraron sendepende de `thresholds`.
- Produkta algoritmo: post unu Stage26-voko, `O(k*q + k)` tempo por `q` sojloj, `O(k+q)` ekstrema memoro. Uzu Gleam `Int` (BEAM arbitra precizeco) por sumoj kaj `k*(k+1)/2`; ne konvertu al i64/fiks-larĝa entjero. Neniu artefarita limo de ses petoj; neniuj nedeterminismaj aŭ senlimaj serĉoj.
- Valido ne postulas por ĉiu `t` saman minimuman fenestron kiel Stage29: `C(t)` inkluzivas **ĉiun** atingantan nemalplenan fenestron, ne nur optimumajn. Ne kopiu solvon el alia lingva branĉo.

## Sendependa oracle kaj invariantoj

La *testa* oracle rekte alvoku `discovery_21_gate_batch.dispatch_discovery_21(context, ids)`, legu `sample.gap`, kontrolu `42..963`, kaj **per du nestitaj limigitaj bukloj** enumeraciu ĉiujn `[a,b)` kun `a<b`. Por ĉiu fenestro akumulu la gap-sumon rekte kaj kalkulu `1` nur kiam `sum>=t`. Neniam alvoku Stage26, Stage29 aŭ produktan Stage30 por derivado de atendataj rezultoj. Komparu plenajn listojn `ThresholdWindowCount`, ne nur totalan nombron de respondoj.

Testaj invariantoj: `0<=C(t)<=k(k+1)/2`; se `t1<=t2`, `C(t1)>=C(t2)`; `C(t<=0)=k(k+1)/2`; `C(t>sum(gaps))=0`; `C(t)` entjera kaj neniam negativa. Ne supozu precizajn Stage25 gap-valorojn: derivu atendojn el la sendependa oracle.

### Precize 12 publikaj gleeunit-testoj

1. `([],[])` liveras `Ok([])`, sed Stage26 ankoraŭ alvokiĝas.
2. `ids=[]`, `thresholds=[-1,0,1]` kaj neuzata nevalida kunteksto: tri nuloj.
3. Unu valida peto: `gap-1`, `gap`, `gap+1` (limoj 1,1,0).
4. Pluraj petoj: `total`, `total+1`, `1`; ĝustaj mezuritaj valoroj kontraŭ oracle.
5. Interaj kaj ne-prefiksaj fenestroj: limaj sojloj derivitaj el internaj Stage25-gapoj.
6. Ripetitaj identaj bovloj: malsamaj pozicioj, fenestrokvanto kontraŭ oracle.
7. Neordigitaj kaj duplikataj sojloj: preciza revenordo kaj multoblo.
8. Negativaj kaj nula sojloj kun `k=4`: ĝuste `10` por ĉiu.
9. Preciza suma limo de unu- kaj du-elementa fenestro, kaj plus-unu limoj.
10. Nevalida bovlo propagas originan Stage26-eraron eĉ ĉe `thresholds=[]`.
11. Nevalida ne-malplena kunteksto propagas originan eraron antaŭ `t<=0`.
12. Grandaj pozitivaj/negativaj tagoj, grandegaj `Int`-sojloj, ripetaj petoj, malgranda limigita oracle; testu ankaŭ monotonecon kaj suprajn limojn.

## Sendependa aritmetika preflight (ne Gleam Native)

Elĉerpe provitaj **364** sintezaj listoj de longo `0..5`, ĉiu elemento el `{42,43,963}`, kontraŭ **12** sojloj `{-10000,-1,0,1,42,43,84,85,963,964,1926,10000}`. Ĉiu el la **4,368** komparoj inter du-montrila kalkulo kaj rekta nesta enumeracio egalis; **0 diferencoj**. Ĉi tio ne asertas la ekzekuton de Gleam-testoj aŭ realaj Stage25-specimenoj.

Reproduktebla Python 3-preflight (sendependa de la Gleam-fonto):

```python
from itertools import product

def optimized(g, t):
    k = len(g)
    if t <= 0:
        return k * (k + 1) // 2
    right = 0
    total = 0
    count = 0
    for left in range(k):
        while right < k and total < t:
            total += g[right]
            right += 1
        if total < t:
            break
        count += k - right + 1
        total -= g[left]
    return count

def independent(g, t):
    count = 0
    for left in range(len(g)):
        total = 0
        for right in range(left, len(g)):
            total += g[right]
            if total >= t:
                count += 1
    return count

thresholds = (-10000, -1, 0, 1, 42, 43, 84, 85, 963, 964, 1926, 10000)
checked = 0
for size in range(6):
    for gaps in product((42, 43, 963), repeat=size):
        for threshold in thresholds:
            assert optimized(gaps, threshold) == independent(gaps, threshold)
            checked += 1
assert checked == 4368
print("4368 comparisons; 0 mismatches")
```

## Akceptaj pordegoj (ĉiu en aparta branĉa HEAD)

1. **Kontrakto**: nur `STAGE30_DISCOVERY26_CONTRACT.md` + `DEVELOPMENT_STAGE.md`; Native `322/322` kun Gleam 1.18.1/OTP28, `gleam format --check`, fontintegreco, kaj sam-SHA Canonical Names Lock SUCCESS. Antaŭ tiuj completed/job-log-pruvoj kontrakto estas **pending**, ne PASS.
2. **Kodo**: nur post kontrakta akcepto; nova produktmodulo + precize 12 novaj publikaj `*_test` + metadata; antaŭ sam-SHA Native `334/334` kaj Names SUCCESS tiu nombro estas **nur prognozo**.
3. **Dokumenta fermo**: aparta commit post kodaj sam-SHA sukcesoj; ĝi bezonas proprajn sam-SHA Native `334/334` kaj Names SUCCESS.
4. **Fina metadata**: aparta commit post dokumentaj sukcesoj, poste propraj sam-SHA `334/334` kaj Names SUCCESS antaŭ definitive `LAST_COMPLETED_STAGE=30`.
5. `queued/in_progress` estas nek PASS nek blokado. Neniu mana duobla CI-dispatch, neniu `main`, merge aŭ publikigo. La 55-stadia programo daŭras.

