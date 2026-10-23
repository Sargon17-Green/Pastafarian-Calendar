# Etap 55 — dokładny leniwy wybór leksykograficzny

**Gałąź:** \`MATLAB+Polski\`.
**Status:** oddzielny eksperyment MATLAB R2026a, bez modyfikacji
\`WholeMonthWeavingFamily\`, \`finalMonsterIntegration\` lub \`main\`.
**Nie jest to formalny wynik Stage 55 ani pełne sprawdzenie
\`normative_oracle\`.**

## 1. Powód i definicja

W poprzedniej trasie \`unrankGeneralWeaveSuffixChunk\` liczyliśmy
\`F(R,o,c)\` raz dla całego prefiksu, a podczas pierwszego
rozgałęzienia dodatkowo uruchamialiśmy wspólny licznik
\`countWholeWeavingNextLetterBlocksOnePass\`, który obliczał
ponownie **tę samą całkowitą liczbę** przy okazji ustalania
dokładnych bloków następnej litery.

Nowa oddzielna funkcja
\`unrankGeneralWeaveSuffixChunkLazyJoint\` eliminuje to
pierwsze redundantne wywołanie. Każda legalna następna
litera należąca do stanu \`(R,o,c)\` ma dokładną
rodzinę dopełnień. Jeśli dokładnie jedna litera jest legalna,
dodanie jej przed każdym dopełnieniem jest bijekcją:
**liczba dopełnień oraz 1-indeksowany rank nie zmieniają się**.

Algorytm wykonuje kolejne wymuszone ruchy, ale nie zakłada
nigdy wartości rodzica zewnętrznego. Przy pierwszym rzeczywistym
rozgałęzieniu wykonuje dokładnie **jeden** wspólny DP:
\`\`\`matlab
[blocks, actual] = pastafari.countWholeWeavingNextLetterBlocksOnePass( ...
    R, openedUpTo, closedUpTo);
\`\`\`
\`actual\` to pełna liczność rodzica, a \`blocks{j}\` to
liczba jego legalnych dokończeń zaczynających się od \`j\`.
Sprawdzamy, że żądana ranga mieści się w tym przedziale.
Kolejno odejmujemy bloki poprzedzające leksykograficznie
wybrany blok, pozostawiając dokładny rank wewnątrz bloku.

Po wyborze zachowujemy jego pełną liczbę jako \`count\`.
Jeśli pojawi się dalsze rozgałęzienie, nowa liczba wspólnego
DP musi być **całkowicie równa** wcześniej zachowanemu
\`count\`. Tak wykrywamy rozbieżność bez dopuszczania
zaokrągleń. Przy najwyżej jednym nieotwartym miesiącu
dostępna jest osobno sprawdzona dokładna faktoryzacja
dwumianowa oraz bloki ze wspólnym mianownikiem.

Jeśli żądany fragment kończy się, zanim wystąpi pierwsze
rozgałęzienie (w tym \`maxSteps=0\`), liczymy dokładnie raz
liczność sufiksu po wymuszonych ruchach i dopiero wtedy
sprawdzamy range. Ta liczność jest równa pierwotnej na mocy
bijekcji. Żaden wynik ani kursor o nieweryfikowanej randze
nie jest zwracany.

## 2. Niezmienniki bezpieczeństwa

- \`0<=closedUpTo<=openedUpTo<=K\`; zamknięty prefiks ma
  dokładnie zero kopii, każdy otwarty-niezamknięty miesiąc
  ma między 1 a \`L(i)-1\` kopii, a nieotwarty dokładnie \`L(i)\`.
- Wszystkie długości i limity kroków to dokładne liczby
  całkowite. Rank i liczności to obiekty \`pastafari.BigInt\`.
- \`initialCount\` w kursorze to dokładna liczba dopełnień
  **stanu wejściowego danej funkcji**, a \`count\` to liczba
  dopełnień stanu po wykonanych krokach. W pierwszym
  wymuszonym prefiksie obie wartości muszą być takie same.
- \`done=true\` dopiero przy dokładnie \`K\` otwarciach,
  \`K\` zamknięciach i zerowych licznościach pozostałych
  kopii; wtedy \`rank=count=1\`.
- Kursor nie jest kryptograficznie uwierzytelnionym ani
  trwałym checkpointem. Przy oddzielnym wznowieniu nowa
  funkcja na nowo ustala liczność, zanim zwróci wynik.

## 3. Już zatwierdzone wyniki natywne

Commit \`e3c9cce9b91c4544545c5e87963fc9874f4f6624\`,
[GitHub Actions 39915045442](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39915045442):
**PASS w MATLAB R2026a**.

\`\`\`text
STAGE_55_LAZY_JOINT_BRUTE_PASS FAMILIES=9 RANK_CHECKS=532 SEGMENTS=2323
STAGE_55_LAZY_JOINT_VALIDATION_PASS
STAGE_55_LAZY_JOINT_BENCH DAYS=80 MONTHS=8 STEPS=3 RANK_CASE=1 SECONDS=0.101
STAGE_55_LAZY_JOINT_BENCH DAYS=80 MONTHS=8 STEPS=3 RANK_CASE=2 SECONDS=0.097
STAGE_55_LAZY_JOINT_BENCH DAYS=80 MONTHS=8 STEPS=3 RANK_CASE=3 SECONDS=0.092
STAGE_55_LAZY_JOINT_EXPERIMENTAL_PASS
\`\`\`

W testach porównano fragmenty, stany kursorów, liczności
i rangi z poprzednią trasą \`joint\` i całe złożone słowa
z niezależnym od nowego licznika produkcyjnym \`itemAt1\`
na małych rodzinach.

## 4. Zaplanowana kontrola dla rzeczywistego roku 5000

Commit \`bb8ad6a87488b8914655e34448c24e0119329047\`:
\`initialCount\` i oddzielny test dla prawdziwego wektora
45 miesięcy / 4244 dni. Rank \`10^6764\` jest dokładnym
wewnętrznym rangiem zgodnym z wcześniej udowodnioną
6765-cyfrową liczbą rodzica. Jedna wspólna rekurencja
ma ustalić dokładną pełną liczność oraz dwie pierwsze
litery (pierwszą wymuszoną i drugą rozgałęziającą).
Czytamy pełny wynik \`initialCount\`, sprawdzamy znane
48 pierwszych i 48 ostatnich cyfr z niezależnego wyniku
MATLAB, a także legalność kursora oraz 4242 dni
pozostałych. Same 96 cyfr nie zastępują równości
z niezależnym całym BigInt — ta była już sprawdzona
osobną parą algorytmów w
[39838926612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39838926612).

Oddzielna natywna bramka:
[39915436061](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39915436061).
**Nie uznawać za PASS bez faktycznego kompletnego logu.**

Dalszy problem to praktyczne wyznaczenie **każdej**
z 4244 liter dla ogólnej, nieekstremalnej rangi,
a następnie dokładne pełne pięcioelementowe
\`normative_oracle\`. \`LAST_COMPLETED_STAGE=54\`,
\`STAGE_55_COMPLETE=NO\`. Nie scalać do \`main\`.
