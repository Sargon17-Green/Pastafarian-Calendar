# Etap 55 — plan kontynuacji pełnej weryfikacji obliczeń wielogodzinnych

## Stan dowodowy (2026-10-21, UTC)

- Native audit `39494750458` (commit `da4ed753e794c7d1e35b58511aafa45b8160e215`): Code Analyzer **162 pliki PASS**, wszystkie testy etapów **1–53 PASS**, Etap 54 static integration PASS. Zadanie zostało przerwane sygnałem shutdown podczas ciężkiego wywołania produkcji; bez porównania z oracle.
- Native audit `39545208545` (commit `b55feaea45a6629fe8ebb78e8a52d5bbbeb6d41d`): te same testy PASS, `STAGE_54_PRODUCTION_DIFFERENTIAL_BEGIN`, `STAGE_54_INTEGRATION_ENTRY`, `STAGE_54_YEAR_CHAIN_READY GATES=22 SECONDS=386.572`. Przerwanie w `buildYearStructure`. Brak `STAGE_54_YEAR_STRUCTURE_READY`, `STAGE_54_ORACLE_DIFFERENTIAL_EQUAL` i końcowego PASS.
- Native audit `39552537262` uruchomiono na `8a7b9a025b68e2629f8e19257a4dd63a92a562fb`; zawiera dalszą instrumentację etapów structure sauce / partition / month lengths / weaving i liczników stanów exact DAG. Jego wynik musi być odczytany z logu, nie domniemywany.

## Analiza kodu i ryzyko zasobowe

`finalMonsterIntegration.buildYearStructure` wywołuje `StructureSauceCompatibilityRoute`, wybór kotletów, `MonthLengthCompatibilityRoute`, a następnie `MonthWeavingCompatibilityRoute`. Ten ostatni przez `MonthWeavingDPPatchWrapper` konstruuje `WholeMonthWeavingFamily`.

`WholeMonthWeavingFamily.buildExactStateDP` utrzymuje **wszystkie warstwy** osiągalnych stanów od dnia 0 do `totalDays` w tablicy `layers`, indeksuje je przez tekstowe klucze `containers.Map`, a następnie utrzymuje osobną tablicę dokładnych `BigInt` completion counts w fazie odwrotnej. Dla dużej liczby miesięcy i dni wzrost przestrzeni stanów może stać się ograniczeniem pamięci/czasu. To ryzyko wynikające z konstrukcji algorytmu, **nie** potwierdzona diagnoza przyczyny przerwania runnera.

## Reguły konieczne dla korekty wydajności

1. Nie pomijać żadnego trudnego przypadku, dnia ani legalnego stanu; żadnego sztucznego `maxStates` zwracającego częściowy `count`.
2. Pozostawić dokładną arytmetykę `BigInt`, kolejność pierwszych otwarć i zamknięć miesięcy, multiplicities, porządek leksykograficzny oraz numerację rank od 1.
3. Nie modyfikować niezależnego oracle tak, aby naśladował produkcję. Dopuszczalne jest optymalizowanie wyłącznie bez zmiany jego znaczenia i z dowodami równoważności.
4. Zmieniony algorytm musi być sprawdzany na wszystkich małych rodzinach enumerowanych wyczerpująco w testach Stage 49, na świadkach Stage 48–53 oraz przy zgodnym, wielokrotnie weryfikowanym SHA wejścia i wyniku.
5. Dopóki nie ma pełnego `STAGE_54_HEAVY_DIFFERENTIAL_PASS` oraz `STAGE_55_FINAL_AUDIT_PASS`, nie zmieniać `LAST_COMPLETED_STAGE=54`.

## Procedura następnej iteracji

1. Odczytać końcowy stderr/stdout z run `39552537262`. Ustalić najdalszy znacznik `STAGE_54_*`. Jeśli pojawia się `STAGE_54_WEAVE_DP_FORWARD`, oszacować liczbę stanów, czas na warstwę i skumulowaną pamięć; nie przypisywać przyczyny bez obserwacji.
2. Jeśli dominują obliczenia sauce lub bram, profilować właściwą fazę oddzielnie. Jeśli dominuje exact DAG, zaprojektować dokładny algorytm z kontrolowaną pamięcią i **trwałymi, weryfikowalnymi checkpointami**, których można użyć w kolejnej sesji.
3. Każdy checkpoint musi zawierać: SHA kodu, wektor `monthLengths`, parametry otwarcia/zamknięcia, indeks warstwy, kompletność warstwy, exact `BigInt` counts, liczebność stanów, wersję formatu i SHA-256 danych. Odzyskanie tylko po walidacji manifestu. Nie uznawać częściowej warstwy za kompletną.
4. Nie wystarczy trzymać checkpointów na dysku efemerycznego runnera — trzeba potwierdzić ich dostępność zewnętrzną **przed** śmiercią joba. Zwykły `upload-artifact` dopiero na końcu nie spełnia tego warunku. Sposób publikacji/przekazania musi zostać najpierw przetestowany na małym wektorze.
5. W przypadku rozdzielenia na zadania osobno poświadczyć pass 1–53 oraz cały heavy differential. Końcowy zamykający gate musi zebrać i zweryfikować identyczny commit i dowody obu części; sam status CI nie jest wystarczający.

## Bezpieczeństwo stanu

Niniejszy dokument nie zmienia implementacji produkcyjnej, testów, workflow, algorytmu ani metadanych ukończenia. `main` pozostaje nietknięty.
