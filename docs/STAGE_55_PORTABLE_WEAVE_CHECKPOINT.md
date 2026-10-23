# Etap 55 — przenośny checkpoint dokładnego rank/unrank

**Gałąź:** \`MATLAB+Polski\` · **stan:** eksperymentalny.
Nie zastępuje standardowej drogi produkcyjnej ani nie zmienia
\`main\`. Każde wznowienie kontroluje dokładną liczbę legalnych
dokończeń. **Brak podpisu, HMAC i uwierzytelnienia pochodzenia**:
checkpoint pozostaje nieufnym wejściem; jego ważność matematyczna
jest sprawdzana przez ponowne liczenie.

## Umowa formatu \`pastafari-weave-cursor-v1\`

JSON jest kodowaniem przenośnym, a nie natywnym zrzutem obiektów
MATLAB. Obowiązkowe pola:

| Pole | Typ w JSON | Znaczenie |
|---|---|---|
| \`schema\` | tekst | dokładnie \`pastafari-weave-cursor-v1\` |
| \`originalLengths\` | liczby całkowite | wszystkie oryginalne długości miesięcy |
| \`remaining\` | liczby całkowite | pozostałe wystąpienia miesiąca |
| \`openedUpTo\` | liczba całkowita | indeks ostatniego otwartego miesiąca, 0..K |
| \`closedUpTo\` | liczba całkowita | indeks ostatniego zamkniętego, 0..opened |
| \`rankDecimal\` | **tekst** | dokładna dodatnia 1-indeksowana ranga wewnątrz sufiksu |
| \`countDecimal\` | **tekst** | dokładna liczba wszystkich legalnych dokończeń sufiksu |
| \`done\` | boolean | czy pozostało zero kopii i wszystkie miesiące zamknięto |
| \`stepsComputed\` | liczba całkowita | długość fragmentu z ostatniego wywołania |

Duże wartości \`rankDecimal\` i \`countDecimal\` są obowiązkowo
**ciągami dziesiętnymi, nigdy liczbami JSON**. Nie wolno
konwertować ich do \`double\` ani skracać do IEEE-754.
Format wymaga kanonicznych niezerowych dodatnich liczb
\`[1-9][0-9]*\`, bez znaku \`+\` i bez zer wiodących.

## Przykład użycia

\`\`\`matlab
[fragment, cursor] = pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    L, L, 0, 0, rankBigInt, 2);
portable = pastafari.serializeExactWeaveCursorJson(L,cursor);
% portable może zostać zapisany do pliku UTF-8, jako tekst.
% W następnej sesji:
[restoredLengths, restoredCursor] = ...
    pastafari.restoreExactWeaveCursorJson(portable);
[nextFragment, nextCursor] = ...
    pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
        restoredLengths, restoredCursor.remaining, ...
        restoredCursor.openedUpTo, restoredCursor.closedUpTo, ...
        restoredCursor.rank, 3);
\`\`\`

Eksporter sprawdza typy, kształt, indeksy prefiksu
i zgodność \`done\` z pozostałymi kopiami. Jego wynik nie
powinien być uważany za uwierzytelniony certyfikat.

Importer **zawsze** ponawia dokładną kontrolę. Sprawdza
całą strukturę JSON, kanoniczne zapisy BigInt i legalność
frontieru, a potem uruchamia
\`unrankGeneralWeaveSuffixChunkLazyJoint(..., maxSteps=0)\`.
Ta droga niezależnie wyznacza liczbę wszystkich dokończeń
i odrzuca podmieniony \`countDecimal\`, nielegalny rank,
niezgodne indeksy, niedozwolony status \`done\` oraz
uszkodzony format. Dopiero po tej walidacji można
bezpiecznie kontynuować.

Konsekwencja wydajnościowa: ponowne ustalenie BigInt
dla pełnych 45 miesięcy i 4244 dni może zająć
kilka minut; importer **nie omija** tej czynności.
Pozwala jednak wznowić dokładny tekstowy punkt
obliczenia po przerwaniu pracy bez zaokrąglenia
liczb i bez zastąpienia brakujących dni szacunkami.

## Kryteria natywnego QA

- Okrążenia serialize → restore → dalsze fragmenty →
  wynik identyczny z \`WholeMonthWeavingFamily.itemAt1\`
  dla małych rodzin, dla krańców i środka;
- porównanie wszystkich BigInt przed i po, a nie tylko
  fragmentów cyfr;
- odrzucenie \`countDecimal\` o innej wartości,
  zapisu z zerem wiodącym, nieznanego schematu,
  niepoprawnej flagi końca i zmienionych liczności;
- zachowanie liczb dłuższych niż zakres bezpieczny
  dla typu \`double\` jako tekstu (bez ich akceptowania,
  jeśli przekraczają dokładną legalną rangę).

Natywny workflow:
[MATLAB Portable Exact Weave Checkpoint JSON (Experiment)](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/workflows/matlab-stage55-checkpoint-json.yml).
Przed odczytem końcowych markerów QA
\`STAGE_55_CHECKPOINT_JSON_*\` nie należy oznaczać za PASS.

## Niezałatwione problemy

Bezpieczna struktura wznowienia **nie jest** równoznaczna
z wydajnym arbitralnym unrankiem wszystkich 4244 dni.
W dalszym ciągu potrzebujemy amortyzacji kosztownego
joint-DP pomiędzy rozgałęzieniami oraz kompletnego
porównania wyniku kalendarza z niezależnym
\`normative_oracle\`. Stan formalny:
\`LAST_COMPLETED_STAGE=54\`, \`STAGE_55_COMPLETE=NO\`.
