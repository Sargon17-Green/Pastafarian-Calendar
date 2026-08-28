# Historia rozwoju potwora spaghetti

## Etap 1 — rozruch

Linia MATLAB + polski została rozpoczęta od zera. Nie użyto kodu, testów, danych oczekiwanych, tabel wygenerowanych, logów, skrótów ani artefaktów żadnej innej implementacji.

Utworzono wyłącznie neutralne elementy architektury, które nie przewidują żadnej konkretnej przyszłej łaty: kontekst jednego wywołania, bazowy dyspozytor, bazową walidację, bazową powłokę metryk i bazowe opakowanie błędu. Produkcyjna funkcja główna pozostaje świadomie bez semantyki historycznych etapów.

Utworzono niezależne testowe źródło odniesienia z Appendix A oraz własny typ dokładnych liczb całkowitych. Katalog polskich nazw został ustalony i zamrożony według indeksów kanonicznych.

Przed formalnym zamknięciem etapu 1 wykryto w samym kodzie rozruchowym błąd dokładności wejścia: natywne wartości `int64` i `uint64` przechodziły przez `double`, co mogło utracić bity powyżej `flintmax`. Naprawiono to w obrębie etapu 1, bez dodawania żadnej przyszłej wady ani łaty, i dodano testy regresyjne wartości granicznych.

Nie ma jeszcze wpisu dla żadnej z 26 wad historycznych, ponieważ ich historia może być dopisywana dopiero w odpowiadających im etapach odkrycia i łaty.


## Audyt wykonania etapu 1 — wydajność źródła odniesienia

Rzeczywisty MATLAB wykazał, że dokładny oracle dochodzi do budowy splotu, ale pierwotne memoizowanie całego wektora pozostałości jest niepraktyczne. W granicach Bootstrapu zastąpiono wyłącznie testowy licznik równoważnym liczeniem rozszerzeń liniowych z jednowymiarowym rozkładem pozycji pierwszego elementu. Nie dodano żadnej historycznej wady, flagi ani łaty etapów 2–53. Małe przypadki są materializowane niezależnie w MATLAB-ie i porównywane element po elemencie z rozwijaniem rangi.

## Korekta wydajności rozruchu: rozwijanie splotu

W etapie 1 nie dodano żadnej historycznej wady ani przyszłej łaty. Rzeczywiste uruchomienie wykazało, że dokładne zliczenie splotu kończy się, lecz rozwijanie rangi powtarza kosztowne liczenie dla każdego prefiksu. Zastąpiono je jednorazowym DP `H_a(T)` i dokładnym rozwijaniem bloków leksykograficznych. Dla dużych iloczynów pomocniczy `BigInt` używa teraz rozkładu Karatsuby. Obie zmiany są optymalizacjami testowego źródła odniesienia i arytmetyki dokładnej etapu 1; nie zmieniają semantyki Appendix A ani neutralnego szkieletu produkcyjnego.

## Zamknięcie etapu 1 — pełna weryfikacja natywna

Pełną weryfikację uruchomiono w rzeczywistym MATLAB-ie `26.1.0.3346908 (R2026a) Update 5`. Szybki zestaw zakończył się znacznikiem `STAGE_01_TESTS_PASS`; obejmuje on między innymi dokładną konwersję `int64` i `uint64` poza `flintmax`, skrajne wartości 64-bitowe, dokładne dzielenie Knutha D i dużą ścieżkę mnożenia Karatsuby.

Ciężkie testowe źródło odniesienia wykonało pełne `calendar` dla Dnia Założenia i zakończyło się znacznikiem `STAGE_01_HEAVY_ORACLE_TEST_PASS`. Dokładne zliczenie rodziny splotów dla 45 miesięcy zwróciło liczbę o 6765 cyfrach, a rozwijanie rangi zakończyło wszystkie 4244 pozycje. Pełne wywołanie kalendarza źródła odniesienia trwało 664.715 s.

Końcowe znaczniki `WYNIK_1=PASS`, `WYNIK_2=PASS`, `STAGE_01_COMPLETE_CANDIDATE=YES` i `STAGE_01_VERIFICATION_PASS` potwierdzają zakończenie rozruchu. `LAST_COMPLETED_STAGE` ustawiono na `1`. Żadna wada historyczna ani łata przyszłego etapu nie została dodana; następnym dozwolonym etapem jest etap 2, `DISCOVERY 01`.
