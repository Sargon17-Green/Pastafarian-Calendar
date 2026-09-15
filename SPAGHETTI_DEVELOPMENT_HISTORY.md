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

## Etap 14 — DISCOVERY 07: grind table index

Dodano siódmy historyczny defekt. Produkcyjna ścieżka po poprawnym `priorPatch` przechodzi przez osobną historyczną warstwę indeksowania 11-wierszowej tabeli mielenia.

Legacy traktuje numer mielenia jak indeks przesunięty o jeden i żąda fizycznego wiersza `grindNumber+1`. Ponieważ tabela nie ma jeszcze sentinel row odpowiadającego logicznemu indeksowi 0, pierwsze mielenie zamiast kanonicznego wiersza `3,5,7,11,1` pobiera drugi wiersz `5,7,11,13,2`. Historyczny guard końca tabeli nasyca żądanie wychodzące poza ostatni wiersz.

`GrindTableCompatibilityRoute` otrzymuje poprawne visible drops sprzed nowej wady, zachowuje je w kontekście, a następnie ponownie buduje 46 widocznych kropli z przesuniętym lookupem grind. Dzięki temu Discovery 07 izoluje nowy defekt bez naruszania wcześniejszego PATCH 06.

W etapie 14 nie ma jeszcze wiersza sentinel. Dopiero Stage 15 ma zachować historyczny wzór indeksowania i dodać wiersz pod logicznym indeksem 0, tak aby wszystkie 11 mielenia wróciły do właściwych wierszy.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 15 — PATCH 07: sentinel grind row

Historyczne indeksowanie `grindNumber+1` pozostaje fizycznie bez zmian. `LegacyGrindTableAdapter` nadal na surowej 11-wierszowej tabeli przesuwa pierwsze mielenie na wiersz 2 i nasyca ostatnie żądanie poza końcem tabeli.

Dodano osobny `SentinelGrindRowPatch`, który nie zmienia lookupu. Przed 11 kanonicznymi wierszami dodaje jeden zerowy wiersz sentinel reprezentujący logiczny indeks 0. Powstaje fizyczna tabela 12×5: sentinel zajmuje wiersz 1, a kanoniczne grinds 1..11 zajmują wiersze 2..12.

Dzięki temu ten sam historyczny lookup `grindNumber+1` wybiera dla grinds 1..11 dokładnie fizyczne wiersze 2..12, czyli wszystkie właściwe wiersze kanoniczne.

`GrindTableCompatibilityRoute` najpierw wykonuje i zachowuje pełną surową ścieżkę Discovery 07 na tabeli bez sentinel, a następnie osobno buduje publikowaną ścieżkę na tabeli z sentinel. Historyczna blizna pozostaje więc obserwowalna.

W trakcie PATCH 07 skorygowano konstrukcję regresji Stage 14: wcześniejszy test wiązał publikowany wynik bezpośrednio z surowym wynikiem legacy, przez co poprawny patch nie mógłby przejść na GREEN. Zmieniony test nadal bezwzględnie sprawdza przesunięte indeksy i surową rozbieżność legacy, ale klasyfikuje stan według publikowanej ścieżki.

Test Stage 15 sprawdza wszystkie 11 mapowań tabeli, zachowanie surowej blizny oraz zgodność wszystkich 46 widocznych kropli z lokalnym normatywnym oracle.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 16 — DISCOVERY 08: oldPermutationUnrank0

Dodano ósmy historyczny defekt. Nowy `LegacyPermutationUnrank0` jest historycznym rozwijaniem rangi zero-based i przyjmuje zakres `0..719` dla sześciu mis.

Defekt nie polega na samym algorytmie zero-based. Produkcyjna trasa błędnie traktuje `regularMod(v,720)` jako końcową rangę zero-based zamiast najpierw utworzyć kanoniczną rangę 1-based.

Dlatego dla wejścia `1` legacy używa `rank0=1` i zwraca drugą permutację leksykograficzną `[1,2,3,4,6,5]` zamiast pierwszej `[1,2,3,4,5,6]`. Dla wejścia `720` legacy używa `rank0=0` i wraca do pierwszej permutacji zamiast ostatniej `[6,5,4,3,2,1]`.

`PermutationCompatibilityRoute` zapisuje wejście, surową rangę zero-based i surową historyczną permutację w kontekście. Publiczny szkielet przechodzi przez nową warstwę po poprawionych visible drops.

W etapie 16 nie ma jeszcze detour rankingu 1-based. Dopiero Stage 17 ma obliczyć `regularMod(v-1,720)+1`, odjąć `1` i dopiero wtedy wywołać niezmieniony legacy unrank0.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 17 — PATCH 08: one-based rank detour

Historyczny `LegacyPermutationUnrank0` pozostaje fizycznie bez zmian i nadal przyjmuje rangę zero-based `0..719`. PATCH 08 nie przepisuje algorytmu unrank.

`PermutationCompatibilityRoute` nadal najpierw wykonuje dokładnie surową ścieżkę Discovery 08: oblicza `regularMod(v,720)` i rozwija tę błędną rangę przez legacy unrank0. Surowa ranga oraz surowa permutacja pozostają zapisane w kontekście jako obserwowalna blizna.

Dodano osobny `OneBasedRankDetourPatch`. Poprawna ranga jest tworzona jako:

`rank1 = regularMod(v-1,720)+1`.

Dopiero na granicy starego unranku wykonywane jest:

`rank0 = rank1-1`.

Ten `rank0` trafia do tego samego, niezmienionego `LegacyPermutationUnrank0`.

W rezultacie wejście `1` publikuje pierwszą permutację `[1,2,3,4,5,6]`, a wejście `720` publikuje ostatnią `[6,5,4,3,2,1]`. Detour zachowuje również prawidłowe zawijanie rang większych od 720.

W trakcie PATCH 08 skorygowano konstrukcję regresji Stage 16: wcześniejszy test wymagał bezwarunkowo, aby publikowane wyniki dla rang 1 i 720 pozostały rozbieżne, przez co prawidłowy patch nie mógłby przejść na GREEN. Zmieniony test nadal bezwzględnie wymaga rozbieżnej surowej blizny legacy, ale klasyfikuje RED/GREEN według publikowanego wyniku.

Test Stage 17 sprawdza granice 1 i 720, kilka rang wewnętrznych, zawinięcia 721 i 1440, zachowanie surowej blizny oraz zgodność detour z lokalnym normatywnym oracle.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 18 — DISCOVERY 09: fixed-bowl pours

Dodano dziewiąty historyczny defekt. Po poprawnym wyznaczeniu order dla sześciu mis trzy pours nadal są liczone tak, jakby positions 1, 2 i 3 były na stałe bowl IDs 1, 2 i 3.

Historyczna warstwa wykonuje więc:
- pour position 1 z `old{1}`,
- pour position 2 z `old{2}`,
- pour position 3 z `old{3}`,

zamiast czytać misy wskazane przez `order(1)`, `order(2)` i `order(3)`.

Pozostała część bowl round jest w tym etapie celowo poprawna: wszystkie odczyty sześciu aktualizacji pochodzą z jednego snapshotu `old`, wyniki trafiają do osobnego `pending`, a commit następuje dopiero po wyliczeniu wszystkich sześciu mis. Wada in-place contamination nie została jeszcze wprowadzona; należy ona dopiero do Discovery 10.

