# Fase 2 — DISCOVERY03 — zeven verborgen druppels

Status: code en tests voorbereid; Native en verify op de nieuwe commit zijn vereist.

## Gecontroleerde voorafgaande poort

- DISCOVERY02: GitHub Actions run 41086967871 op commit e15999c3dd61b4798c02ae8c2ce774a8c1930786.
- Native: 17 tests, 364 assertions, 0 failures, 0 errors; verify: success.
- Dit bewijs betreft uitsluitend het bovengenoemde commit.

## Exacte contractgrens

- Er worden exact zeven verborgen druppels teruggegeven, elk een SAVE-residu in [1, M] waarbij M = 2^127 - 1.
- Uit gevalideerde werk-tellingen (actie, doel, afstand, verbinding, richting) wordt voor k=1..7 een seed opgebouwd:
  action + a[k]*target + b[k]*distance + c[k]*connection + d[k]*direction + som(steen[k]).
- De coefficientenrijen zijn [3,4,6,8], [5,7,10,12], [7,10,14,16], [9,13,18,20], [11,16,22,24], [13,19,26,28], [15,22,30,32].
- Begin met SAVE(seed), daarna zeven maalbewerkingen: SAVE(x*x + 3*x + steen[k][soort] + beurt), waarbij de nul-gebaseerde soortvolgorde [0,1,2,3,4,0,1] is.
- Productie heeft geen dependency op het normatieve testorakel; alle rekenstappen zijn exact integer.

## Bewijsprotocol

- Twee onafhankelijk berekende vaste vectoren.
- 49 begrensde paren rond stichtingsdag x zeven druppels = 343 differential assertions tegen het aparte testorakel.
- Extra tests voor bereik, chronologische richting, ongeldige input en grote gehele getallen.
- Stage1/2-regressies en Canonical Names Lock moeten gelijktijdig slagen.
- Geen Native PASS vóór de volledige uitvoer van de nieuwe commit. Geen Stage2 PASS.

## Volgende stap

Na Native+verify success: contracteer zichtbare druppels (1..46) bovenop de zeven verborgen,
met expliciet vastgelegde indexen voor tijdlijn (-6..0), prev1, prev3, prev7, 11 maalstappen,
vaste grensfixtures en 46 onafhankelijke differential-controles. Pas daarna sausbewerking.
Geen Stage3 of merge/main.
