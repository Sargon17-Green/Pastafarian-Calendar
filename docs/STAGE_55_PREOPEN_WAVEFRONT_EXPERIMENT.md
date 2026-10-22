# Etap 55 — dokładne obliczanie wszystkich nieotwartych miesięcy metodą fali

**Status:** eksperyment, bez zamknięcia natywnego audytu Stage 55.
**Gałąź:** `MATLAB+Polski`; nie należy zmieniać `main`.
**Pierwszy commit:** `849fd92e69ce03495d3d88bf6df0d371ea79be67`.
**Remediacja kosztu testowego oracle:** `fdefc922564468e803c5a975b077426ed5f2123d`.

## Co dokładnie liczymy

Weźmy dodatnie długości miesięcy `m_1,…,m_K`.
Miesiące początkowo nie są otwarte. Każde słowo zawiera dokładnie
`m_i` kopii symbolu miesiąca `i`. Pierwsze wystąpienia miesięcy
muszą wystąpić w kolejności rosnącej `1..K`; ostatnie wystąpienia
również w kolejności rosnącej `1..K`. Nie usuwamy ani nie przybliżamy
żadnego poprawnego słowa.

Niech `N_i=m_1+...+m_i`. Definiujemy `D_i(p,q)` jako liczbę
poprawnych słów na miesiącach `1..i`, w których pierwsze wystąpienie
największego miesiąca zajmuje pozycję `p`, a ostatnie pozycję `q`.
Niech `P_i(p,q)` będzie sumą `D_i(f,l)` dla wszystkich `f<=p`
i `l<=q`. Wszystkie wyniki są pełnymi obiektami `pastafari.BigInt`.

Dla `i>1` i `m_i>=2`:

```text
D_i(p,q) = C(q-p-1, m_i-2) * P_(i-1)(p-1, q-m_i)
P_i(p,q) = P_i(p-1,q) + SUM_{v<=q} D_i(p,v)
```

Warunek `p-1` zachowuje porządek pierwszych wystąpień; argument
`q-m_i` zachowuje porządek ostatnich wystąpień. Współczynnik
dwumianowy wybiera dokładnie pozycje `m_i-2` kopii wewnętrznych.
Dla `m_i=1` jedyna kopia zajmuje `p=q`; wtedy
`D_i(p,p)=P_(i-1)(p-1,p-1)`.
Warunek bazowy dla `i=1`: jedno słowo `1^{m_1}`.

## Redukcja pamięci bez redukcji obliczenia

Wszystkie wartości `P_i(p,q)` przy ustalonym `p` wymagają tylko
`P_i(p-1,q)` oraz `P_(i-1)(p-1,q-m_i)`. Gdy iterujemy po `p`
rosnąco, możemy zachować jedynie **poprzedni wiersz każdego i**.
Bieżące wiersze powstają z poprzedniego stanu, a następnie
atomowo zastępują poprzednie wiersze. Suma po `v<=q` jest
akumulowana inkrementalnie w obrębie wiersza. Współczynniki
dwumianowe preliczymy dokładnie i bez przeliczania wartości
zmiennoprzecinkowych na liczby całkowite.

Przy tym samym `K=45`, `m_i=94`, `N_K=4230`, hipotetyczne
**pełne kwadratowe siatki** dla wszystkich prefiksów mają
277 600 845 pól, podczas gdy przechowywane wiersze o indeksach
`q=0..N_i` mają 97 335 pól; różnica w liczbie pól wynosi
około **2852 razy**. Są to liczby komórek indeksowych, a nie
pomiar faktycznie zajętych bajtów i nie ekstrapolacja wydajności
uruchomienia produkcyjnego. Utrzymujemy jeszcze wiersze bieżące i
preliczone współczynniki. Złożoność pamięci roboczej względem
`N_i` pozostaje liniowa, `O(SUM N_i)`, a liczba operacji
`BigInt` pozostaje kwadratowa, `O(SUM N_i^2)`.
Nie ma gwarancji, że czas roku 4244 dni będzie akceptowalny.

## Niezależność i bramki testowe

- Prototyp recyrkulacji w JS porównano z niezależną rekurencją
  legalnych kolejnych miesięcy na wszystkich 363 wektorach
  dodatnich długości 1..3 i 1..5 miesięcy; **363/363 zgodne**.
  To nie jest dowód natywnego MATLAB PASS.
- `tests/run_stage55_preopen_wavefront_tests.m` porównuje
  wynik fali jednocześnie z `countWholeWeavingSuffixByEndpoints`
  i z niezależną rekurencją legalnych przejść, z memoizacją
  identycznych stanów (bez pomijania poprawnych słów).
- Dodatkowe pełne testy liczą 30, 80 i 120 dni, mierzą
  czas i sprawdzają dokładną wartość `BigInt` z poprzednim
  licznikiem.
- Oddzielny workflow:
  `MATLAB Pre-open Wavefront Exact Counter (Experiment)`,
  [run 39765218587](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39765218587),
  wymaga dokładnych markerów
  `STAGE_55_PREOPEN_WAVEFRONT_EXHAUSTIVE_PASS` i
  `STAGE_55_PREOPEN_WAVEFRONT_EXPERIMENTAL_PASS`.
  Run pozostawał w kolejce przy opracowaniu dokumentu:
  **nie ogłaszamy natywnego PASS przed odczytaniem logu**.
- Wcześniejsze osobne workflow
  [39762862661](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39762862661)
  dla 160, 240, 320 dni początkowo nieotwartych miesięcy również
  musi otrzymać pełne wyniki. Nie wolno zastępować wyniku
  przypadkiem, w którym wszystkie miesiące już otwarto.

## Otwarte ograniczenia

Algorytm fali dotyczy wyłącznie zera otwartych miesięcy.
Stan z częściowo otwartymi miesiącami wymaga innego warunku bazowego.
Żaden wiersz jest nie zapisywany trwale między odrębnymi uruchomieniami;
nie istnieje jeszcze zweryfikowany mechanizm checkpointów pomiędzy
wyłączonymi runnerami. W żadnym z etapów nie wolno poświadczyć
`STAGE_54_HEAVY_DIFFERENTIAL_PASS`, ani
`STAGE_55_FINAL_AUDIT_PASS` przed zakończeniem całego obliczenia
produkcji i niezależnego `normative_oracle`.

**Wynik:** zmniejszamy wymaganą pamięć, ale jeszcze nie wykazaliśmy
praktycznego czasu pełnego roku oraz nie integrujemy nowego
licznika z `WholeMonthWeavingFamily`.
