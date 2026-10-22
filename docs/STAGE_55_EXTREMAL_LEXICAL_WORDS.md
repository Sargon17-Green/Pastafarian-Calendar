# Etap 55 — skrajne słowa leksykograficzne bez DAG

**Gałąź:** `MATLAB+Polski`.
**Status:** odrębne doświadczenie do testowania całego słowa; bez zmian produkcji oraz `main`. Nie jest to rozwiązanie dowolnego rank.

## Twierdzenie o dokończeniu każdego legalnego prefiksu

Niech miesiące mają dodatnie dokładne wielokrotności `L(1)..L(K)`. Stan prefiksu przechowuje liczby pozostałych kopii `R`, ostatni otwarty miesiąc `o` oraz ostatni zamknięty miesiąc `c`. Dozwolona kolejna litera `j` spełnia jednocześnie:

1. `R(j)>0`;
2. jeśli `R(j)=L(j)` (pierwsze wystąpienie), to `j=o+1`;
3. jeśli `R(j)=1` (ostatnie wystąpienie), to `j=c+1`.

Takich ruchów nie można utożsamiać z dowolnym wyborem litery: ograniczenia kontrolują obie kolejności i wykluczają przedwczesne zamknięcie.

Każdy stan osiągnięty przez poprawny prefiks ma co najmniej jedno pełne legalne dokończenie. Konstruktywny dowód: dla miesięcy od `c+1` do `K` kolejno dopisujemy **wszystkie** pozostałe kopie najmniejszego jeszcze niezamkniętego miesiąca. Każdy jeszcze nieotwarty miesiąc zostaje wtedy otwarty dopiero po poprzednim; każdy miesiąc zamyka się dopiero po poprzednim. Nie zmieniamy ani nie pomijamy żadnej kopii. Zatem także po dowolnym lokalnie legalnym ruchu istnieje co najmniej jedno dokończenie.

## Konsekwencja leksykograficzna

Wśród dostępnych legalnych następnych liter wybór najmniejszej daje najwcześniejszy prefiks, którego pewne pełne legalne słowo istnieje. Analogicznie wybór największej daje najpóźniejszy taki prefiks. Zasada indukcji po liczbie pozostałych pozycji dowodzi, że powtarzanie tych wyborów aż do końca daje odpowiednio dokładnie **pierwsze** i **ostatnie** legalne słowo.

Procedura nie wykonuje egzemplifikacji wykładniczego DAG ani kosztownego BigInt-count na każdy dzień. Sprawdza najwyżej `K` kandydatów dziennie i zapisuje wszystkie `N=sum(L)` liter. Koszt wyboru to `O(K*N)`, a pamięć bieżącego stanu `O(K)` i gotowego słowa `O(N)`.

Tak obliczone dwa słowa są skrajnościami dla dokładnej 1-indeksowanej rodziny uporządkowanej leksykograficznie; odpowiadają rangom `1` oraz `count(L)`. Metoda nie oblicza ani nie zgaduje rank dla słowa wewnętrznego.

## Weryfikacja

- Funkcja: `src/+pastafari/extremalWholeMonthWeavings.m`.
- Niezależny test: `tests/run_stage55_extremal_weave_tests.m`.
- Test powinien porównać 363 małe rodziny długości z osobną rekurencyjną konstrukcją ekstremów i 10 rodzin z `WholeMonthWeavingFamily.itemAt1` dla dokładnych rang `1` i `count`.
- Pełnowymiarowa próba wykorzystuje **prawdziwy wektor** 45 miesięcy i 4244 dni roku 5000 z logu `39818603362`. Sprawdza wszystkie liczności, wszystkie pierwsze i ostatnie wystąpienia, długość słów oraz kompletną leksykograficzną skrajność.
- Uruchomienie MATLAB R2026a: [39841626098](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39841626098), commit `064e8b726018fb70b487438b6685222fd3e3d952`. **Nie poświadczać PASS do odczytu faktycznych końcowych logów.**
- Pełna liczba legalnych przeplotów rzeczywistego wektora została już porównana jako całkowity BigInt dwoma niezależnymi licznikami w [39838926612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39838926612) — **PASS, 6765 cyfr**. To dowód liczności, nie wybierania wszystkich rang.

Ograniczenie końcowe pozostaje bez zmian: brak jeszcze wydajnego ogólnego rank/unrank dla 4244 liter oraz pełnego porównania normatywnych krotek daty. `STAGE_55_COMPLETE=NO`, `LAST_COMPLETED_STAGE=54`; nie scalać do `main`.
