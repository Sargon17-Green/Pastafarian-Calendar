# Etap 55 — dokładny unrank prefiksów w dowolnym stanie

**Repo:** Sargon17-Green/Pastafarian-Calendar
**Branch:** \`MATLAB+Polski\`
**Status:** eksperymentalny algorytm kontrolny, NIE produkcyjny Stage 55 PASS.

## 1. Stan wejścia i poprawność

Stan zapisuje oryginalne długości \`L\`, liczniki pozostałych
wystąpień \`R\`, indeks ostatniego otwartego miesiąca \`o\`,
ostatniego zamkniętego miesiąca \`c\`, i dokładny rank od 1.

Niezmienniki: \`0<=c<=o<=K\`; wszystkie \`R(1:c)=0\`;
dla wcześniej otwartych ale niezamkniętych miesięcy
\`0<R(c+1:o)<L(c+1:o)\`; dla jeszcze nieotwartych
\`R(o+1:K)=L(o+1:K)\`. Każdy element \`R\` jest liczbą całkowitą
reprezentowalną dokładnie. Nie akceptujemy sprzeczności licznika
z historią prefiksu.

W każdym kroku dokładnie jeden miesiąc i może być wybrany, jeśli
ma pozostałe wystąpienia, jego pierwsze otwarcie następuje wyłącznie
dla \`i=o+1\`, a ostatnie wystąpienie wyłącznie dla \`i=c+1\`.
Kandydaci są rozpatrywani rosnąco, więc wynik jest leksykograficzny.

Dla dowolnego poprawnego dziecka \`u\`, dokładna liczba pełnych słów
zaczynających się od \`u\` równa się
\`countWholeWeavingSuffixByFirstEndpoint(R_child,o_child,c_child)\`
(o ile miesiące nie są już wszystkie otwarte; potem dopuszczalny
jest osobno zweryfikowany wariant algebraiczny).
Bloki dzieci tworzą rozłączny, zupełny podział wszystkich słów
rodzica. Wybór bloku według rank i odjęcie poprzednich bloków
nie traci ani nie przybliża żadnego słowa.

## 2. Redukcja dla wyboru wymuszonego

Gdy rodzic ma dokładnie **jedno** legalne następne wystąpienie \`u\`,
mapowanie \`w -> uw\` jest bijekcją między wszystkimi legalnymi
dokończeniami dziecka i rodzica. Liczba dokończeń i względny rank
nie zmieniają się. Zatem dla takiego kroku bezpiecznie przypisujemy
\`childCount=parentCount\`, bez ponownego uruchamiania licznika.

Nie oznacza to skrócenia całkowitego słowa, pominięcia trudnego dnia,
ani zaakceptowania częściowego wyniku. Licznik \`stepsComputed\`,
\`remaining\`, \`rank\`, \`count\`, \`openedUpTo\`, \`closedUpTo\`
i \`done\` są zapisywane jawnie. Zapis do nietrwałej struktury MATLAB
nie jest jeszcze sprawdzonym, trwałym checkpointem pomiędzy jobami CI.

## 3. Faktycznie zakończone testy natywne

Commit \`a9fcd55ae9e5bea952f0c30ed20b7205d07ebd1d\`,
[MATLAB R2026a run 39784828233](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39784828233):
**PASS**, z logu:
- \`STAGE_55_GENERAL_CHUNK_BRUTE_PASS FAMILIES=10 RANK_CHECKS=640 SEGMENTS=2832 PARTIAL=1056 ALL_OPEN=1776\`.
- \`STAGE_55_GENERAL_CHUNK_VALIDATION_PASS\`.
- \`STAGE_55_GENERAL_CHUNK_PREOPEN_BENCH DAYS=80 MONTHS=8 STEPS=3 SECONDS=0.236 RESULT=[1 2 3]\`.
- \`STAGE_55_GENERAL_CHUNK_EXPERIMENTAL_PASS\`.

Testy wszystkich tych małych prefiksów porównały wynik po
ponownym łączeniu podzielonych fragmentów z niezależnym
rekurencyjnym wyliczeniem słów i starym produkcyjnym DAG.

## 4. Rozpoczęte kolejne bramki

Commit \`5257fe1101ea646528f8ef0613a95e57f1c6010a\`
zawiera szybszy wybór wymuszony oraz osobny duży test pierwszej
litery dla syntetycznego roku 45 miesięcy / 4244 dni.
- Pełna mała regresja:
  [39785576314](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39785576314).
- Pełnowymiarowy test syntetyczny:
  [39785576435](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39785576435).
- Nie należy uznać żadnego z tych dwóch testów za PASS
  bez odczytania całych końcowych markerów z ich logów.

Pełnowymiarowy test sprawdza wybrany środkowy dokładny rank, jego
niezmienność przy pierwszym wymuszonym miesiącu oraz 6844 cyfr
liczności rodziny, zgodnie z osobno porównanymi metodami
jedno- i dwukońcową. Nie jest to równoważne wydajnemu unrank
wszystkich 4244 dni.

## 5. Otwarty problem wydajności i bramka końcowa

Dla wielu legalnych kolejnych miesięcy prototyp liczy ich bloki
ponownie od początku za pomocą \`BigInt\`.
To metoda dokładna, ale nie udowodniono jej praktycznej wydajności
dla całego roku produkcyjnego. Następny projekt powinien wyprowadzić
liczniki bloków z jednego wspólnego przejścia DP lub innego
równoważnego, exact-rank zachowującego wzoru, a następnie wykazać
pełną równoważność z enumeracją małych rodzin i niezależnym oracle.

**Bez zmian w \`main\` i produkcyjnym \`WholeMonthWeavingFamily\`.**
Dopóki brak natywnego porównania kompletnej daty i
\`STAGE_54_HEAVY_DIFFERENTIAL_PASS\`,
\`STAGE_55_FINAL_AUDIT_PASS\` pozostaje nieosiągnięty.
