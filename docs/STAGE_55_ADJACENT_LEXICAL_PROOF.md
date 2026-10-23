# Etap 55 — dokładny następnik i poprzednik pełnego przeplotu

**Gałąź:** \`MATLAB+Polski\`.
**Zakres:** tylko lokalnie sąsiednie rangi istniejącego, kompletnego,
sprawdzonego słowa. Kod produkcyjny i \`main\` pozostają bez zmian.
Nie jest to dowolny rank/unrank ani zamknięcie Stage 55.

## 1. Warunek legalnego ruchu

Niech \`L(1)..L(K)\` będą dodatnimi licznościami kopii miesięcy.
Dla prefiksu niech \`R(i)\` oznacza liczbę kopii jeszcze
nieumieszczonych, \`o\` liczbę otwartych miesięcy i \`c\`
liczbę miesięcy już zamkniętych. Następną kopią miesiąca \`j\`
wolno przedłużyć prefiks wtedy i tylko wtedy, gdy:
- \`R(j)>0\`;
- jeżeli \`R(j)=L(j)\`, musi to być miesiąc \`o+1\`;
- jeżeli \`R(j)=1\`, musi to być miesiąc \`c+1\`.

Jest to dokładnie porządek pierwszych i ostatnich wystąpień.
Stan pozwala również na miesiące jednokopijne: ich jedyne
wystąpienie otwiera i zamyka miesiąc w tym samym ruchu.

### Każdy legalny krok ma dopełnienie

Po dowolnym lokalnie legalnym kroku dopisujemy wszystkie
pozostałe kopie miesięcy według rosnącego ID.
Ta konstrukcja otwiera jeszcze nieotwarte miesiące
w wymaganym porządku, a zamyka wszystkie w wymaganym
porządku. Zatem po każdym legalnym ruchu istnieje co
najmniej jedno poprawne kompletne słowo. Żaden kandydat
nie jest fałszywie dopuszczony przez brak dalszego rozwiązania.

## 2. Konstrukcja sąsiada

Przesuwamy punkt \`pivot\` od ostatniej pozycji ku pierwszej.
Odtwarzamy stan prefiksu kończącego się tuż przed \`pivot\`
przez cofanie po jednej aktualnej literze:
\`R(letter)++\`. Gdy po cofnięciu \`R(letter)=1\`,
cofamy zamknięcie; gdy \`R(letter)=L(letter)\`,
cofamy otwarcie. Dla miesiąca o długości 1 oba
cofnięcia zachodzą jednocześnie.

Następnik: w pierwszym znalezionym punkcie od prawej
wybieramy najbliższy większy niż oryginalny identyfikator
miesiąca, który jest lokalnie legalny. Wypełniamy
pozostały sufiks, zawsze wybierając najmniejszą legalną
następną literę. Dla poprzednika postępujemy symetrycznie:
najbliższy mniejszy identyfikator i następnie największe
legalne litery.

Dlaczego jest to **dokładnie** sąsiad? Wszystkie słowa
o wspólnym prefiksie do punktu bardziej na prawo leżą
leksykograficznie bliżej oryginału niż słowa różniące się
wcześniej. Dlatego wybieramy najbardziej prawy możliwy
pivot. W tym pivocie najmniejszy wzrost (lub największy
spadek) symbolu daje najbliższy zbiór słów, a
najmniejsze (lub największe) dopełnienie daje najbliższy
element tego zbioru. Istnienie dopełnienia jest zapewnione
przez poprzedni lemat. Pozycje, w których brak kandydata,
nie dopuszczają zmiany w danym kierunku.

Jeśli nie istnieje żaden pivot, badane słowo jest
globalnym maksimum lub minimum. Funkcja zwraca wówczas
\`exists=false\` i pusty sąsiad, nie sztuczną rangę.

Złożoność: walidacja pełnego słowa oraz ewentualny
greedy-sufiks wymagają \`O(K*N)\` operacji prostych na
małych licznikach i \`O(K+N)\` miejsca (łącznie z wynikiem).
Nie są budowane liczniki \`BigInt\` o tysiącach cyfr.

## 3. Sprawdzenia i pochodzenie

Niezależny prototyp JS porównano z pełnym rekurencyjnym
enumeratorem: **120 rodzin / 3940 legalnych słów**, każdy
następnik i poprzednik zgodny z najbliższym elementem
enumeracji. To nie jest samo w sobie natywne MATLAB CI.

Implementacja natywna:
\`src/+pastafari/adjacentWholeMonthWeaving.m\`.
Testy natywne:
\`tests/run_stage55_adjacent_weave_tests.m\`.

Testy MATLAB wymagają:
- 120 rodzin i porównania sąsiednich rang skrajnych
  z \`WholeMonthWeavingFamily.itemAt1\`;
- przejścia przez wszystkie 1301 rang rodziny \`[4 4 4]\`
  i sprawdzania odwracalności każdego kroku;
- sprawdzenia sześciu pełnych 4244-dniowych słów przy
  obu krańcach rodziny **rzeczywistych długości roku 5000**,
  w tym wszystkich liczności i porządku pierwszych i
  ostatnich wystąpień;
- sprawdzenia odrzucania nielegalnej liczności oraz
  naruszenia porządku ostatnich wystąpień.

Commit \`822342096ece59e7a91c2c05ab547e56de68efee\`;
[natywny GitHub Actions 39931324481](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39931324481).
**Natywny MATLAB R2026a — PASS**, z końcowych logów
run 39931324481, commit 822342096ece59e7a91c2c05ab547e56de68efee:

\`\`\`text
STAGE_55_ADJACENT_SMALL_DAG_PASS FAMILIES=120
STAGE_55_ADJACENT_ALL_1301_RANKS_PASS TRANSITIONS=1300
STAGE_55_REAL_YEAR_5000_ADJACENT_FULL_WORDS_PASS MONTHS=45 DAYS=4244 EXACT_EDGE_RANKS=6 SECONDS=0.016
STAGE_55_ADJACENT_EXPERIMENTAL_PASS
\`\`\`

Test rzeczywistych 4244-dniowych słów obejmuje dokładnie rangi
\`1, 2, 3, count-2, count-1, count\`; nie stanowi testu
wszystkich rang pośrednich ani pełnego normative oracle.

Nie wolno wyciągać wniosku o praktycznym obliczeniu
arbitralnej wewnętrznej rangi 6765-cyfrowej ani o
zgodności całego pięcioelementowego wyniku daty
z \`normative_oracle\`. Stage 55 pozostaje \`UNSEALED\`.
