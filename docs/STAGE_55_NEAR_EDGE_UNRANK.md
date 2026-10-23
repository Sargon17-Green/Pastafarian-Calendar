# Etap 55 — dokładny rank w pobliżu granic porządku

**Gałąź:** \`MATLAB+Polski\`. **Status:** eksperyment niezależny od produkcyjnego DAG.
Nie jest to asymptotyczne rozwiązanie dowolnej wewnętrznej rangi
i nie spełnia końcowej bramki \`normative_oracle\`.

## Znaczenie argumentów

\`pastafari.unrankWholeWeavingNearEdge(L,d,'first')\`
zwraca kompletne słowo leksykograficznej rangi **\`d+1\`**.

\`pastafari.unrankWholeWeavingNearEdge(L,d,'last')\`
zwraca kompletne słowo leksykograficznej rangi
**\`F(L)-d\`**, gdzie \`F(L)\` oznacza dokładną liczbę
wszystkich legalnych splotów. Nie trzeba liczyć
tej liczby w procedurze: porządek i liczba wykonanych
kroków definiują rangę.

\`d\` jest nieujemną dokładną liczbą całkowitą
reprezentowalną w \`double\`. Odległość dotyczy **liczby
legalnych pełnych słów**, a nie liczby dni i nie jest
przybliżeniem BigInt. W szczególności \`d=0\`
oznacza skrajne słowo. Jeśli rodzina ma za mało
słów, nie jest zwracana żadna fikcyjna ranga;
sygnalizowany jest \`Pastafari:NearEdge:OutOfRange\`.

## Dowód

Funkcja \`extremalWholeMonthWeavings\`, natywnie
porównana z enumeratorem, daje dokładnie rangi
\`1\` oraz \`F(L)\`. Funkcja
\`adjacentWholeMonthWeaving\` również została
natywnie zweryfikowana — dla legalnego pełnego słowa
zwraca dokładnie kolejny albo poprzedni element
porządku leksykograficznego, a nie tylko jakiś
większy lub mniejszy.

Indukcja po \`d\`:
- dla \`d=0\` wynik jest skrajnym słowem;
- jeśli po \`d\` krokach uzyskano słowo o randze
  \`d+1\` (\`F(L)-d\` od prawej), jeden dokładny
  krok następnika (poprzednika) daje słowo
  o randze \`d+2\` (\`F(L)-d-1\`).
- jeśli w danym miejscu sąsiad już nie istnieje,
  nie istnieje kolejna legalna ranga w tym kierunku.
  Procedura wykrywa brak sąsiada i **odrzuca**
  odległość zamiast zwracać część rozwiązania.

Żaden wielki licznik \`BigInt\` nie musi być wyznaczany
podczas tej operacji; jej poprawność korzysta z
dokładnego sąsiedztwa, a nie z przybliżenia \`F(L)\`.

Złożoność wynosi \`O(d*K*N)\` prostych operacji i
\`O(K+N)\` pamięci, dla \`K\` miesięcy i \`N\` dni.
Dlatego droga jest szybka blisko obu krańców i
nadal **niepraktyczna** dla wewnętrznych rang
oddalonych od obu krańców o wielką liczbę słów.
Nie należy mylić jej z rozwiązaniem ogólnego
problemu 6765-cyfrowego unranku.

## Weryfikacja

- \`src/+pastafari/unrankWholeWeavingNearEdge.m\`.
- \`tests/run_stage55_near_edge_tests.m\`.
- 120 małych rodzin: porównanie z dokładnym
  \`WholeMonthWeavingFamily.itemAt1\` dla
  dostępnych offsetów \`0..3\` od obu krańców.
- Rodzina \`[4 4 4]\`, liczność **1301**:
  wybrane offsety aż do \`1300\` od obu krańców,
  z porównaniem do historycznego DAG.
- Rzeczywisty wektor produkcyjnych 45 miesięcy
  i 4244 dni roku 5000: offsety
  \`0,1,2,7,31,127\` od obu krańców.
  Daje to **12 całych słów**, każde sprawdzane
  pod kątem liczności oraz poprawnego porządku
  pierwszych i ostatnich wystąpień.
- Odrzucanie zbyt dużego offsetu i argumentów
  o niecałkowitej lub ujemnej odległości.

[CI MATLAB R2026a — near-edge](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39965243451),
commit \`c1c1a7437b9360332ae0ad4cbb481cc1a271fdc3\`.

Do momentu uzyskania końcowego znacznika
\`STAGE_55_NEAR_EDGE_EXPERIMENTAL_PASS\`
nie wolno oznaczać tego testu jako natywny PASS.

**Nie scalać do \`main\`.** \`LAST_COMPLETED_STAGE=54\`,
\`STAGE_55_COMPLETE=NO\`, dopóki całe 4244-dniowe
wewnętrzne unrank i pełne sprawdzenie pięcioskładnikowej
daty nie przejdą niezależnego oracle.
