# Etap 55 — dokładne bloki pierwszej litery we wspólnym przebiegu DP

**Gałąź:** \`MATLAB+Polski\`.
**Stan:** osobny algorytm eksperymentalny oraz opcjonalna ścieżka
\`joint\` dla \`unrankGeneralWeaveSuffixChunk\`; bez zmian produkcji,
\`main\` i niezależnego \`normative_oracle\`.

## 1. Dlaczego jeden przebieg wystarcza

Dla dokładnych pozostałych wielokrotności miesięcy \`r_i>0\`,
z otwartym prefiksem \`o\` i zamkniętym prefiksem \`c\`, w słowach
legalnych pierwsze wystąpienia muszą zachować porządek miesięcy,
które jeszcze się nie otwarły; ostatnie wystąpienia wszystkich
pozostałych miesięcy muszą zachować porządek zamknięć.

Niech \`G_i(j,p)\` będzie liczbą słów na miesiącach \`c+1..i\`,
których **pierwszym symbolem** jest miesiąc \`j\`, a pierwsze
wystąpienie największego miesiąca \`i\` jest w pozycji \`p\`.
Ostatni symbol musi być \`i\` (inaczej największy miesiąc nie
zamknąłby się ostatni). Wymiar jego ostatniej pozycji jest więc
zawsze równy \`N_i\` i nie wymaga osobnej tablicy.

Przy dodaniu \`m_i>=2\` kopii nowego największego miesiąca,
dla jego pierwszego wystąpienia w pozycji \`p\` pozostaje
\`m_i-2\` kopii do umieszczenia we wnętrzu:

\`\`\`text
W_i(p) = C(N_i-p-1, m_i-2)
\`\`\`

Jeśli \`p=1\`, nową pierwszą literą jest \`i\`, co jest legalne
jedynie wtedy, gdy \`i<=o+1\`. Liczba tych słów wynosi
\`W_i(1)*sum_j sum_f G_(i-1)(j,f)\`.

Jeśli \`p>1\`, pierwsza litera \`j\` pozostaje bez zmiany.
Gdy \`i>o+1\`, nowe pierwsze wystąpienie największego miesiąca
musi nastąpić po pierwszym wystąpieniu poprzedniego największego
miesiąca. Dlatego:

\`\`\`text
G_i(j,p) = W_i(p) * sum_{f<p} G_(i-1)(j,f)
\`\`\`

Gdy \`i<=o+1\`, ograniczenie nie obowiązuje:

\`\`\`text
G_i(j,p) = W_i(p) * sum_f G_(i-1)(j,f).
\`\`\`

W przypadku \`m_i=1\`, jedyne wystąpienie nowego największego
miesiąca zajmuje ostatnią pozycję \`N_i\`, zatem zachowuje
pierwszy symbol poprzedniego słowa.

Wynik końcowy \`B_j=sum_p G_K(j,p)\` jest **dokładną liczbą
wszystkich legalnych dokończeń zaczynających się od j**.
Zbiory takich słów są rozłączne i wyczerpują wszystkie
dokończenia, więc \`sum_j B_j\` musi się zgadzać z liczbą rodzica.

Metoda trzyma jedynie wektory prefiksowe dla dozwolonych
pierwszych liter (co najwyżej liczba aktywnych/otwieranych
miesięcy), a nie osobne pełne DP dla każdej możliwej kolejnej
litery. Stosuje \`pastafari.BigInt\` i dokładne \`floorDivMod\`
dla współczynników dwumianowych; niczego nie zaokrągla.

## 2. Niezależne sprawdzenia

- Niezależny prototyp w JS porównano z rekurencyjnym enumeratorem
  na 6288 nieterminalnych osiągalnych stanach, PASS. To był test
  projektowy, nie dowód natywnego MATLAB.
- MATLAB R2026a, commit \`1720dfa49583e590251bb375d1495f5a782dd202\`,
  [run 39817561064](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39817561064):
  **PASS** dla 363 rodzin, 6651 wszystkich stanów (włącznie z
  końcowymi), 10221 legalnych przejść. Wszystkie bloki następnej
  litery porównano z niezależną rekurencją legalnych przejść,
  sumę bloków z osobnym licznikiem jednokońcowym.
- Natywny pomiar pełnego, ale małego frontu:
  80 dni/8 miesięcy \`0.070 s\`, 240 dni/12 miesięcy
  \`0.277 s\`. Są to pomiary tych konkretnych runnerów.
- W commit \`e08ef2779ba281acee82add38797d7eb8595edb8\` dodano
  opcjonalny tryb \`joint\` do \`unrankGeneralWeaveSuffixChunk\`,
  bez zmiany domyślnej ścieżki \`reference\`.
  Oprócz niezależnych bloków sprawdzana jest pełna równość
  \`jointTotal==parentCount\`, zanim zostanie wybrany rank.
  Na etap przygotowania dokumentu test end-to-end
  [run 39818052124](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39818052124)
  nie był jeszcze zatwierdzony; należy odczytać rzeczywisty
  końcowy wynik przed uznaniem go za PASS.

## 3. Granice praktycznego zastosowania

Jednorazowe wyliczenie wszystkich bloków oszczędza powtarzanie
licznika dla każdej legalnej litery, lecz nie udowadnia jeszcze
wydajnego wyznaczenia wszystkich 4244 liter: po każdej wybranej
literze rozkład pozostałych wielokrotności zmienia się.
Wymagana jest dalsza metoda zachowania/aktualizacji wystarczających
statystyk DP pomiędzy pozycjami lub zweryfikowana strategia
odtwarzalnych fragmentów o rozsądnym koszcie.

Również poprawny wynik dla syntetycznego wektora 45 miesięcy
nie zastępuje rzeczywistej dystrybucji długości roku 5000,
produkcji \`finalMonsterIntegration\` i całkowitego porównania
pięciu składowych daty z niezależnym \`normative_oracle\`.

\`LAST_COMPLETED_STAGE=54\` i \`STAGE_55_COMPLETE=NO\` pozostają
niezmienione. Nigdy nie scalać do \`main\`.
