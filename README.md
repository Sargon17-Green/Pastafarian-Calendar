# Kalendarz pastafariański — linia MATLAB + polski

To jest niezależna implementacja Kalendarza Pastafariańskiego w MATLAB-ie, z tekstem przeznaczonym dla człowieka po polsku.

## Bieżący stan

Linia doszła do **Etapu 55 z 55 — końcowego audytu**.

Etap 54 połączył wszystkie 26 historycznych par `DISCOVERY/PATCH` w jedną produkcyjną trasę `pastafari.finalMonsterIntegration`. Publiczna funkcja `calendarDateSpaghetti` nie jest już szkieletem kończącym się `NotImplementedYet`; zwraca pięć pól daty:

1. numer roku,
2. nazwę kotleta,
3. dzień kotleta,
4. nazwę miesiąca,
5. dzień miesiąca.

Etap 55 nie zmienia logiki produkcyjnej. Jego zadaniem jest wykonanie pełnej natywnej weryfikacji w MATLAB-ie i zamknięcie linii dopiero po rzeczywistym PASS.

Dlatego przed końcową natywną weryfikacją:

- `CURRENT_STAGE=55`,
- `LAST_COMPLETED_STAGE=54`,
- Stage 55 pozostaje kandydatem do zamknięcia,
- nie wolno deklarować `LAST_COMPLETED_STAGE=55` bez logu kończącego się markerem `STAGE_55_FINAL_AUDIT_PASS`.

## Końcowa weryfikacja

Z katalogu repozytorium należy uruchomić w MATLAB-ie:

```matlab
addpath('tests');
run_stage55_final_audit
```

Audyt ustawia automatycznie `PASTAFARI_STAGE54_HEAVY=1`, uruchamia pełną regresję wcześniejszych etapów, ciężki differential produkcji względem niezależnego testowego `normative_oracle`, a następnie kontroluje kompletność etapów, obecność PATCH 01–26, izolację oracle od produkcji oraz aktualność metadanych.

Wynik jest zapisywany do:

```text
logs/STAGE_55_MATLAB_RUN.log
```

Końcowy sukces wymaga trzech markerów:

```text
STAGE_55_REPOSITORY_AUDIT_PASS
STAGE_55_NATIVE_VERIFICATION_PASS
STAGE_55_FINAL_AUDIT_PASS
```

## Architektura historyczna

26 historycznych wad pozostaje fizycznie obecnych jako warstwy legacy. Produkcyjne `CompatibilityRoute` najpierw wykonują i zachowują odpowiedni historyczny scar, a następnie publikują wynik po właściwym PATCH.

Stage 54 nie zastąpił tych warstw czystą implementacją oracle. Zintegrowana trasa korzysta między innymi z:

- PATCH 16 i 17 przy wyborze roku 5000,
- PATCH 18 i 26 przy wyznaczaniu roku dnia pytanego,
- PATCH 19 dla chronionego cache struktury roku,
- PATCH 20 dla sauce pierwszego dnia roku,
- PATCH 21 dla filtrowanej rodziny podziałów kotletów,
- PATCH 22 dla nazw bez powtórzeń,
- PATCH 23 dla wirtualnej rodziny długości miesięcy,
- PATCH 24 dla pełnego splotu miesięcy,
- PATCH 25 dla occurrence-based dnia miesiąca.

Testowy `normative_oracle` pozostaje wyłącznie pod `tests/oracle` i nie jest zależnością kodu produkcyjnego.

## Dokładne liczby całkowite

`pastafari.BigInt` zapewnia dokładną arytmetykę całkowitą wymaganą przez algorytm bez zewnętrznego środowiska uruchomieniowego. Weryfikacja Stage 1 obejmowała między innymi wartości przekraczające `flintmax`, skrajne wartości `int64`/`uint64` oraz duże operacje arytmetyczne.

Historyczna natywna weryfikacja Stage 1 została wykonana w MATLAB-ie:

```text
26.1.0.3346908 (R2026a) Update 5
```

Końcowy Stage 55 musi ponownie potwierdzić całą obecną linię po wszystkich późniejszych etapach.

## Katalog języka źródłowego

`pastafari.sourceLanguageCatalog` zawiera zamrożony katalog 17 nazw kotletów i 47 nazw miesięcy. Semantyka wewnętrzna korzysta z `canonicalIndex`; polski tekst jest rozwiązywany dopiero przy budowaniu wyniku końcowego.
