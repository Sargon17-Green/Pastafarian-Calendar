# Etap 55 — rzeczywisty wektor 45 miesięcy roku 5000

**Gałąź:** \`MATLAB+Polski\`.
**Status:** diagnostyczny zbiór odniesienia i oddzielny test dokładny;
produkcja, \`main\` i \`normative_oracle\` bez zmian.

## Pochodzenie danych

W logu prawdziwego natywnego audytu
[GitHub Actions 39818603362](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39818603362)
dla commit \`6435dfc097626b6c68159c942abb2424674e35dd\`,
po zakończeniu \`MonthLengthCompatibilityRoute.call\` i przed
\`MonthWeavingCompatibilityRoute.call\`, pojawił się znacznik:

\`\`\`text
STAGE_54_STRUCTURE_MONTH_LENGTHS_VECTOR COUNT=45 VALUES=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 97 50 122 110 81 54 101 83 88 40 25 77 98 122 105]
\`\`\`

Wektor zawiera **45 miesięcy, 4244 dni**, w zakresie 25..122.
Pochodzi z faktycznej ścieżki produkcyjnej, nie z wcześniejszego
syntetycznego \`[108, 94,...,94]\`. Te dwa przypadki nie są równoważne.

Sam Stage55 po tym punkcie nie doszedł do oracle: pozostawiony
bez zmian historyczny wykładniczy DAG utworzył 32768 stanów już
w dniu 16, następnie runner otrzymał sygnał wyłączenia.
Nie wystąpił \`STAGE_54_HEAVY_DIFFERENTIAL_PASS\`.

## Oddzielny eksperyment

Test \`tests/run_stage55_real_year_5000_lengths_tests.m\`
przyjmuje **dokładnie odczytany wektor** jako stały fixture,
sprawdza jego sumę i wartości, i wyznacza liczbę wszystkich
legalnych przeplotów dwoma różnymi algorytmami:
\`countWholeWeavingSuffixByFirstEndpoint\` oraz
\`countWholeWeavingAllUnopenedWavefront\`.

Otrzymane obiekty \`pastafari.BigInt\` są porównywane w pełni
operatorem \`==\`. Wypisywanie 48 cyfr początkowych/końcowych
jest tylko czytelnym znacznikiem diagnostycznym, nie zastępuje
równości pełnej liczby. Dodatkowo pierwszy symbol każdego
legalnego słowa musi być miesiącem 1, a jego odjęcie jest
wymuszoną bijekcją zachowującą pełną liczność i dokładny rank.

Oddzielny workflow:
\`MATLAB Real Year-5000 Month Weave Exact Count (Experiment)\`.
Bez potwierdzenia końcowych znaczników MATLAB R2026a nie
wolno ogłosić tego eksperymentu jako PASS.

**Nie osiągnięto jeszcze** praktycznego rank/unrank
dla wszystkich 4244 dni z pełnego oryginalnego
wektora ani porównania pięcioelementowej daty
z \`normative_oracle\`. \`STAGE_55_COMPLETE=NO\`;
nie łączyć do \`main\`.
