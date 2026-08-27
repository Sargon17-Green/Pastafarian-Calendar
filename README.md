# Kalendarz pastafariański — linia MATLAB + polski

To jest niezależna linia implementacyjna rozpoczęta od zera na podstawie wbudowanego opisu normatywnego zadania. Kod wykonywalny jest napisany wyłącznie w MATLAB-ie, a cały tekst tworzony dla człowieka w tej linii jest po polsku.

## Stan

Pakiet obejmuje wyłącznie etap 1 z 55: rozruch. Nie zawiera żadnej z 26 historycznych wad ani żadnej przyszłej łaty. Produkcyjna funkcja `calendarDateSpaghetti` jest celowo neutralnym szkieletem i kończy działanie kontrolowanym błędem, ponieważ historyczna ścieżka produkcyjna ma powstawać dopiero w kolejnych etapach.

W katalogu `tests/oracle` znajduje się niezależne, czyste źródło odniesienia przeznaczone wyłącznie do testów. Implementuje ono algorytm normatywny, natomiast produkcja nie ma do niego odwołania ani ścieżki awaryjnej.

## Dokładne liczby całkowite

MATLAB nie zapewnia w bibliotece podstawowej ogólnego typu liczb całkowitych o dowolnej precyzji. Dlatego `pastafari.BigInt` implementuje znakowane liczby całkowite w MATLAB-ie, bez obcego środowiska uruchomieniowego i bez mostu do innego języka. Reprezentacja używa kończyn w bazie 10 000 000, a działania utrzymują pośrednie wartości całkowite poniżej granicy dokładności typu `double` używanego wyłącznie jako pojemnik na pojedynczą kończynę.

## Katalog języka źródłowego

`pastafari.sourceLanguageCatalog` jest wersjonowany i zamrożony logicznie. Zawiera 17 nazw kotletów i 47 nazw miesięcy. Semantyka wewnętrzna operuje na `canonicalIndex`; tekst polski jest rozwiązywany dopiero w warstwie wyniku. Szczegóły znajdują się w `docs/SOURCE_LANGUAGE_CATALOG.md`.

## Uruchamianie testów

W MATLAB-ie przejdź do katalogu `tests` i uruchom:

```matlab
run_stage01_tests
```

Dodatkowy, potencjalnie kosztowny test pełnego źródła odniesienia:

```matlab
run_stage01_heavy_oracle_test
```

W środowisku, w którym przygotowano ten pakiet, program MATLAB nie był dostępny, dlatego wynik wykonania testów nie jest deklarowany jako zaliczony. Kod testowy jest częścią pakietu przekazania, ale etap pozostaje formalnie niezamknięty do czasu rzeczywistego uruchomienia w MATLAB-ie.
