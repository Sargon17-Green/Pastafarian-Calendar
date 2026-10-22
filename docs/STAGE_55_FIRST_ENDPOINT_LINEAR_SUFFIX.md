# Etap 55: dokładny licznik jednokońcowy legalnych przeplotów

**Gałąź:** `MATLAB+Polski`
**Stan:** odrębny eksperyment; nie zastępuje produkcji ani niezależnego oracle.
**Konieczna bramka końcowa:** `STAGE_55_FINAL_AUDIT_PASS` — **jeszcze nieosiągnięta**.

## Obserwacja matematyczna

W każdym legalnym słowie złożonym z miesięcy 1..i ostatnie
wystąpienia muszą być uporządkowane rosnąco. Stąd **ostatnim symbolem
całego słowa musi być i**. Pozycja ostatniego wystąpienia miesiąca i
nie jest zatem zmienną dynamiczną: wynosi dokładnie
`N_i = m_1+...+m_i`. Wcześniejsza tablica stanów
`DP_i(first,last)` zawiera drugi wymiar o jednej jedynej dopuszczalnej
wartości `last=N_i`.

Niech `F_i(p)` będzie dokładną liczbą legalnych słów, w których
pierwsze wystąpienie największego miesiąca i następuje w pozycji p.
`T_i=\sum_p F_i(p)` i
`P_i(p)=\sum_{f\le p}F_i(f)` oznaczają liczbę wszystkich słów
i rozkład skumulowany pierwszej pozycji. Liczności wszystkich
miesięcy są znane i dodatnie.

### Gdy m_i jest co najmniej 2

Nowo dodawany miesiąc i pojawia się najpierw w pozycji p,
a po raz ostatni w pozycji `N_i`. Pozostałe `m_i-2` identyczne
kopie wybiera się dokładnie z `N_i-p-1` wewnętrznych pozycji.
Liczba możliwości wynosi:

```text
F_i(p) = C(N_i-p-1, m_i-2) * E_(i-1)(p)
```

Jeżeli miesiąc i musi dopiero otworzyć się we właściwej kolejności
(`monthID > openedUpTo+1`), to pierwszy symbol największego
wcześniejszego miesiąca musi już wystąpić przed p, więc
`E_(i-1)(p)=P_(i-1)(p-1)`.

W przeciwnym razie (miesiąc i już był otwarty w prefiksie
albo stanowi pierwszy jeszcze nieotwarty miesiąc)
**nie istnieje ograniczenie nowego pierwszego wystąpienia**, więc
`E_(i-1)(p)=T_(i-1)`.

Oba przypadki ściśle zachowują wszystkie legalne słowa i ich liczby.
Pozycje p mieszczą się w `1..N_(i-1)+1`, a dla m_i=1 jedyna
kopia jest jednocześnie pierwszą i ostatnią:
`F_i(N_i)=T_(i-1)`. Przypadek bazowy jednego miesiąca to
dokładnie jedno słowo z `F_1(1)=1`.

### Pamięć i arytmetyka

Do policzenia nowej tablicy `F_i` wystarczają wyłącznie
`P_(i-1)`, `T_(i-1)` i dokładne współczynniki dwumianowe.
Nie przechowujemy wcześniejszych warstw ani pozycji ostatniego
wystąpienia. W danej chwili przetrzymywane są co najwyżej
kilka wektorów o długości proporcjonalnej do liczby
pozostałych dni, czyli **O(N) obiektów BigInt**.

Współczynniki dwumianowe wyliczane są rekurencyjnie za pomocą
`floorDivMod`. Pozostała część nigdy nie może być różna
od zera. Nie ma liczenia na `double` ani odrzucania stanów.

## Dowody i wynik eksperymentów

1. Istniejący algorytm `countWholeWeavingSuffixByEndpoints`
   i niezależny automat legalnych kolejnych liter zostały
   porównane na **6651 osiągalnych stanach** pochodzących
   z 363 małych wektorów miesięcy 1..5, długości 1..3:
   niezależna walidacja konstrukcji w JS 6651/6651 PASS.
   **Nie jest to jeszcze natywny wynik MATLAB dla nowego
   algorytmu**.
2. Natywny, wcześniej zatwierdzony algorytm Wavefront obliczył
   **wszystkie** legalne słowa dla syntetycznego
   `[108, 94, ..., 94]` (45 miesięcy, 4244 dni) w 146.407 s.
   [Run 39772586987](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39772586987),
   commit `16f2ff5d18ae0449504c2b14472078e525389ef4`:
   `STAGE_55_PREOPEN_4244_FULL_COUNT_PASS`,
   dokładnie **6844 cyfry**.
   Pierwsze 48 cyfr:
   `274324460241386716639660134170726950620695177088`;
   ostatnie 48:
   `924885822253633097338430639126334493274345601640`.
   Te dwa fragmenty są wskaźnikami w logu, **nie hashem** całej
   wartości.
3. Nowy niezależny licznik:
   `src/+pastafari/countWholeWeavingSuffixByFirstEndpoint.m`,
   commit `fb72867f1c98f7c5a53c895a134118b8c102ef01`.
   Dokładne sprawdzenia Native R2026a:
   - `STAGE_55_FIRST_ENDPOINT_EXHAUSTIVE_PASS`;
   - `STAGE_55_FIRST_ENDPOINT_4244_EXACT_PASS`;
   - `STAGE_55_FIRST_ENDPOINT_EXPERIMENTAL_PASS`.
   **Nie ogłaszać PASS, dopóki te markery nie pojawią się w logu**.
4. Rozszerzony test `9e77e00b31e931d7c21fb61e38e84af28caf97cd`
   wymaga **pełnej równości BigInt**, a nie tylko zbieżności
   fragmentów liczby, dla całego syntetycznego roku 4244 dni
   liczonych zarówno jednowymiarowym licznikiem, jak i
   wcześniej zatwierdzonym Wavefront.
   [Run 39773820740](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39773820740):
   przy opracowaniu dokumentu wynik Native był jeszcze
   nierozstrzygnięty.

## Dalsze prace i granice ukończenia

Dokładna, szybka liczba wszystkich przeplotów jest warunkiem
koniecznym, ale nie wystarczającym dla produkcyjnej konwersji
daty. Nadal trzeba zbudować **dokładny i wydajny rank/unrank**
dla dowolnego prefiksu (w szczególności, gdy kilka miesięcy
już otwarto, a kilka jeszcze nie), zachować kolejność
leksykograficzną i niezależnie sprawdzić produkcyjny wektor
długości miesięcy roku 5000 oraz wszystkie pola kanonicznej
daty. Finalny Stage 54 differential musi dotrzeć do
`normative_oracle` i porównać kompletne krotki.
Syntetyczny benchmark 4244 dni nie zastępuje tej czynności.

Do zakończenia wszystkich wyżej wymienionych etapów:
`LAST_COMPLETED_STAGE=54`, `STAGE_55_COMPLETE=NO`.
Nigdy nie scalać do `main`.
