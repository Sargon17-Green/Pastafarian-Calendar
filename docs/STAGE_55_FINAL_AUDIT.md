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