Regresja używa kontrolowanego drop `121`, którego porządek mis zaczyna się `[2,1,3,4,5,6]`. Dzięki temu legacy pour 1 i 2 rozchodzą się natychmiast, natomiast pour 3 przypadkowo pozostaje zgodny. Surowe legacy pours są zapisywane osobno, aby przyszły PATCH 09 mógł zachować bliznę i naprawić wyłącznie publikowaną ścieżkę.

W etapie 18 nie istnieje jeszcze `bowlAlias`. Dopiero Stage 19 ma ustawić `bowlAlias[position]=order[position]` i skierować każde odczytanie misy dla pours przez ten alias.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 19 — PATCH 09: bowl aliases

Historyczny `LegacyFixedBowlPourAdapter` pozostaje fizycznie bez zmian. Nadal interpretuje positions 1, 2 i 3 jako stałe bowl IDs 1, 2 i 3 i nadal produkuje surową rozbieżną ścieżkę Discovery 09.

Dodano osobny `BowlAliasPatch`. Dla każdego bieżącego order tworzy dokładne mapowanie:

`bowlAlias[position] = order[position]`.

Trzy publikowane pours odczytują więc odpowiednio `old{bowlAlias(1)}`, `old{bowlAlias(2)}` i `old{bowlAlias(3)}`. Nie zmienia to samego order ani historycznej funkcji fixed-bowl.

`BowlPourCompatibilityRoute` wykonuje teraz dwie pełne ścieżki. Najpierw buduje i zachowuje surowe legacy pours oraz końcowe bowls z historycznym fixed-bowl adapterem. Następnie osobno buduje publikowaną ścieżkę z `BowlAliasPatch`.

Obie ścieżki wciąż są transakcyjne: każdy round zachowuje snapshot `old`, wszystkie sześć wyników trafia do osobnego `pending`, a commit następuje dopiero po zakończeniu całego round. Dzięki temu PATCH 09 nie wyprzedza Discovery 10 dotyczącego in-place bowl contamination.

Niezmieniony regression Stage 18 ma po tej zmianie przejść na GREEN. Test Stage 19 dodatkowo sprawdza kilka różnych permutacji, zachowanie surowej historycznej blizny oraz zgodność pełnej 46-round ścieżki z niezależnym reference.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 20 — DISCOVERY 10: in-place bowl stir contamination

Dodano dziesiąty historyczny defekt. Poprzedni PATCH 09 pozostaje osobną zieloną warstwą: pours nadal używają `bowlAlias[position]=order[position]`.

Nowa `LegacyInPlaceBowlUpdateWrong` wykonuje jednak sześć aktualizacji bowl jednego round na jednym mutable logicznie `working`. Każda pozycja czyta `current`, `previous` i `next` z bieżącego `working`, oblicza nową wartość i natychmiast zapisuje ją z powrotem. Późniejsze positions mogą więc odczytać wynik zapisany wcześniej w tym samym round zamiast stanu wejściowego round.

Mały dokładny witness używa bowls `11,13,17,19,23,29`, drop `1`, indeksu `4`, stones `2,3,5,7,11` oraz identity order. Simultaneous reference daje:

`23205, 23443, 49647, 18871, 28375, 13610`.

Historyczna ścieżka in-place daje:

`23205, 2167757877, 18796698741299337031, 52134066600902479800271676581807921729, 49276137518158613509478075707571518903, 122328037836810514334452521434516846956`.

Pierwsza pozycja pozostaje zgodna, ponieważ żaden wcześniejszy write jeszcze nie nastąpił; bowls 2–6 są już skażone.

Aby nie psuć regresji PATCH 09, Discovery 10 jest nową downstream warstwą `BowlStirCompatibilityRoute`. Zielona ścieżka PATCH 09 jest nadal wykonywana i zachowywana osobno, a dopiero nowa warstwa publikuje zanieczyszczone bowls.

W etapie 20 nie istnieją jeszcze `vaultOld`, osobny `pending` ani późny commit. Dopiero Stage 21 ma pozostawić legacy in-place fizycznie bez zmian, ale wykonać wszystkie reads z jednego `vaultOld`, wszystkie writes do `pending` i zatwierdzić wynik dopiero po sześciu pozycjach.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 21 — PATCH 10: vaultOld + pending

Historyczny `LegacyInPlaceBowlUpdateWrong` pozostaje fizycznie bez zmian. Nadal wykonuje sześć sekwencyjnych writes na jednym `working` i nadal pozostaje obserwowalną blizną Discovery 10.

Dodano osobny `VaultOldPendingPatch`. Na początku każdego round bieżące sześć mis jest kopiowane logicznie do `vaultOld`. Każde z sześciu obliczeń `current`, `previous` i `next` czyta wyłącznie z tego samego `vaultOld`, niezależnie od tego, które positions zostały już policzone.

Wynik każdej position trafia do osobnego `pending{id}`. Żadna wartość `pending` nie jest używana jako wejście dla kolejnej position. Dopiero po obliczeniu wszystkich sześciu positions całe `pending` staje się stanem następnego round.

`BowlStirCompatibilityRoute` wykonuje teraz dwie pełne ścieżki: najpierw niezmieniony legacy in-place i zachowuje jego pierwszy oraz końcowy stan jako bliznę, a następnie osobno buduje publikowaną ścieżkę przez `vaultOld + pending`.

PATCH 09 pozostaje aktywny w obu ścieżkach na poziomie pours: semantyczne positions nadal są mapowane przez `bowlAlias[position]=order[position]`.

Niezmieniony regression Stage 20 ma po tej zmianie przejść na GREEN. Test Stage 21 ponownie sprawdza mały dokładny witness oraz kilka 46-round sekwencji o różnych order, porównując każdą końcową bowl z niezależną transakcyjną ścieżką reference.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 22 — DISCOVERY 11: lost order at drop 46

Dodano jedenasty historyczny defekt ownership. Poprawna ścieżka bowls z PATCH 10 pozostaje bez zmian, a dwanaście normatywnych post-stirs jest wykonywanych z jednym snapshotem `old` i wspólnym commitem każdego stir.

Historyczny problem dotyczy wyłącznie przechowywania order. `LegacyOverwritableOrderMemory` ma jedno nadpisywalne pole. To samo pole otrzymuje 46 zapisów order — po jednym dla każdego visible drop — a następnie 12 kolejnych zapisów order podczas post-stirs.

Bezpośrednio po drop 46 pamięć zawiera właściwy order. Dla Foundation jest to:

`4,5,2,3,6,1`.

Nie istnieje jednak osobny latch. Post-stirs 1–12 nadpisują to samo pole. Po ostatnim, 58. zapisie pamięć pochodzi z `post-stir 12`; dla Foundation zawiera:

`1,6,5,2,4,3`.

`queryOrder` czyta właśnie to jedno legacy pole, dlatego zwraca końcowy order post-stir zamiast order z drop 46.

Same bowls pozostają poprawne. Każdy post-stir oblicza `savedStirSum = SAVE(sum(oldBowls)+149*stir)`, wyznacza order i aktualizuje sześć mis jednocześnie ze wspólnego snapshotu `old`. Final bowls muszą być identyczne z lokalnym normatywnym oracle.

W etapie 22 nie istnieje jeszcze `orderAt46Latch`. Dopiero Stage 23 ma po drop 46 i przed post-stir 1 wykonać dokładnie jeden `orderAt46Latch = clone(order46)`, nigdy nie zapisywać latch podczas post-stirs i skierować `queryOrder` wyłącznie do latcha. Jednocześnie legacy overwritable memory oraz wszystkie 58 historycznych writes muszą pozostać fizycznie zachowane.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 23 — PATCH 11: orderAt46Latch

