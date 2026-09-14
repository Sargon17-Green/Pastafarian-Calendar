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

## Korekta stanu wejściowego przed etapem 2

Po zamknięciu etapu 1 ponownie przejrzano bieżący kod. Obsługę natywnych `int64` i `uint64` poprawiono tak, aby nie przechodziła przez `double`, a regresje wartości poza `flintmax` znajdują się obecnie w szybkim zestawie testowym.

Jednocześnie bieżący kod `BigInt` używa dokładnego mnożenia szkolnego oraz dokładnego dzielenia długiego z wyszukiwaniem cyfry ilorazu. Wcześniejsze etykiety dokumentacyjne „Karatsuba” i „Knuth D” nie opisują obecnego kodu i wymagają końcowego ponownego audytu dokumentacji. Ponowne uruchomienie natywnego MATLAB-a po tej korekcie zostało odłożone do zbiorczego cyklu weryfikacji.

## Etap 2 — DISCOVERY 01: SAVE nad zwykłym modulo

Po raz pierwszy dodano rzeczywistą historyczną wadę produkcyjną. `oldRemainder(x)` wykonuje dokładnie `regularMod(x, M)` i pozostaje celowo błędny dla dodatnich wielokrotności `M`.

Nowa trasa `SaveCompatibilityRoute` deleguje w tym etapie bezpośrednio do `oldRemainder`, zapisuje wejście i wynik w kontekście wywołania oraz rejestruje ślad i metrykę. Publiczny szkielet produkcyjny przechodzi już przez tę warstwę, lecz nadal zatrzymuje się na kontrolowanej granicy niezaimplementowanego pełnego kalendarza.

Regresja Discovery 01 sprawdza przypadki `M`, `2M`, `3M` i `M+1`. Dla pierwszych trzech przypadków legacy zwraca `0`, podczas gdy normatywne `SAVE` zwraca `M`; dla `M+1` oba zwracają `1`. Stan etapu jest zatem celowo `EXPECTED_RED`.

W etapie 2 nie dodano jeszcze `savePatch`. Błędny `oldRemainder` musi pozostać niezmieniony jako historyczna blizna; dopiero etap 3 ma dodać łatę nad nim.

## Etap 3 — PATCH 01: savePatch

Historyczny `oldRemainder` pozostaje bez zmian i nadal zwraca `0` dla dodatnich wielokrotności `M`. Łata nie naprawia starej funkcji w miejscu.

Dodano osobny `SavePatch`, który otrzymuje surowy wynik legacy i wykonuje dokładnie jedną korektę: gdy wynik jest równy `0`, zwraca `M`; każdą niezerową wartość pozostawia bez zmian.

`SaveCompatibilityRoute` najpierw wykonuje i zapisuje wynik `oldRemainder`, a dopiero potem nakłada `savePatch`. Dzięki temu ślad historycznej wady pozostaje obserwowalny, natomiast publikowany wynik SAVE jest zgodny z normatywnym oracle.

Niezmieniony regression z Discovery 01 ma po tym etapie przejść na zielono dla `M`, `2M`, `3M` i `M+1`. Dodatkowy test etapu 3 sprawdza, że surowa wada nadal istnieje, patch jest wywoływany dokładnie raz i modyfikuje wyłącznie zero.

Ponowne uruchomienie w natywnym MATLAB-ie jest odłożone do końcowego, zbiorczego cyklu weryfikacji.

## Etap 4 — DISCOVERY 02: oldDayTag

Dodano drugą historyczną wadę produkcyjną. `oldDayTag(day)` oblicza dokładnie `2*abs(day-FOUNDATION)` i pozostaje celowo błędny.

Przed Dniem Założenia wzór przypadkiem zgadza się z normatywnym licznikiem dnia. Na samym Foundation zwraca `0` zamiast `1`, a po stronie późniejszej brakuje przesunięcia `+1` — na przykład pierwszy dzień po Foundation otrzymuje `2` zamiast `3`.

Nowa `DayTagCompatibilityRoute` w etapie 4 publikuje bezpośrednio wynik `oldDayTag`, zachowuje surową wartość w kontekście oraz rejestruje ślad i metrykę. Publiczna ścieżka produkcyjna przechodzi zarówno przez zachowany PATCH 01, jak i przez nową warstwę Discovery 02.

