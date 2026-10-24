# Etap 55 — przedzial dokladnych rang prefiksu po otwarciu miesiecy

**Gałąź:** \`MATLAB+Polski\`. **Status:** eksperyment. Bez zmian
w \`main\`, \`WholeMonthWeavingFamily\` i \`normative_oracle\`.
Nie stanowi zamkniecia Stage 55.

## Kontrakt

Dla legalnego stanu, w ktorym WSZYSTKIE miesiace sa juz otwarte,
dowolny legalny prefiks \`p\` definiuje jeden spojny przedzial
dokladnych rang leksykograficznych:

- \`firstRank(p)\` — najmniejsza ranga legalnego dopelnienia;
- \`lastRank(p)\` — najwieksza taka ranga;
- \`lastRank-firstRank+1\` — dokladna liczba wszystkich dopelnien.

Pusty prefiks identyfikuje pelna rodzine \`[1,F(R)]\`.
Prefiks pelnego slowa ma \`firstRank=lastRank\`. Wszystkie
rangi i liczby dopelnien sa \`pastafari.BigInt\`;
nie stosujemy operacji zmiennoprzecinkowych na licznikach.

## Dowod indukcyjny

W kazdym stanie \`S\` legalne pierwsze litery \`i\` dziela
zbior wszystkich dopelnien na rozlaczne bloki
\`B_i=F(child(S,i))\`. W porzadku leksykograficznym
bloki nastepuja po sobie rosnaco wedlug identyfikatora
miesiaca. Dla wybranej litery \`j\` aktualizujemy:
\`start := start + SUM_{i<j} B_i\`;
\`S := child(S,j)\`;
\`count := B_j\`.
Poczatkowo \`start=1\`. Po kazdej iteracji przedzial
legalnych dopelnien prefiksu jest dokładnie
\`[start,start+count-1]\`.
Nielegalna litera, w szczegolnosci zamkniecie miesiaca
poza porzadkiem, jest jawnie odrzucana.

Uzywany jest jeden z dwoch zweryfikowanych
algebraicznych licznikow blokow:
\`allOpenedWholeWeaveChildCountsCommonDenominator\`
albo \`allOpenedWholeWeaveChildCounts\` (\`rational\`).
Sa matematycznie rownowazne, ale implementacyjnie rozne.
Nie oznacza to niezaleznego pelnego oracle dla calego
kalendarza.

## Natywne kryteria weryfikacji

Pliki:
\`src/+pastafari/rankAllOpenedWeavePrefix.m\`
i \`tests/run_stage55_all_open_prefix_rank_tests.m\`.

- 9 malych rodzin: niezalezna rekurencyjna enumeracja
  wszystkich legalnych slow w kolejnosci leksykograficznej.
  Kazdy prefiks, wraz z pustym i pelnym, porownany
  w dwoch metodach liczenia. Lacznie **3322 testy przedzialu**.
- Kazdy przedzial musi byc spojny; jego szerokosc ma
  rownac sie liczbie dopelnien. Testy blednych ID,
  limitow i przedwczesnego zamkniecia musza przejsc.
- Rzeczywisty rok 5000: wektor 45 miesiecy / 4244 dni,
  ale do eksperymentu wziety stan \`R=L-1\`, czyli
  **4199 pozostalych dni po otwarciu wszystkich miesiecy**.
  Oddzielny unrank dokladnej rangi srodkowej daje
  96 liter. Inna metoda wyznacza przedzial ich rang.
  Sprawdzamy pelne rownania BigInt:
  \`lo<=rank<=hi\`,
  \`rank-lo+1=residualRank\`,
  \`hi-lo+1=residualCount\`.
  Pozostale liczby wystapien i indeks ostatniego
  zamknietego miesiaca musza byc identyczne.

[MATLAB R2026a: native CI 39982128692](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39982128692),
commit \`e16bbc9d0afaf244ae561f7015cc8f81ced02529\`.
Natywny MATLAB R2026a **PASS**, potwierdzony w logach
[run 39982128692](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39982128692):

- `STAGE_55_ALL_OPEN_PREFIX_RANK_BRUTE_PASS FAMILIES=9 INTERVAL_CHECKS=3322`
- `STAGE_55_ALL_OPEN_PREFIX_RANK_VALIDATION_PASS`
- `STAGE_55_REAL_YEAR_ALL_OPEN_PREFIX_INVERSE_PASS MONTHS=45 DAYS=4199 STEPS=96 DIGITS=6745 UNRANK_SECONDS=27.403 INVERSE_SECONDS=217.798`
- `STAGE_55_ALL_OPEN_PREFIX_RANK_EXPERIMENTAL_PASS`.

## Ograniczenia

Nie rozwiazuje otwierania miesiecy w poczatkowej,
4244-dniowej rodzinie, nie dowodzi wydajnego
szybkiego unranku dla kazdej wewnetrznej rangi
i nie zastępuje niezaleznego \`normative_oracle\`.
\`LAST_COMPLETED_STAGE=54\`,
\`STAGE_55_COMPLETE=NO\`. **Nie scalac do main.**