Historyczny `LegacyOverwritableOrderMemory` pozostaje fizycznie bez zmian. Nadal otrzymuje 46 zapisów order podczas visible drops i 12 kolejnych podczas post-stirs, czyli dokładnie 58 historycznych writes. Jego końcowa wartość nadal pochodzi z `post-stir 12`.

Dodano osobny `OrderAt46LatchPatch`. Bezpośrednio po zapisaniu order dla drop 46, a jeszcze przed rozpoczęciem post-stir 1, wykonywany jest dokładnie jeden `captureOnce(order46)`. Latch przechowuje własny snapshot sześciu bowl IDs.

Latch jest jednokrotny. Drugie `captureOnce` jest błędem, a query przed pierwszym capture również jest błędem. Pętla 12 post-stirs nigdy nie zapisuje do latcha.

`OrderAt46CompatibilityRoute` nadal wykonuje wszystkie 58 zapisów do historycznej pamięci i zachowuje jej końcową wartość oraz ostatnie źródło jako obserwowalną bliznę. Zmienia się wyłącznie źródło publikowanego `queryOrder`: od PATCH 11 odpowiedź pochodzi wyłącznie z `orderAt46Latch`.

Dla Foundation raw legacy memory nadal kończy się wartością `1,6,5,2,4,3` z post-stir 12, natomiast publikowany order pozostaje poprawnym snapshotem drop 46: `4,5,2,3,6,1`.

Niezmieniony regression Stage 22 ma po tej zmianie przejść na GREEN. Test Stage 23 dodatkowo sprawdza semantykę jednokrotnego capture, niezależność snapshotu, zakaz drugiego zapisu, zachowanie wszystkich 58 legacy writes oraz niezmienione final bowls.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 24 — DISCOVERY 12: fixed-name successor

Dodano dwunasty historyczny defekt. PATCH 11 nadal poprawnie zachowuje i publikuje `orderAt46Latch`, lecz downstream consumer wyznacza następną bowl według stałych nazw numerycznych, a nie według pozycji w latchu.

`LegacyFixedNameSuccessor.next(id)` implementuje dokładnie stały pierścień:

`1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1`.

Funkcja w ogóle nie czyta `orderAt46Latch`.

Dla Foundation latch wynosi `4,5,2,3,6,1`. Normatywny successor jest więc następnym elementem tej właśnie kolejności: `1->4`, `2->3`, `3->6`, `4->5`, `5->2`, `6->1`. Fixed-name legacy rozchodzi się dokładnie dla IDs `1,3,5`.

Historyczny publiczny consumer pyta o bowl znajdującą się na pozycji 4 latcha. Dla Foundation jest to ID `3`. Legacy zwraca `4`, podczas gdy poprawny successor w latched order wynosi `6`.

`NextBowlCompatibilityRoute` zapisuje latched order, queried ID i surowy legacy successor osobno. W etapie 24 publikuje jeszcze surowy fixed-name result, dlatego stan jest `EXPECTED_RED`.

W etapie 24 nie istnieje jeszcze latched successor patch. Dopiero Stage 25 ma pozostawić `LegacyFixedNameSuccessor` fizycznie bez zmian i wykonywać go jako diagnostyczną bliznę, natomiast semantic path ma znaleźć pozycję `queriedBowlId` w `orderAt46Latch` i zwrócić następny element z zawijaniem na początek.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 25 — PATCH 12: latched successor

Historyczny `LegacyFixedNameSuccessor` pozostaje fizycznie bez zmian. Nadal wyznacza successor według stałego pierścienia nazw `1->2->3->4->5->6->1` i nadal jest wykonywany jako obserwowalna blizna Discovery 12.

Dodano osobny `LatchedSuccessorPatch`. Patch nie modyfikuje order ani nazw bowl. Otrzymuje poprawny `orderAt46Latch` oraz `queriedBowlId`, znajduje dokładną pozycję queried ID w latchu, a następnie zwraca element z następnej pozycji. Pozycja szósta zawija się do pierwszej.

`NextBowlCompatibilityRoute` najpierw wykonuje surowy `LegacyFixedNameSuccessor.next(id)` i zachowuje wynik w kontekście. Następnie publikowany successor jest obliczany przez `LatchedSuccessorPatch`.

Dla Foundation latch `4,5,2,3,6,1` daje mapę successor `1->4`, `2->3`, `3->6`, `4->5`, `5->2`, `6->1`. Historyczna fixed-name mapa `1->2`, `2->3`, `3->4`, `4->5`, `5->6`, `6->1` pozostaje zachowana i nadal rozchodzi się dla IDs `1,3,5`.

Niezmieniony regression Stage 24 ma po tej zmianie przejść na GREEN. Test Stage 25 sprawdza wszystkie sześć IDs kontrolowanego Foundation latch, jawne zawinięcie ostatniej pozycji oraz wszystkie 720 możliwych permutacji order dla wszystkich sześciu queried IDs.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 26 — DISCOVERY 13: biased legacy pick modulo

Dodano trzynasty historyczny defekt. Po utworzeniu normatywnego answer ring historyczny selector natychmiast przekazuje pierwszą odpowiedź `x` do:

`biasedLegacyPick(x,N) = regularMod(x-1,N)+1`.

Nie istnieje jeszcze rejection.

To mapowanie jest obciążone, gdy rozmiar answer ring `M` nie jest wielokrotnością `N`. Dla kontrolowanego `N=922` zachodzi `M mod 922 = 221`, więc bez rejection rangi 1..221 otrzymują o jeden punkt pierścienia więcej niż pozostałe rangi.

Dodano `AnswerRingStreamFactory`, który buduje `first` i `directionStep` zgodnie z normatywną formułą pytanej misy, oraz udostępnia `answerAt(offset)` jako ruch po jednym i tym samym pierścieniu rozmiaru M. Ta warstwa nie dokonuje wyboru ani rejection.

Regresja Discovery 13 używa celowego witnessa syntetycznego: `first = limit+1`, `directionStep=-1`, `N=922`, gdzie `limit=floor(M/N)*N`. Legacy natychmiast mapuje `limit+1` na rank `1`. Normatywna ścieżka odrzuca tę odpowiedź, wykonuje dokładnie jeden krok na tym samym answer ring do `x=limit`, a dopiero wtedy mapuje wynik na rank `922`.

`SmallPickCompatibilityRoute` zapisuje surowe `x`, `N` i legacy rank w kontekście i w Stage 26 publikuje jeszcze bezpośrednio surowy biased rank. Stan jest więc celowo `EXPECTED_RED`.

W etapie 26 nie istnieje jeszcze rejection patch. Dopiero Stage 27 ma zachować `LegacyBiasedPick` fizycznie bez zmian, obliczyć `limit=floor(M/N)*N`, przesuwać offset na tym samym answer ring aż `x<=limit`, i dopiero wtedy wywołać `biasedLegacyPick(x,N)`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 27 — PATCH 13: rejection on answer ring

Historyczny `LegacyBiasedPick` pozostaje fizycznie bez zmian. Nadal implementuje wyłącznie `regularMod(x-1,N)+1` i nadal jest wykonywany na pierwszej odpowiedzi jako obserwowalna blizna Discovery 13.

Dodano osobny `AnswerRingRejectionPatch`. Dla krótkiego wyboru `1 <= N <= M` patch oblicza:

`acceptanceLimit = floor(M/N) * N`.