Regresja sprawdza `FOUNDATION-1`, `FOUNDATION` i `FOUNDATION+1`. Oczekiwany wzorzec to zgodność przed Foundation oraz `EXPECTED_RED` na Foundation i po stronie późniejszej.

W etapie 4 nie ma jeszcze korekty Foundation scar. `oldDayTag` ma pozostać niezmieniony; dopiero etap 5 doda osobną korektę strony późniejszej i drugi guard dla Foundation. Ponowna weryfikacja natywnego MATLAB-a pozostaje odłożona do końcowego cyklu uruchomień.

## Etap 5 — PATCH 02: Foundation scar

Historyczny `oldDayTag(day)=2*abs(day-FOUNDATION)` pozostaje bez zmian. Łata nie poprawia starej funkcji w miejscu.

Dodano osobny `FoundationScarPatch`. Najpierw bierze surowy wynik `oldDayTag`. Jeżeli `day >= FOUNDATION`, dodaje `1`. Następnie wykonuje drugi, celowo redundantny guard: jeżeli `day == FOUNDATION` i wynik nadal nie jest równy `1`, wymusza `1`.

Ten drugi guard pozostaje w kodzie jako wymagana historyczna blizna, mimo że po wcześniejszym dodaniu `+1` normalnie nie zmienia już wyniku Foundation.

`DayTagCompatibilityRoute` nadal wywołuje i zapisuje surowy `oldDayTag`, a dopiero potem nakłada Foundation scar. Dzięki temu historyczna wada pozostaje obserwowalna, natomiast publikowany licznik dnia zgadza się z normatywnym `dayCount`.

Niezmieniony regression z Discovery 02 ma po tym etapie przejść na zielono. Dodatkowy test etapu 5 obejmuje zakres od `FOUNDATION-2` do `FOUNDATION+2`, potwierdza zachowanie starej blizny oraz zgodność wyniku po patchu.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 6 — DISCOVERY 03: oldDistance

Dodano trzeci historyczny defekt. `oldDistance(c,t)` nie mierzy odległości na osi dni. Zamiast tego bierze bezwzględną różnicę poprawionych tagów dni:

`abs(dayTagWithFoundationScar(c) - dayTagWithFoundationScar(t))`.

W tej wersji nie ma jeszcze końcowego `+1`. Sama różnica tagów jest szczególnie zdradliwa wokół Foundation, ponieważ tagi po obu stronach tej granicy nie stanowią liniowej osi chronologicznej.

Nowa `WorkCountsCompatibilityRoute` oblicza poprawne `action`, `target`, `connection` i `direction`, lecz publikuje błędny legacy distance. Dzięki temu Discovery 03 izoluje wyłącznie trzeci defekt.

Regresja obejmuje ten sam dzień oraz kilka par wokół Foundation. Między innymi ten sam dzień daje `0` zamiast `1`, Foundation do Foundation+3 daje `6` zamiast `4`, Foundation-3 do Foundation+3 daje `1` zamiast `7`, natomiast Foundation do Foundation+1 przypadkowo pozostaje zgodne (`2`).

W etapie 6 nie ma jeszcze PATCH 03 ani końcowego `+1`. Historyczny `oldDistance` ma pozostać fizycznie zachowany; etap 7 doda nad nim detour z chronologiczną różnicą dni. Ponowna weryfikacja natywnego MATLAB-a pozostaje odłożona do końcowego cyklu uruchomień.

## Etap 7 — PATCH 03: chronological distance

Historyczny `oldDistance` pozostaje fizycznie bez zmian. Nadal oblicza bezwzględną różnicę poprawionych tagów dni i nadal może zwracać błędne wartości.

Dodano osobny `ChronologicalDistancePatch`. Trasa najpierw wykonuje i zachowuje surowy `oldDistance`, a następnie całkowicie zastępuje go właściwym dystansem osi dni:

`abs(targetDay - calculationDay) + 1`.

Końcowe `+1` jest częścią wymaganej semantyki dystansu, dlatego ten sam dzień daje zawsze `1`.

