# Etap 55 — dokładna rodzina wielomianowa i usunięcie bariery DAG

**Gałąź:** `MATLAB+Polski` · **stan:** Stage 55 otwarty, ostatni ukończony 54. 
**Weryfikowany HEAD przed aktualizacją:** `1180f4216fcfcd5dbb2962f9d0c525a23ec2c3df` (2026-10-28).
**Klasyfikacja:** plan naprawy i protokół akceptacji, nie deklaracja zakończenia Stage 55.

## Ustalone dowody natywne

- [MATLAB Stage 55 Native Audit, run 40488525486](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40488525486) zakończył się niepowodzeniem. W dzienniku: rzeczywiste długości 45 miesięcy, 4244 dni, `STAGE_54_WEAVE_DP_FORWARD DAY=16 STATES=32768`; następnie komunikat `runner has received a shutdown signal`. **Nie** ma dowodu błędu rachunkowego, nie wolno nazywać tego OOM bez pomiaru RAM.
- [Small-family equivalence, run 40280041449](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40280041449): zakończony `success` w natywnym MATLAB. Test porównuje `WholeMonthWeavingFamily` z `WholeMonthWeavingFamilyPolynomial` dla wszystkich rang dziewięciu małych rodzin, łącznie z częściowymi prefiksami.
- [Full real-year four edge ranks, run 40280041350](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40280041350): `success`; sprawdza pełne słowa 4244-dniowe dla rang `1,2,F-1,F`, bez dowodzenia rang wewnętrznych.
- [256 real-year edge words, run 40280041328](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40280041328): `success`; pierwsze i ostatnie 128 pełnych słów, dokładna kolejność, wielokrotności i świadkowie momentów.
- [BigInt subtraction, run 40673798921](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40673798921): `success`, MATLAB R2026a Update 5, 2 Passed / 0 Failed. Zapis trwały: [oryginalny ZIP dziennika](https://drive.google.com/file/d/177E4fF3lH2MWE3QtXNqGnILnQcdFm5gf/view).

Wyniki z innych commitów świadczą o testowanych niezmienionych plikach w danej rewizji; przy każdej zmianie dotykającej ich zależności wymagane jest ponowne sprawdzenie zakresu zależnego. `STAGE_55_FINAL_AUDIT_PASS`, pełny niezależny Oracle i cross-engine Soak **nie** uzyskały PASS.

## Diagnoza algorytmiczna

`src/+pastafari/MonthWeavingDPPatchWrapper.m` konstruuje `WholeMonthWeavingFamily(monthLengths)` **przed** wyborem rangi. Konstruktor `WholeMonthWeavingFamily` materializuje każdy osiągalny wektor `remaining`, wszystkie warstwy dzienne oraz mapę `completionCounts` (zob. `buildExactStateDP`). Oracle w `tests/oracle/normative_oracle.m` ma osobny rekurencyjny memoizowany `makeWeavingFamily`, również oparty na wektorze `remaining`. Obydwa są nieograniczone w liczbie stanów; serializacja ich bieżącej warstwy **nie** ograniczy rozmiaru całkowitej przestrzeni stanów.

Istniejące `countWholeWeavingSuffixByFirstEndpoint` liczy dokładną liczność, przechowując wektory BigInt o długości zależnej od liczby pozostałych dni, bez pełnego DAG. `WholeMonthWeavingFamilyPolynomial` zapewnia tę liczność i ścieżki `itemAt1` / `prefixAt1`. Zakres pamięci licznika jest wielomianowy (w liczbie komórek), ale koszt czasu i pamięci wielkich liczb dla **dowolnej wewnętrznej rangi 4244-dniowej** nadal musi być zmierzony. Cztery rangi brzegowe i okna brzegowe nie certyfikują przypadku środkowego.

## Działanie naprawcze — bez podwójnego prototypu

1. **Testowy kontrakt zamienności**: wykorzystać istniejący `tests/run_stage55_polynomial_family_equivalence_tests.m`, bez pisania nowego algorytmu. Po zmianie istniejących liczników powtórzyć wszystkie małe rodziny i granice BigInt; nie rozszerzać wyników PASS poza zbadane dziedziny.
2. **Dokładny środek roku 5000**: dla rzeczywistego `L` i rangi wybieranej przez `GeneralSelectionCompatibilityRoute` uruchamiać istniejący `unrankGeneralWeaveSuffixChunkAdjoint` fragmentami, nie pełne `itemAt1` w jednym nieograniczonym wywołaniu. Każdy fragment ma mieć jawny limit liczby dni i limit czasu procesu; sprawdzać `count`, `rank`, `remaining`, `openedUpTo`, `closedUpTo`, sumę długości oraz poprawność prefiksu. Zapisywać `serializeExactWeaveCursorJson` **po** udanym fragmencie do trwałego artefaktu. Następny proces ma przywrócić checkpoint przez `restoreExactWeaveCursorJson`, który ponownie dokładnie liczy suffix. Nie ignorować kosztu tego odtworzenia.
3. **Nieodwracalny commit semantyczny dopiero po walidacji**: na produkcyjnej trasie planowana zamiana dotyczy **obu** wywołań (licznik przed wyborem rangi i sam unrank); podmiana samego unrank pozostawia ekspansję DAG w konstruktorze. Zachować kolejność `LegacyMonthWeavingAdapter` → `GeneralSelectionCompatibilityRoute` → dokładny wynik, 26 historycznych śladów i pięć pól daty; bez przybliżenia BigInt.
4. **Niezależność Oracle**: nie podłączać `normative_oracle` do produkcyjnego `WholeMonthWeavingFamilyPolynomial` i nie przedstawiać zgodności dwóch wywołań tego samego licznika jako niezależnego dowodu. Oryginalny Oracle pozostawić dla pełnej enumeracji małych rodzin; dla pełnego roku trzeba przygotować osobno udowodnioną metodę kontrolną lub zestaw niezależnych certyfikatów rang, przed zatwierdzeniem całego pięciopolowego differential. To nadal otwarta zależność, a nie wykonana naprawa.
5. **Warunek ciężkiej ponownej próby**: dopiero po przejściu kroków 1–4 i pomiarze pamięci oraz przepustowości przy kontrolowanych rozmiarach uruchomić `run_stage55_final_audit.m` w natywnym MATLAB z oryginalnym dziennikiem, artefaktami także w FAIL i bez przekraczania limitu zasobów. Nie uruchamiać ponownie identycznego DAG 4244-dniowego „na próbę”.

## Kryteria akceptacji i ograniczenia

- Wszystkie pięć składowych daty, nie tylko liczność i brzegi, musi się zgadzać z **niezależnym** wzorcem.
- Matematyczne dokładności `BigInt` nie zastępować typem `double`; checkpointy muszą zawierać pełne cyfry dziesiętne.
- `STAGE_55_REPOSITORY_AUDIT_PASS`, `STAGE_55_NATIVE_VERIFICATION_PASS` i `STAGE_55_FINAL_AUDIT_PASS` mogą zostać zapisane jako PASS tylko z odpowiadającym rzeczywistym dziennikiem.
- Cross-engine Soak pozostaje osobną bramą akceptacji.
- Bez zmiany `main`, bez merge PR, bez Stage 56 i bez zmiany `LAST_COMPLETED_STAGE=54`.

**Następna praca implementacyjna:** zamknięcie mierzalnego protokołu dla rzeczywistej rangi wewnętrznej oraz niezależnego dowodu Oracle (zamiast nieograniczonego DAG). Żadna modyfikacja produkcyjnej ścieżki nie jest tu przedwcześnie autoryzowana.