Następnie zaczyna od offsetu 0 i pobiera odpowiedzi wyłącznie przez `AnswerRingStreamFactory.answerAt(stream, offset)`. Jeżeli `x > acceptanceLimit`, offset jest zwiększany o jeden i pobierana jest następna odpowiedź z tego samego ring. Nie tworzy się nowego streamu, nie oblicza ponownie first i nie losuje nowego kierunku.

Dopiero pierwsze `x <= acceptanceLimit` jest przekazywane do niezmienionego `LegacyBiasedPick.pick(x,N)`. Dzięki temu modulo legacy staje się poprawnym ostatnim krokiem po bezstronnym rejection.

`SmallPickCompatibilityRoute` najpierw wykonuje i zachowuje surowe x oraz raw rank Discovery 13. Następnie osobno wykonuje PATCH 13 i publikuje wynik po rejection.

Niezmieniony regression Stage 26 ma po tej zmianie przejść na GREEN. Test Stage 27 sprawdza witness jednego rejection, brak rejection, zawinięcie `M -> 1` w kierunku dodatnim, 17 kolejnych rejection na jednym ring oraz kilka różnych rozmiarów N w porównaniu z lokalnym normatywnym oracle.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 28 — DISCOVERY 14: short-only selector

Dodano czternasty historyczny defekt. PATCH 13 pozostaje zielonym i poprawnym selektorem dla `1 <= N <= M`, ale nowy general-selection dispatcher błędnie zakłada, że każdy dodatni rozmiar rodziny jest wyborem krótkim.

`LegacyShortOnlySelectionDispatcher` przekazuje więc także `N>M` bezpośrednio do `SmallPickCompatibilityRoute`. Nie istnieje rozgałęzienie na wide selection, nie oblicza się `places`, `space`, cyfr wide ani wide rejection.

Gdy short route odrzuca `N>M` błędem `Pastafari:Selection:LegacyShortAssumption`, dispatcher zachowuje invocation-local historyczną bliznę: `legacyWideSelectionUnsupported=true`, identyfikator błędu oraz pusty `legacyGeneralSelectionResult`.

`GeneralSelectionCompatibilityRoute` w etapie 28 publikuje dokładnie wynik legacy dispatchera. Dla wide request jest to więc wynik pusty, podczas gdy normatywny oracle posiada dokładny wide rank.

Regresja używa jednego prostego answer ring `first=1`, `directionStep=+1` i trzech rozmiarów: `M+1`, `M^2` oraz `M^3`. Wszystkie trzy muszą być `EXPECTED_RED`, a kontrolny `N=922` musi nadal przechodzić poprawnie przez PATCH 13.

W etapie 28 nie ma jeszcze żadnej wide arithmetic ani wide detour. Dopiero Stage 29 ma zachować cały raw short-only failure jako bliznę, a dla `N>M` zbudować minimalną liczbę `places` z `space=M^places>=N`, odczytać cyfry z tego samego answer ring, zbudować little-endian wide value i wykonać rejection w przestrzeni `space`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 29 — PATCH 14: wide detour

Historyczny `LegacyShortOnlySelectionDispatcher` pozostaje fizycznie bez zmian. Nadal kieruje każde dodatnie `N`, także `N>M`, do short selector PATCH 13. Dla wide request nadal zachowuje `legacyWideSelectionUnsupported=true`, błąd `Pastafari:Selection:LegacyShortAssumption` oraz pusty raw result.

Dodano osobny `WideSelectionDetourPatch`. Patch jest używany wyłącznie dla `N>M`. Najpierw wybiera minimalne `places`, dla którego `space=M^places >= N`.

Następnie czyta dokładnie `places` kolejnych odpowiedzi z tego samego answer ring. Każda cyfra ma postać `answerAt(stream,j)-1` i należy do `0..M-1`. Wide value jest składane little-endian:

`wide = 1 + Σ digit_j * M^j`.

Po zbudowaniu wide value patch oblicza:

`acceptanceLimit = floor(space/N) * N`.

Jeżeli wide przekracza limit, nie tworzy nowego streamu i nie przebudowuje cyfr. Zamiast tego przesuwa bieżące `w` o `directionStep` w tym samym szerokim pierścieniu `1..space`, z zawijaniem modulo `space`, aż `w<=acceptanceLimit`.

Zaakceptowany wide rank jest następnie mapowany przez `regularMod(w-1,N)+1`.

`GeneralSelectionCompatibilityRoute` zawsze najpierw wykonuje surowy Stage 28 dispatcher. Dla `N<=M` publikowany wynik pozostaje dokładnie istniejącą zieloną ścieżką PATCH 13. Dla `N>M` raw unsupported scar pozostaje nienaruszony, ale publikowany wynik pochodzi z `WideSelectionDetourPatch`.

Niezmieniony regression Stage 28 ma po tej zmianie przejść na GREEN. Test Stage 29 sprawdza witnesses `M+1`, `M^2`, `M^3`, minimalność `places`, zachowanie raw unsupported scar, short passthrough oraz dokładny witness jednego wide rejection względem lokalnego normatywnego oracle.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 30 — DISCOVERY 15: positive-only gate question

Dodano piętnasty historyczny defekt. Po raz pierwszy ścieżka produkcyjna zaczyna pytać o odstępy bram po obu stronach Foundation.

`GateQuestionEngine` jest warstwą neutralną względem znaku. Otrzymuje już konkretny target day, buduje aktualny sauce dla `Foundation -> target`, pyta bowl 1 z seal 1, wybiera jedną z 922 dróg przez aktualny general selector i zwraca `41 + chosen`.

Historyczny błąd znajduje się w `LegacyPositiveOnlyGateQuestion`. Dla signed step `+n` pyta poprawnie `Foundation+n`. Dla signed step `-n` ignoruje znak i również pyta `Foundation+n`, czyli używa `Foundation+abs(step)`.

`GateGapCompatibilityRoute` w Stage 30 publikuje dokładnie wynik tej legacy warstwy. Dodatnie bramy są więc poprawne przypadkiem, a ujemne są lustrzanie błędne.

Kontrolne wartości wynikające z normatywnej ścieżki rozróżniają znak natychmiast: dla `n=1` dodatni gap wynosi `345`, a ujemny `503`; dla `n=2` odpowiednio `818` i `441`; dla `n=3` odpowiednio `831` i `329`.

Regresja Stage 30 wymaga, aby raw legacy question day i raw legacy gap dla `-n` pozostały identyczne z dodatnim `+n`. Jednocześnie publikowany wynik jest porównywany z prawdziwym pytaniem `Foundation-n`, dzięki czemu Stage 30 jest celowo `EXPECTED_RED`.

Dopiero Stage 31 ma pozostawić `LegacyPositiveOnlyGateQuestion` fizycznie bez zmian jako bliznę, ale dla semantic path zbudować signed question day dokładnie jako `Foundation+signedStep`. Dla kroku ujemnego jest to `Foundation-abs(step)`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 31 — PATCH 15: signed gate question

Historyczny `LegacyPositiveOnlyGateQuestion` pozostaje fizycznie bez zmian. Nadal ignoruje znak kroku i dla `signedStep=-n` pyta `Foundation+n`, zachowując mirrored positive day i positive gap jako obserwowalną bliznę Discovery 15.

Dodano osobny `SignedGateQuestionPatch`. Semantic question day jest budowany dokładnie jako:

`questionDay = Foundation + signedStep`.

Dla `+n` zachowanie pozostaje identyczne z dotychczasową poprawną ścieżką dodatnią. Dla `-n` pytanie trafia do `Foundation-n`, bez użycia `abs` i bez lustrzanego przejścia na stronę dodatnią.