`WorkCountsCompatibilityRoute` publikuje po patchu poprawne `distance`, zachowując jednocześnie poprawne `action`, `target`, `connection` i `direction`. Ślad wykonania i metryki rejestrują osobno historyczny oldDistance oraz PATCH 03.

Niezmieniony regression z Discovery 03 ma po tym etapie przejść na zielono. Dodatkowy test etapu 7 obejmuje ruch w przód i wstecz po obu stronach Foundation oraz osobno potwierdza granicę tego samego dnia.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 8 — DISCOVERY 04: sekwencyjna mutacja kamieni

Dodano czwarty historyczny defekt. Tabela 46×5 kamieni jest budowana przez stary mutator, który aktualizuje pięć kamieni każdego nowego wiersza kolejno w tym samym buforze.

Pierwszy kamień korzysta jeszcze wyłącznie z poprzedniego wiersza. Drugi używa już zaktualizowanego kamienia 1, trzeci używa zaktualizowanego kamienia 2, czwarty używa zaktualizowanego kamienia 3, a piąty używa zaktualizowanych kamieni 1 i 4.

Dlatego drugi wiersz legacy ma wartości `378, 1434, 3780, 9932, 25047`, podczas gdy snapshot oracle daje `378, 1073, 2375, 6195, 10493`. Pierwszy kamień pozostaje przypadkowo zgodny, a kamienie 2–5 rozchodzą się natychmiast.

`StoneTableCompatibilityRoute` w etapie 8 publikuje bezpośrednio sekwencyjnie mutowaną tabelę i zachowuje ją w kontekście.

PATCH 04 nie został jeszcze dodany. Historyczny mutator musi pozostać fizycznie zachowany; etap 9 ma wywołać legacy na klonie, lecz nadpisać wszystkie pięć wyników na podstawie niezmienionego snapshotu poprzedniego wiersza.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 9 — PATCH 04: snapshot kamieni

Historyczny sekwencyjny mutator kamieni pozostaje fizycznie bez zmian. PATCH 04 nie usuwa go ani nie naprawia w miejscu.

Dla każdego nowego wiersza zapisywany jest niezmienny snapshot pięciu kamieni poprzedniego wiersza. Historyczny mutator jest nadal wykonywany na kopii tego snapshotu, dzięki czemu jego błędne wyniki pozostają obserwowalne.

Następnie PATCH 04 nadpisuje wszystkie pięć publikowanych wyników, obliczając każdy z nich wyłącznie z niezmiennego snapshotu poprzedniego wiersza. Żaden kamień nowego wiersza nie może zobaczyć aktualizacji wykonanej wcześniej w tym samym wierszu.

Dlatego drugi wiersz legacy nadal ma `378, 1434, 3780, 9932, 25047`, ale publikowany drugi wiersz ma `378, 1073, 2375, 6195, 10493`. Test etapu 9 porównuje po patchu całą tabelę 46×5 z lokalnym normatywnym oracle.

Niezmieniony regression z Discovery 04 ma po tym etapie przejść na zielono. Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 10 — DISCOVERY 05: backward hidden storage

Dodano piąty historyczny defekt. Siedem wartości hidden jest obliczanych według właściwych formuł, lecz fizyczny magazyn zapisuje je w odwrotnej kolejności:

`hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1`.

Historyczny odczyt nadal traktuje jednak fizyczny slot `k` jako logiczne `hidden k`. W rezultacie logiczne hidden są widziane w kolejności `7..1`.

`HiddenCompatibilityRoute` zachowuje fizyczny odwrócony magazyn w kontekście oraz publikuje naiwne odczyty legacy. Regresja Stage 10 niezależnie oblicza siedem wartości hidden, potwierdza dokładną relację odwrócenia magazynu i wykazuje rozbieżność logicznego indeksowania.

W etapie 10 nie istnieje jeszcze translator indeksu. Nie wolno odwracać ani przepisywać magazynu. Dopiero Stage 11 ma sprawić, że każde żądanie `hidden k` odczyta fizyczny slot `8-k`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 11 — PATCH 05: translator indeksu hidden

