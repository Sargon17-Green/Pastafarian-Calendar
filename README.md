# Kalendarz pastafariański — linia MATLAB + polski

To jest niezależna linia implementacyjna rozpoczęta od zera na podstawie wbudowanego opisu normatywnego zadania. Kod wykonywalny jest napisany wyłącznie w MATLAB-ie, a cały tekst tworzony dla człowieka w tej linii jest po polsku.

## Stan

Etap 1 z 55, czyli rozruch, jest zakończony i zweryfikowany w rzeczywistym MATLAB-ie `26.1.0.3346908 (R2026a) Update 5`. Pakiet nie zawiera żadnej z 26 historycznych wad ani żadnej przyszłej łaty. Produkcyjna funkcja `calendarDateSpaghetti` pozostaje celowo neutralnym szkieletem i kończy działanie kontrolowanym błędem, ponieważ historyczna ścieżka produkcyjna ma powstawać dopiero od etapu 2.

W katalogu `tests/oracle` znajduje się niezależne, czyste źródło odniesienia przeznaczone wyłącznie do testów. Implementuje ono algorytm normatywny Appendix A. Produkcja nie ma do niego odwołania ani ścieżki awaryjnej.

## Dokładne liczby całkowite

MATLAB nie zapewnia w bibliotece podstawowej ogólnego typu liczb całkowitych o dowolnej precyzji. Dlatego `pastafari.BigInt` implementuje znakowane liczby całkowite w MATLAB-ie, bez obcego środowiska uruchomieniowego i bez mostu do innego języka. Reprezentacja używa kończyn w bazie 10 000 000. Typ `double` jest używany wyłącznie jako pojemnik na pojedyncze kończyny i ich ograniczone iloczyny, dla których wartości pośrednie pozostają poniżej `flintmax`.

Audyt etapu 1 usunął pośrednią konwersję natywnych `int64` i `uint64` przez `double`. Natywne testy obejmują wartości `2^53+1`, `-(2^53+1)`, `intmax('uint64')` i `intmin('int64')`. Testy obejmują także dokładne dzielenie wielocyfrowe Knutha D, dzielenie podłogowe liczb ujemnych i dużą ścieżkę mnożenia Karatsuby. Wszystkie te regresje przeszły w MATLAB-ie R2026a Update 5.

## Katalog języka źródłowego

`pastafari.sourceLanguageCatalog` jest wersjonowany i zamrożony logicznie. Zawiera 17 nazw kotletów i 47 nazw miesięcy. Semantyka wewnętrzna operuje na `canonicalIndex`; tekst polski jest rozwiązywany dopiero w warstwie wyniku. Szczegóły znajdują się w `docs/SOURCE_LANGUAGE_CATALOG.md`.

## Weryfikacja etapu 1

W katalogu `tests` uruchomiono:

```matlab
run_stage01_verification
```

Końcowy wynik:

```text
STAGE_01_TESTS_PASS
WYNIK_1=PASS
STAGE_01_HEAVY_ORACLE_TEST_PASS
WYNIK_2=PASS
STAGE_01_COMPLETE_CANDIDATE=YES
STAGE_01_VERIFICATION_PASS
```

Pełny log znajduje się w `logs/STAGE_01_MATLAB_RUN_2026-08-28_PASS.txt` oraz jako bieżący `logs/STAGE_01_MATLAB_RUN.log`.

## Wydajność dokładnego źródła odniesienia

Ciężkie źródło odniesienia wykonało pełne obliczenie dla Dnia Założenia. Najważniejsze zmierzone czasy:

- znalezienie roku: 43.954 s;
- sos struktury: 1.379 s;
- kotlety: 0.048 s;
- długości miesięcy: 16.202 s;
- dokładne przygotowanie i zliczenie splotów: 194.673 s;
- dokładne leksykograficzne rozwijanie splotu 4244-dniowego: 406.775 s;
- cały etap splotu miesięcy: 602.941 s;
- pełna budowa struktury roku: 620.754 s;
- pełne wywołanie `calendar`: 664.715 s.

Licznik splotów dla 45 miesięcy wygenerował dokładną liczbę o 6765 cyfrach. Optymalizacje są opisane w `docs/BIGINT_DIVISION_PERFORMANCE_STAGE_01.md`, `docs/WEAVING_PERFORMANCE_STAGE_01.md` i `docs/WEAVING_UNRANK_ACCELERATION_STAGE_01.md`.

## Następny etap

Etap 1 jest zamknięty. Następnym dozwolonym krokiem jest wyłącznie etap 2 z 55: `DISCOVERY 01`. Nie wolno łączyć go z łatą 01 ani z żadnym późniejszym etapem.