Sam `GateQuestionEngine` pozostaje bez zmian. Otrzymuje konkretny signed target day i wykonuje ten sam sauce/answer-ring/general-selection pipeline co wcześniej.

`GateGapCompatibilityRoute` najpierw wykonuje surowe positive-only pytanie i zachowuje jego question day oraz gap w polach legacy. Następnie osobno wykonuje `SignedGateQuestionPatch` i publikuje signed question day oraz signed gap.

Niezmieniony regression Stage 30 ma po tej zmianie przejść na GREEN. Test Stage 31 sprawdza `±1`, `±2`, `±3`, zachowanie dokładnych fixture gaps, obecność obu trace/metrics, odrzucenie kroku zero oraz fizyczne zachowanie historycznego mirrored wyniku dla `-1`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 32 — DISCOVERY 16: legacy year max 5781

Dodano szesnasty historyczny defekt w warstwie kandydatów roku.

Normatywne `validYearPair` wymaga co najmniej sześciu odstępów bram oraz długości roku od `252` do `5778` dni. Historyczny generator zachowuje poprawne minimum i minimalny gate span, lecz używa błędnego maksimum `5781`.

Dodano `LegacyYearMax5781Filter`. Kandydat jest mierzony przez:

`gateSpan = closeGateIndex - openGateIndex`

oraz

`lengthDays = closeGateDay - openGateDay`.

Legacy przyjmuje kandydata, gdy `gateSpan>=6`, `lengthDays>=252` i `lengthDays<=5781`.

`YearCandidateCompatibilityRoute` w Stage 32 publikuje jeszcze dokładnie tę surową listę. Nie istnieje jeszcze żaden late max-5778 filter.

Regresja używa kandydatów o długościach `251,252,5778,5779,5780,5781,5782` oraz osobnego kandydata o poprawnej długości, lecz z gate span `5`. Historyczna lista zawiera `252,5778,5779,5780,5781`; normatywna lista zawiera wyłącznie `252,5778`. Historyczna blizna składa się więc dokładnie z `5779,5780,5781`.

Stage 32 celowo nie implementuje jeszcze Year 5000 ani jego tie-breaking. Ta warstwa jedynie ustanawia listę kandydatów, na której będą pracować kolejne etapy.

Dopiero Stage 33 ma pozostawić `LegacyYearMax5781Filter` fizycznie bez zmian i zachować jego pełną raw listę, a następnie zastosować osobny late filter `lengthDays<=5778` przed publikacją kandydatów.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 33 — PATCH 16: late 5778 filter

Historyczny `LegacyYearMax5781Filter` pozostaje fizycznie bez zmian. Nadal generuje kandydatów z długością do `5781` dni i nadal zachowuje `5779`, `5780` oraz `5781` w pełnej raw liście Discovery 16.

Dodano osobny `YearMax5778LateFilter`. Otrzymuje on dopiero listę, która już przeszła przez historyczny generator. Nie regeneruje kandydatów, nie sortuje ich i nie wykonuje żadnego wyboru roku.

Late filter mierzy wyłącznie:

`lengthDays = closeGateDay - openGateDay`

i zachowuje kandydata wtedy i tylko wtedy, gdy `lengthDays<=5778`.

Kolejność kandydatów jest zachowywana dokładnie. Kandydaci `5779`, `5780` oraz `5781` pozostają obserwowalni w `legacyYearCandidatesAccepted` i `legacyYearCandidateLengths`, lecz nie trafiają do publikowanego `yearCandidatesCandidate`.

`YearCandidateCompatibilityRoute` najpierw wykonuje raw generator max-5781 i zapisuje pełną historyczną listę. Następnie osobno wykonuje PATCH 16 i publikuje dopiero late-filtered listę.

Niezmieniony regression Stage 32 ma po tej zmianie przejść z EXPECTED_RED do GREEN. Test Stage 33 sprawdza dokładne boundary `5778/5779`, zachowanie kolejności, usunięcie dokładnie `5779..5781`, obecność obu trace/metrics oraz fizyczne zachowanie `LegacyYearMax5781Filter`.

Stage 33 celowo nie dodaje jeszcze sortowania ani wyboru Year 5000. Dopiero Stage 34 wprowadzi historyczny tie defect przy sortowaniu kandydatów roku 5000.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 34 — DISCOVERY 17: Year 5000 tie

Dodano siedemnasty historyczny defekt w porządkowaniu kandydatów roku 5000.

Kandydaci wejściowi najpierw przechodzą przez PATCH 16, więc kandydaci dłużsi niż `5778` nie biorą udziału w tej warstwie.

Historyczny `LegacyYear5000StableLengthSort` wykonuje jawny stabilny sort wyłącznie po `lengthDays = closeGateDay-openGateDay`. Dla różnych długości kolejność jest poprawna: krótszy kandydat stoi wcześniej.

Błąd występuje wyłącznie przy równej długości. Stabilność zachowuje wtedy pierwotną kolejność wejściową, zamiast normatywnego drugiego klucza: rosnącego opening gate.

Regresja zawiera dwie niezależne tie runs. Dla input IDs `1,2,3,4,5,6` historyczny stable-length order wynosi `2,4,1,3,5,6`, natomiast normatywny order `length ASC, opening gate ASC` wynosi `4,2,3,5,1,6`.

`Year5000OrderingCompatibilityRoute` w Stage 34 zachowuje input listę oraz raw stable-length order i publikuje jeszcze dokładnie ten historyczny order. Stan jest więc celowo `EXPECTED_RED`.

Stage 34 nie wykonuje jeszcze wyboru rank Year 5000. Izoluje wyłącznie porządkowanie listy, tak aby następny patch nie mógł zmienić innych części wyboru.

Dopiero Stage 35 ma pozostawić `LegacyYear5000StableLengthSort` fizycznie bez zmian, a po jego wykonaniu posortować wyłącznie contiguous equal-length runs po opening gate. Kandydaci z różnymi długościami nie mogą zostać ponownie globalnie przemieszani.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 35 — PATCH 17: tie run sort

Historyczny `LegacyYear5000StableLengthSort` pozostaje fizycznie bez zmian. Nadal wykonuje stabilny sort wyłącznie po `lengthDays`, a przy ties zachowuje kolejność wejściową jako obserwowalną bliznę Discovery 17.

Dodano osobny `Year5000TieRunSortPatch`. Patch otrzymuje już listę po historycznym length-only sort i najpierw potwierdza, że długości są niemalejące.

Następnie wykrywa wyłącznie contiguous runs kandydatów o identycznym `lengthDays`. Każdy taki run jest stabilnie sortowany po `openGateDay` rosnąco. Kandydaci należący do różnych długości nie są ponownie globalnie sortowani ani przemieszczani między runs.

Jeżeli dwa kandydaty mają również identyczny `openGateDay`, zachowana zostaje ich kolejność wejściowa.

`Year5000OrderingCompatibilityRoute` zawsze najpierw wykonuje raw legacy sorter i zapisuje `legacyYear5000StableLengthOrder`. Następnie osobno wykonuje PATCH 17 i publikuje patched order w `year5000CandidateOrder`.

Niezmieniony regression Stage 34 ma po tej zmianie przejść z EXPECTED_RED do GREEN. Dla głównego fixture raw order pozostaje `2,4,1,3,5,6`, a publikowany order staje się `4,2,3,5,1,6`.

Test Stage 35 sprawdza dwie niezależne tie runs, niezmienione membership i length-run boundaries, już poprawny run, stabilność przy identycznym opening gate, odrzucenie wejścia nieposortowanego po długości oraz fizyczne zachowanie legacy sorter.

