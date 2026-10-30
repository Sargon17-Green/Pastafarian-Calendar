# Fase 2 — DISCOVERY02 — zelfstandige SAVE- en stenentabel

Status: implementatie en tests gecommit; Native en verify voor deze commit zijn vereist.

## Gecontroleerde basis

- Stage 1-regressie en Stage 2 DISCOVERY01 Native: 13 tests, 114 assertions, nul failures/errors.
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040644318
- Bovenstaande uitslag geldt alleen voor commit 4b78709f881cd23a4d74654b5e958777f7c046c7.

## Contract van deze ontdekking

1. `SAVE(x) = 1 + ((x - 1) mod M)` met `M = 2^127 - 1` en een niet-negatief residu, ook voor negatieve invoer.
2. Bouw exact 46 stenen; steen 1 is `[17, 29, 43, 71, 101]`; elke volgende steen heeft vijf componenten.
3. Voor steen `i` met voorganger `[w,b,s,t,r]`:
   `[SAVE(w*w + 3*b + i), SAVE(b*b + 5*s + w), SAVE(s*s + 7*t + b), SAVE(t*t + 11*r + s), SAVE(r*r + 13*w + t)]`.
4. Posities zijn 1-gebaseerd; de gehele tabel wordt in productieruimte eenmaal geconstrueerd.
5. Het testorakel mag uitsluitend door tests worden gebruikt. Geen saus, poort, jaar, maand of volledige kalenderdatum is hier geclaimd.

## Verificatie

- Vaste grens- en ankerfixtures, inclusief negatieve SAVE-input en de laatste steen.
- 46 x 5 = 230 afzonderlijke differential assertions voor alle velden tegenover het testorakel.
- Stage 1, DISCOVERY01 en DISCOVERY02 via `clojure -M:test`; Canonical Names Lock via `verify`.
- Aantallen tests, assertions en errors uitsluitend als Native-logresultaat publiceren.
- Geen Stage 2 PASS zolang de volgende productielagen (verborgen/zichtbare druppels en saus) ontbreken.

## Volgende stap binnen Stage 2

Als Native en verify slagen: contracteer de verborgen druppels, daarna de zichtbare druppels, met begrensde fixtures en onafhankelijke differential-tests; integreer de saus pas nadat de voorafgaande lagen zijn geverifieerd. Bij falen: herstel de gerapporteerde oorzaak op deze tak. Geen merge naar main.
