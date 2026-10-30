# Fase 2 — DISCOVERY05 — zes sauskommen

Status: zelfstandige productiecode en begrensde tests gecommit; nieuwe Native en verify nog vereist.

## Bewezen eerdere poort
DISCOVERY04: commit bc08d66b22c98e03f6a75b1e91f99a9739f29996.
GitHub Actions run 41097808622: 26 tests / 2994 assertions / 0 failures/errors; verify SUCCESS.

## Exact contract
- Invoer: positieve exacte werk-tellingen en 46 SAVE-residuen van zichtbare druppels; M=2^127-1.
- Zes beginwaarden voor id=1..6 met primes [17,19,23,29,31,37]:
  SAVE((action+target*id+distance+connection+direction+prime^2)^2+id).
- Lexicografische permutatie op [1..6]: rang 1+((drop-1) mod 720).
- Voor iedere druppel i=1..46 blijven de zes oude kommen onveranderd gedurende alle zes posities.
- Schenkingen in de eerste drie posities p=1..3:
  SAVE(drop^2+stone[i][p-1]*old[order[p]]+(2*p+1)*i); de andere drie zijn nul.
- Elke positie p heeft cyclische buren prev en next en steensoort [0,1,2,3,4,0].
  s=old[id]+2*old[prev]+3*old[next]+pour[p]+drop+stone[i][type].
  new[id]=SAVE(s^2+5*old[prev]*old[next]+i*p).
- Leg de volgorde van druppel 46 vast. Voer daarna 12 simultane nabewerkingen uit:
  sum=SAVE(sum(old)+149*j), order=unrank1(1+((sum-1) mod 720)).
  s=old[id]+3*old[prev]+5*old[next]+sum+j+p^2.
  new[id]=SAVE(s^2+7*old[prev]*old[next]).
- De testoracle-namespace wordt nooit door productie geladen.

## QA
Twee onafhankelijk berekende exacte numerieke ankers, 49*7=343 differential
assertions voor alle eindkommen en de laatste druppelvolgorde, plus
richting, ongeldige input, precieze 100-cijferige dagen en bestaande regressies.
Geen aanname van datumvolledigheid of PASS zonder completed CI+Native-log.

## NEXT
Lees completed Native+verify op het nieuwe SHA; corrigeer echte fouten,
of ga pas daarna verder binnen Stage 2 volgens geverifieerd contract.
Geen Stage 3, geen main/merge.