Stage 35 nadal nie wykonuje wyboru rank Year 5000 ani wyszukiwania następnych/poprzednich lat. Kolejny etap wprowadzi historyczny old-year jump guess by 365.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 36 — DISCOVERY 18: old year jump guess by 365

Dodano osiemnasty historyczny defekt w wyszukiwaniu roku zawierającego odległy target day.

Historyczna `LegacyOldYearJumpGuess` nie chodzi po kolejnych rzeczywistych latach. Zamiast tego traktuje rok jako przybliżenie 365-dniowe i oblicza bezpośrednio:

`guessOffset365 = floor((targetDay - anchor.openGateDay) / 365)`

oraz

`guessedYearNumber = anchor.number + guessOffset365`.

Następnie wybiera od razu rok o tym numerze z dostępnego łańcucha. Nie sprawdza po drodze rzeczywistych granic kolejnych lat.

Dla bliskich targetów wokół anchor Year 5000 defect może pozostać niewidoczny. Regression zawiera więc controls, w których `4999`, `5000` i `5001` są trafiane poprawnie.

Dla odległych targetów zmienne długości lat kumulują drift. W kontrolowanym łańcuchu przyszły target `1500` należy do roku `5003`, ale `/365` wybiera `5004`. Analogicznie target `-1200` należy do `4997`, lecz raw guess wybiera `4996`.

`TargetYearCompatibilityRoute` w Stage 36 publikuje jeszcze bezpośrednio raw guessed year i zapisuje pełną telemetrię: anchor number/open day, target, delta days, `/365` offset, guessed number oraz guessed year.

Stage 36 celowo nie implementuje jeszcze sequential walk. Dopiero Stage 37 ma zachować całą raw guess telemetry i raw guessed year jako historyczną bliznę, ale semantic path ma zaczynać od anchor year i chodzić `next` lub `previous` dokładnie po jednym rzeczywistym roku, dopóki target nie spełni przedziału `(openGateDay, closeGateDay]`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 37 — PATCH 18: sequential year walk

Historyczny `LegacyOldYearJumpGuess` pozostaje fizycznie bez zmian. Nadal oblicza numer przez `anchor.number + floor((targetDay-anchor.openGateDay)/365)` i raw guessed year wraz z pełną telemetrią pozostają obserwowalną blizną Discovery 18.

Dodano osobny `SequentialYearWalkPatch`.

Semantic path zaczyna dokładnie od anchor year. Jeżeli `targetDay > current.closeGateDay`, przechodzi do roku o numerze `current.number+1`. Jeżeli `targetDay <= current.openGateDay`, przechodzi do roku o numerze `current.number-1`.

Każdy krok obejmuje dokładnie jeden rzeczywisty rok. Patch nie przeskakuje numerów i sprawdza, że granica następnego roku styka się z bieżącym close, a granica poprzedniego z bieżącym open.

Spacer kończy się wyłącznie wtedy, gdy target spełnia normatywny przedział:

`openGateDay < targetDay <= closeGateDay`.

`TargetYearCompatibilityRoute` zawsze najpierw wykonuje raw `/365` guess i zachowuje anchor, delta, offset, guessed number oraz raw guessed year. Następnie osobno wykonuje PATCH 18 i publikuje wynik sequential walk w `targetYearCandidate`.

Niezmieniony regression Stage 36 ma po tej zmianie przejść z EXPECTED_RED do GREEN. Dla przyszłego target `1500` raw guess pozostaje `5004`, ale publikowany rok staje się `5003`; dla target `-1200` raw guess pozostaje `4996`, ale publikowany rok staje się `4997`.

Test Stage 37 sprawdza również lokalne lata `4999/5000/5001`, dokładne granice `(open,close]`, liczbę kroków forward/backward, brakujący kolejny numer roku, niespójną granicę sąsiadów oraz fizyczne zachowanie LegacyOldYearJumpGuess.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 38 — DISCOVERY 19: bad year cache key

Dodano dziewiętnasty historyczny defekt: process-persistent cache struktury roku keyed wyłącznie przez `year.number`.

`LegacyYearNumberStructureCache` przechowuje pod tym złym kluczem pełny entry zawierający:

`calculationDayFingerprint`,
`openGate`,
`closeGate`,
`value`.

Te pola istnieją już w entry, lecz historyczny `getRaw` ich nie sprawdza. O trafieniu decyduje wyłącznie obecność wpisu o tym samym numerze roku.

`YearStructureCacheCompatibilityRoute` najpierw wykonuje raw lookup. Przy miss uruchamia producenta struktury i zapisuje entry. Przy hit w Stage 38 publikuje od razu raw cached value, bez sprawdzania calculationDay fingerprint ani obu gate days.

Regresja najpierw wykonuje cold fill dla roku 5000 i `calculationDay=111`, a następnie poprawny warm hit dla tego samego kontekstu. Potem wykonuje drugi request dla tego samego `year.number=5000` i tych samych gates, lecz `calculationDay=222`.

Raw cache nadal trafia w entry pierwszego calculationDay i zwraca strukturę A zamiast oczekiwanej struktury B. Stage 38 jest więc celowo `EXPECTED_RED`.

Regression został przygotowany tak, aby Stage 39 nie usuwał historycznej blizny: także po patchu raw lookup musi nadal raportować hit, fingerprint 111 oraz stale value A. Zmienić ma się wyłącznie publikowany semantic value.

Dopiero Stage 39 ma zachować fizyczny key `year.number`, ale dopuścić semantic cache hit tylko wtedy, gdy jednocześnie zgadzają się `calculationDayFingerprint`, `openGate` i `closeGate`. W przeciwnym razie ma nastąpić miss, recompute oraz transactional overwrite tego samego złego key.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 39 — PATCH 19: guarded cache

Historyczny `LegacyYearNumberStructureCache` pozostaje fizycznie bez zmian. Process-persistent map nadal jest keyed wyłącznie przez `year.number`, więc sam raw lookup nadal może trafić w entry należący do innego kontekstu obliczeniowego.

Dodano osobny `GuardedYearCachePatch`.

Semantic cache hit jest uznawany za poprawny wyłącznie wtedy, gdy jednocześnie zgadzają się trzy pola istniejącego entry:

`calculationDayFingerprint`,
`openGate`,
`closeGate`.

Fizyczny key nie zostaje rozszerzony ani zmieniony.

`YearStructureCacheCompatibilityRoute` zawsze najpierw wykonuje historyczny raw lookup i zachowuje jego key, hit, stale value oraz guard fields jako obserwowalną bliznę Discovery 19.

Następnie PATCH 19 sprawdza guard. Jeżeli wszystkie trzy pola są zgodne, istniejący cached value może zostać ponownie użyty bez uruchamiania producenta.

Jeżeli choć jedno pole jest różne albo raw entry nie istnieje, semantic path traktuje lookup jako miss. Najpierw oblicza nową wartość przez producer. Dopiero po pomyślnym zakończeniu obliczenia nadpisuje ten sam historyczny `year.number` entry nowym fingerprintem, gates i value.

Takie uporządkowanie zapewnia transactional overwrite na poziomie tej warstwy: jeżeli producer zgłosi błąd, dotychczasowy cache entry pozostaje nienaruszony.

Niezmieniony regression Stage 38 ma po tej zmianie przejść z EXPECTED_RED do GREEN. Dla requestu `calculationDay=222` raw hit nadal pokazuje fingerprint `111` oraz stale value `A`, ale publikowany semantic result staje się `B`, a fizyczny entry zostaje następnie nadpisany danymi kontekstu 222.