Fizyczny magazyn z Discovery 05 pozostaje bez zmian i nadal przechowuje wartości w kolejności `hidden7..hidden1`. PATCH 05 nie odwraca tablicy, nie kopiuje jej do kolejności logicznej i nie usuwa historycznej blizny.

Dodano osobny `HiddenIndexTranslator`. Żądanie logicznego `hidden k` jest mapowane na fizyczny slot `8-k`. Trasa nadal oblicza i zachowuje naiwny historyczny odczyt slotu `k`, ale publikuje wartość odczytaną przez translator.

W trakcie przygotowania PATCH 05 skorygowano również konstrukcję regresji Stage 10: wcześniejszy test błędnie wymagał, aby publikowany wynik zawsze pozostawał równy naiwnemu slotowi legacy, co uniemożliwiałoby przejście na GREEN po prawidłowym patchu. Zmieniona regresja nadal bezwzględnie wymaga fizycznego układu `7..1` i zachowania naiwnego odczytu w kontekście, lecz klasyfikuje RED/GREEN według publikowanego wyniku logicznego. Nie zmienia to historycznego defektu Stage 10.

Po PATCH 05 logiczne hidden 1..7 odpowiadają normatywnym wartościom, podczas gdy pamięć i naiwny odczyt legacy pozostają obserwowalne jako blizna.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 12 — DISCOVERY 06: legacyPrior

Dodano szósty historyczny defekt. Widoczna kropla `i` potrzebuje poprzedników `i-1`, `i-3` i `i-7`. Siedem hidden tworzy historię dla logicznych pozycji `0,-1,...,-6`.

Historyczny `legacyPrior` rozumie jednak wyłącznie dodatnie indeksy już zbudowanych visible drops. Gdy pierwsze siedem kropli pyta o slot `0` albo ujemny, legacy zgłasza brak wartości. Aby ścieżka mogła dalej wykonywać kolejne obliczenia, Discovery 06 podstawia w brakującym miejscu zero; samo podstawienie nie jest poprawką semantyczną.

Dla drop 1 brakuje wszystkich trzech poprzedników, dla drop 2 i 3 brakuje dwóch, a dla drops 4–7 brakuje poprzednika `i-7`. Od drop 8 wszystkie trzy wymagane indeksy visible są już dodatnie.

`VisibleDropCompatibilityRoute` zapisuje żądane sloty, macierz braków i pełny surowy ciąg legacy. Regresja zachowuje tę bliznę niezależnie od późniejszego patcha, a stan Stage 12 jest `EXPECTED_RED`.

W etapie 12 nie istnieje jeszcze `priorPatch`. Dopiero Stage 13 ma mapować brakujące logiczne sloty `0..-6` na odpowiednie hidden 1..7, bez modyfikowania `legacyPrior`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 13 — PATCH 06: priorPatch

Historyczny `LegacyPriorAdapter` pozostaje fizycznie bez zmian. Nadal rozumie wyłącznie dodatnie indeksy wcześniej zbudowanych visible drops i nadal zgłasza brak wartości dla logicznych slotów `0..-6`.

Dodano osobny `PriorPatch`. Jeżeli `legacyPrior` nie znajduje poprzednika i żądany logiczny slot należy do zakresu `0..-6`, patch mapuje go na odpowiednie hidden według reguły:

`hiddenIndex = 1 - slot`.

Oznacza to dokładnie `0 -> hidden1`, `-1 -> hidden2`, ..., `-6 -> hidden7`.

`VisibleDropCompatibilityRoute` zachowuje pełną surową ścieżkę Discovery 06 z zerowymi fallbackami jako obserwowalną bliznę. Osobno buduje publikowaną ścieżkę: dodatnie sloty nadal przechodzą przez historyczny `legacyPrior`, a wyłącznie brakujące sloty `0..-6` są uzupełniane przez `PriorPatch`.

Niezmieniony regression Stage 12 ma po tej zmianie przejść na GREEN. Test Stage 13 dodatkowo sprawdza wszystkie siedem mapowań oraz zgodność wszystkich 46 widocznych kropli z lokalnym normatywnym oracle dla kilku kierunków i odległości.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

