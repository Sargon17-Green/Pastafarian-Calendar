# Etap 55 — końcowy audyt i natywna weryfikacja

## Cel

Etap 55 jest ostatnim etapem linii MATLAB + polski. Nie dodaje nowej semantyki kalendarza i nie powinien modyfikować kodu produkcyjnego, chyba że rzeczywista weryfikacja ujawni konkretny błąd.

Punktem wejścia jest stan po Etapie 54, w którym `calendarDateSpaghetti` jest już podłączony do `pastafari.finalMonsterIntegration`.

## Warunek zamknięcia

Samo statyczne przygotowanie plików nie zamyka Etapu 55.

Do zamknięcia wymagany jest rzeczywisty natywny przebieg MATLAB-a:

```matlab
addpath('tests');
run_stage55_final_audit
```

Audyt musi zakończyć się markerem:

```text
STAGE_55_FINAL_AUDIT_PASS
```

oraz utworzyć:

```text
logs/STAGE_55_MATLAB_RUN.log
```

Dopiero po sprawdzeniu tego logu można wykonać małą deltę zamykającą, która ustawi `LAST_COMPLETED_STAGE=55`, `STAGE_55_COMPLETE=YES_NATIVE_PASS` i `MATLAB_RERUN_REQUIRED=NO`.

## Zakres

Końcowy audyt:

- wymusza ciężki Stage 54 differential względem niezależnego oracle,
- uruchamia łańcuch wcześniejszych regresji,
- sprawdza kompletność plików etapów 1–55,
- sprawdza reprezentatywne artefakty PATCH 01–26,
- skanuje całą produkcję pod kątem niedozwolonej zależności od `normative_oracle`,
- sprawdza, że metadane nie deklarują przedwcześnie ukończenia Etapu 55,
- sprawdza, że README opisuje rzeczywisty stan po integracji.

## Stan przed uruchomieniem

Przed natywnym PASS prawidłowe metadane to:

```text
CURRENT_STAGE=55
CURRENT_KIND=FINAL_AUDIT_CANDIDATE
LAST_COMPLETED_STAGE=54
STAGE_55_COMPLETE=NO_AWAITING_NATIVE_FINAL_AUDIT
MATLAB_RERUN_REQUIRED=YES
```

Jest to stan celowy. Nie należy zmieniać go na ukończony na podstawie samego audytu statycznego.

## Zgodność regresji historycznych z wejściem końcowym

Przed końcową weryfikacją poprawiono **28 przestarzałych asercji** w 27 plikach testów: Etap 1 (dwa przypadki) oraz parzyste Etapy 2–52 (po jednym przypadku). Dawniej wymagały błędu `Pastafari:Bootstrap:NotImplementedYet`, mimo że po Etapie 54 publiczne `calendarDateSpaghetti` ma zwracać datę, a nie zatrzymywać się na szkielecie.

Każdy z tych przypadków wywołuje teraz testowy `assert_public_calendar_entry_contract`. Sprawdza on walidację dokładnych wejść, zachowanie liczb w kontekście i faktyczne odrzucenie `NaN` przez publiczną funkcję. Ponadto kontroluje podłączenie produkcyjnego `finalMonsterIntegration` i brak starego wyjątku. Nie symuluje wyniku kalendarza i nie przechwytuje jego prawdziwego ciężkiego testu.

`run_stage55_final_audit` wykonuje wstępny przegląd tych 28 miejsc i emituje `STAGE_55_PUBLIC_ENTRY_REGRESSION_AUDIT_PASS`. To tylko bramka statyczna. **Rzeczywisty wynik całego kalendarza** nadal musi zostać obliczony natywnie i porównany z niezależnym oracle w ciężkim `run_stage54_tests`.

Nie wykonano nowej natywnej próby MATLAB tylko przez przygotowanie tej poprawki. Metadane Etapu 55 pozostają w stanie `NO_AWAITING_NATIVE_FINAL_AUDIT` aż do rzeczywistego PASS.

## Automatyczna natywna próba na GitHub Actions

Workflow `.github/workflows/matlab-stage55-native.yml` uruchamia natywne MATLAB R2026a na hostowanym przez GitHub systemie Ubuntu dla gałęzi `MATLAB+Polski`. Repozytorium jest publiczne: akcje MathWorks `setup-matlab@v3` i `run-command@v3` obsługują w tym trybie automatyczne licencjonowanie MATLAB-a, bez dodawania prywatnych kluczy do repozytorium.

Zmiana testów, kodu lub pliku workflow uruchamia pełny audyt Stage 55. Zadanie ma ograniczenie 180 minut. Krok `upload-artifact@v4` zachowuje `logs/STAGE_55_MATLAB_RUN.log` również po niepowodzeniu testu, jeśli plik powstał. Weryfikacja wykonuje oryginalne `run_stage55_final_audit` i **nie używa zastępczego oracle**.

Sukces workflow nie aktualizuje automatycznie `LAST_COMPLETED_STAGE`. Zamknięcie wymaga sprawdzenia, że log dotyczy właściwego commit SHA, zawiera wszystkie wymagane markery PASS, a różnice semantyczne i regresje zostały faktycznie zweryfikowane. Przed uzyskaniem takiego wyniku Stage 55 pozostaje otwarty.

## Code Analyzer preflight (MATLAB native)

Before Stage 54 heavy tests, Stage 55 runs `run_stage55_code_analysis` over all `src/` and `tests/` MATLAB files (including `tests/oracle/`). It uses MathWorks `codeIssues` with factory settings, requires at least 150 analyzed files, and fails on any `Severity=error` diagnostic. All reported diagnostics are included in the Stage 55 failure report and the artifact log, up to the first 100 errors. This is a syntax/static-analysis gate, not a substitute for native semantic and differential verification.