Test Stage 39 sprawdza osobno mismatch fingerprintu, mismatch `openGate`, mismatch `closeGate`, prawidłowy guarded warm hit, zachowanie starego entry przy błędzie producenta oraz fakt, że fizyczny key nadal pozostaje historycznie błędnym `year.number`.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 40 — DISCOVERY 20: old structure sauce target

Dodano dwudziesty historyczny defekt w budowaniu sauce używanego do struktury roku.

Wspólna funkcja `sauceWithCurrentScars(cDay,targetDay)` wykonuje aktualny naprawiony pipeline sauce dla dokładnie przekazanej pary `(c,t)`. Nie interpretuje roli targetu.

Historyczna funkcja `oldStructureSauce(cDay,originalTargetDay)` pozostaje osobną, realnie wykonywaną warstwą. Wywołuje sauce z oryginalnym targetem zapytania użytkownika.

To jest wada: struktura konkretnego roku musi być determinowana przez sauce dla pierwszego dnia tego roku. Przy reprezentacji roku przez opening gate normatywny pierwszy dzień wynosi:

`firstDayOfYear = openGateDay + 1`.

`StructureSauceCompatibilityRoute` zna zarówno `originalTargetDay`, jak i `yearFirstDay`, ale w Stage 40 nadal publikuje wyłącznie wynik `oldStructureSauce(cDay,originalTargetDay)`.

Regression zawiera trzy dokładne witnesses, mierzone przez finalny `bowl 2`.

1. `cDay=-15055671`, `originalTarget=-15055668`, `yearFirstDay=-15050770`: raw bowl2 `30490712077192838912252735934522861502`, authoritative bowl2 `25571125800832315000523776987293072647`.

2. `cDay=-15055664`, `originalTarget=-15055666`, `yearFirstDay=-15055564`: raw bowl2 `44486119807401318534404702377176765242`, authoritative bowl2 `163498808332082587884523302982947090138`.

3. `cDay=-15055682`, `originalTarget=-15055677`, `yearFirstDay=-15055782`: raw bowl2 `115056314572464196578969473149772288830`, authoritative bowl2 `73239755307544431731595307996239836106`.

Wartości authoritative są dodatkowo porównywane z lokalnym normatywnym oracle `sauce(cDay,firstDayOfYear)`.

Stage 40 zachowuje także control, w którym `originalTargetDay==firstDayOfYear`; wtedy stary i normatywny sauce są identyczne.

Stan Stage 40 jest celowo `EXPECTED_RED`. `oldStructureSauce` nie jest naprawiany ani przekierowywany.

Dopiero Stage 41 ma najpierw wykonać dokładnie ten sam historyczny ghost call, zachować jego target/bowl2/orderAt46 jako bliznę, a następnie dla semantic path użyć sauce z `firstDayOfYear`. Jeżeli original target już jest first day, patch może wykorzystać ten sam ghost result bez ponownego liczenia.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 41 — PATCH 20: structure sauce detour

Historyczny `oldStructureSauce(cDay,originalTargetDay)` pozostaje fizycznie bez zmian i nadal jest realnie wykonywany przy każdym przejściu przez `StructureSauceCompatibilityRoute`.

Jego target, finalny `bowl2` oraz `orderAt46` pozostają zapisane w polach legacy jako obserwowalna blizna Discovery 20.

Dodano osobny `StructureSauceDetourPatch`.

Autorytatywny target do budowania struktury roku jest wyliczany wyłącznie jako:

`firstDayOfYear = openGateDay + 1`.

Jeżeli `originalTargetDay` różni się od `firstDayOfYear`, semantic path wykonuje osobny:

`Sauce(cDay,firstDayOfYear)`

przez neutralny `sauceWithCurrentScars`.

Jeżeli `originalTargetDay==firstDayOfYear`, historyczny ghost jest już dokładnie właściwym sauce i może zostać użyty ponownie bez drugiego obliczenia.

`StructureSauceCompatibilityRoute` zawsze wykonuje ghost jako pierwszy, zapisuje jego pełną bliznę, a dopiero potem publikuje wynik PATCH 20 w `structureSauceCandidate` i `structureSauceBowl2Candidate`.

Niezmieniony regression Stage 40 ma po tej zmianie przejść z EXPECTED_RED do GREEN.

Test Stage 41 sprawdza wszystkie trzy dokładne witnesses Stage 40, porównuje wszystkie sześć bowls i `orderAt46` z normatywnym oracle, sprawdza niezależność struktury tego samego roku od dwóch różnych original targets oraz potwierdza reuse przy `originalTargetDay==firstDayOfYear`.

`oldStructureSauce` nie jest przekierowywany, usuwany ani zastępowany.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 42 — DISCOVERY 21: unfiltered cutlet partitions

Dodano dwudziesty pierwszy historyczny defekt w rodzinie podziałów kotletów.

`LegacyAllPositiveCutletPartitionFamily` reprezentuje wszystkie dodatnie kompozycje `gapCount` na dokładnie `cutletCount` części, w porządku leksykograficznym. Rodzina celowo nie zna `internalGateOffset`.

`LegacyCutletPartitionAdapter` wybiera rank z pełnej rodziny przez istniejący general selection pipeline i wykonuje leksykograficzne unrank. Adapter również nie przyjmuje żadnego internal gate.

`CutletPartitionCompatibilityRoute` zna i zapisuje `internalGateOffset`, ale Stage 42 nie przekazuje go ani do generatora rodziny, ani do raw selection. Publikowany wynik jest więc nadal surowym wynikiem historycznym.

Normatywny warunek jest inny: jeżeli `calculationDay` wypada dokładnie na wewnętrznym gate roku, wybrana kompozycja musi zawierać ten gate jako granicę między kotletami. Dla offsetu względem opening gate oznacza to, że jakiś wewnętrzny prefix sum kompozycji musi być dokładnie równy `internalGateOffset`.

Główny witness ma `gapCount=10`, `cutletCount=8`, `internalGateOffset=4`.

Pełna legacy family ma `36` elementów. Kontrolowany answer-ring stream z `first=87` wybiera z niej rank `15`, czyli:

`[1,1,1,3,1,1,1,1]`.

Jej kolejne prefix sums wynoszą `1,2,3,6,7,8,9`, więc nie zawiera wymaganej granicy `4`.

Normatywna rodzina jest dokładnie leksykograficzną subsekwencją legacy family zawierającą prefix sum `4`; ma `28` elementów. Ten sam stream wybiera z niej rank `3`, czyli:

`[1,1,1,1,1,1,3,1]`.

Stage 42 pozostaje celowo `EXPECTED_RED`.

Regression zachowuje descriptor pełnej legacy family, raw count `36`, raw rank `15` oraz raw partition jako obserwowalną bliznę. Jest również control bez wewnętrznego gate; w takim przypadku również przyszły PATCH 21 ma przepuścić raw selection bez filtrowania.

Dopiero Stage 43 ma pozostawić `LegacyAllPositiveCutletPartitionFamily` oraz `LegacyCutletPartitionAdapter` fizycznie bez zmian i uruchamiać je diagnostycznie jako pierwsze. Semantic family ma być dokładnie leksykograficzną subsekwencją legacy family, której prefix sum trafia w wymagany internal gate offset.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 43 — PATCH 21: filtered partition family

Historyczne `LegacyAllPositiveCutletPartitionFamily` oraz `LegacyCutletPartitionAdapter` pozostają fizycznie bez zmian.

Każde przejście przez `CutletPartitionCompatibilityRoute` nadal wykonuje pełną raw family i raw selection jako pierwsze. Descriptor, count, rank oraz selected partition pozostają zapisane jako obserwowalna blizna Discovery 21.

Dodano `FilteredLegacyCutletPartitionFamily`.

Jeżeli istnieje `internalGateOffset`, semantic family jest dokładnie leksykograficznym podciągiem raw all-positive family, zawierającym tylko kompozycje, których właściwy prefix sum jest równy wymaganej granicy.

Rodzina produkcyjna nie jest materializowana. Jej count wynosi kombinatorycznie:

`C(gapCount-2, cutletCount-2)`.

`unrank1` skanuje możliwe wartości kolejnych części w tym samym porządku co legacy family i oblicza rozmiar każdego legalnego descendant block. Dzięki temu zachowuje dokładnie kolejność filtrowanej subsekwencji bez budowania pełnej listy.

Dodano `CutletPartitionGatePatchWrapper`.

Gdy internal gate istnieje, wrapper wykonuje wybór rank ponownie nad filtrowanym count i unrankuje z `FilteredLegacyCutletPartitionFamily`.

Gdy internal gate nie istnieje, wrapper nie wykonuje drugiego wyboru: reuse dokładnie raw rank, raw partition, raw count i raw descriptor.

Dla głównego witness `gapCount=10`, `cutletCount=8`, `offset=4` raw scar pozostaje `count=36`, `rank=15`, `[1,1,1,3,1,1,1,1]`, natomiast semantic path używa `count=28`, `rank=3` i publikuje `[1,1,1,1,1,1,3,1]`.

Dodatkowy witness `gapCount=10`, `cutletCount=3`, `offset=4` potwierdza count `8`; filtered rank 1 daje `[1,3,6]`, a rank 8 daje `[4,5,1]`.

Niezmieniony regression Stage 42 ma po tej zmianie przejść z EXPECTED_RED do GREEN.

Stage 43 nie dodaje żadnej logiki nazw kotletów. Dopiero Stage 44 rozpocznie osobny historyczny defekt repeated cutlet names.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 44 — DISCOVERY 22: repeated names

Dodano dwudziesty drugi historyczny defekt: nazwy kotletów są wybierane z rodziny, która dopuszcza powtarzanie tego samego `canonicalIndex` w obrębie jednego roku.

`LegacyRepeatedNameGenerator` definiuje rodzinę `masterCount^K` sekwencji. Każda z `K` pozycji wybiera niezależnie indeks `1..masterCount`. Unrank interpretuje `rank-1` jako `K` cyfr base-`masterCount`, z ostatnią pozycją jako najmniej znaczącą cyfrą. Daje to zwykły porządek leksykograficzny wszystkich sekwencji z powtórzeniami.

Dla nazw kotletów `masterCount=17`.

`CutletNameCompatibilityRoute` korzysta z authoritative structure sauce po PATCH 20, pyta bowl `5` z seal `22` i przekazuje resulting answer-ring stream do historycznego generatora.

Stage 44 nie zawiera żadnego distinct-name detour.

Regression zawiera trzy kontrolowane raw witnesses dla `K=6`: rank `1` daje `[1,1,1,1,1,1]`, rank `2` daje `[1,1,1,1,1,2]`, a rank `18` daje `[1,1,1,1,2,1]`. Każdy zawiera powtórzenie i różni się od test-only distinct partial-permutation reference o tym samym rank.

Dodatkowo realny wiring witness używa bowls `[17,19,23,29,31,37]`, orderAt46 `[1,2,3,4,5,6]`, bowl `5` i seal `22`. Answer ring zaczyna się od `61401`; dla `K=6` legacy family `17^6=24137569` wybiera rank `61401` i zwraca:

`[1,1,13,9,8,14]`.

Indeks `1` powtarza się. Test-only normatywny partial-permutation unrank dla tego samego rank daje:

`[1,3,16,4,11,13]`.

Raw rank, family count i repeated indices są przechowywane w `MonsterContext` jako obserwowalna blizna Discovery 22.

Dopiero Stage 45 ma pozostawić `LegacyRepeatedNameGenerator` fizycznie bez zmian, wykonać go jako pierwszy i zachować `bad`, a następnie obliczyć distinct family przez falling factorial i partial-permutation unrank na tym samym bowl-5/seal-22 stream.

Ten sam mechanizm distinct-family będzie nadawał się również do miesięcy z katalogiem `47` i seal `33`, lecz Stage 44 nie wprowadza jeszcze month-name route.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

## Etap 45 — PATCH 22: distinct-name detour

Historyczny `LegacyRepeatedNameGenerator` pozostaje fizycznie bez zmian. Nadal definiuje rodzinę `masterCount^K`, dopuszcza powtórzenia i jest wykonywany jako pierwszy przy każdym name selection. Raw family count, raw rank i bad candidate pozostają obserwowalną blizną Discovery 22.

Dodano `partialPermutationNameRowCount`. Liczba poprawnych distinct rows to falling factorial:

`N * (N-1) * ... * (N-K+1)`.

Dodano `partialPermutationNameRowUnrank`. Funkcja wykonuje dokładny 1-based lexicographic unrank partial permutation przez listę pozostałych canonical indices oraz kombinatoryczny rozmiar każdego suffix block. Nie materializuje pełnej rodziny.

Dodano `RepeatedNamePatchWrapper`.

Wrapper otrzymuje już wykonany `badCandidate`, oblicza rank ponownie na tym samym answer-ring stream, lecz względem falling-factorial distinct family, i unrankuje `correct`.

Jeżeli `badCandidate==correct`, wrapper reuse historyczny candidate. Jeżeli są różne, publikuje `correct`.

`CutletNameCompatibilityRoute` nadal pyta bowl `5` z seal `22`, wykonuje raw repeated-name generator jako pierwszy, a następnie PATCH 22. Dla syntetycznego witness raw scar pozostaje `17^6=24137569`, rank `61401`, `[1,1,13,9,8,14]`; distinct family ma `17P6=8910720`, ten sam rank `61401`, a publikowany row to `[1,3,16,4,11,13]`.

Dodano `MonthNameCompatibilityRoute`. Używa tego samego mechanizmu z katalogiem `47`, bowl `5` i seal `33`. Dla tego samego syntetycznego sauce answer ring zaczyna się od `66681`. Raw repeated family `47^6=10779215329` daje `[1,1,1,31,9,35]`, natomiast distinct family `47P6=7731052560` publikuje `[1,2,3,40,44,30]`.

Regression Stage 45 porównuje produkcyjny partial-permutation unrank z małym brute-force oracle dla wszystkich `5P3=60` ranks, sprawdza obie gałęzie wrappera, zachowanie raw legacy scar oraz brak powtórzeń dla kotletów i miesięcy.

Sprawdzany jest również pełny count `47!`, który przekracza SAVE modulus i pozostaje reprezentowalny jako BigInt; rank 1 unrankuje się do `1:47`.

Niezmieniony regression Stage 44 ma po tej zmianie przejść z EXPECTED_RED do GREEN.

Stage 45 nie implementuje żadnej rodziny długości miesięcy, nie materializuje takich długości i nie zawiera kodu `VirtualLegacyList`. Dopiero Stage 46 wprowadzi historyczny defekt materialized month lengths.

Ponowna weryfikacja w natywnym MATLAB-ie pozostaje odłożona do końcowego, zbiorczego cyklu uruchomień.

