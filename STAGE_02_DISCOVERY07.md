# Fase 2 — DISCOVERY07 — monotone poortposities en begrensde voorganger

Status: zelfstandig, nieuw contract op de geaccepteerde DISCOVERY06-afstanden. Geen claim over volledig kalenderjaar, data of vijf datumcomponenten.

## Basis en definities
- Tak: Clojure+Nederlands. Voorafgaand HEAD: 00a26fbd00d4e4ddc3f18e30621863277cbaa93c.
- Basis-acceptatie: DISCOVERY06 run 41136748133; completed SUCCESS voor native+verify; 36 tests, 4215 assertions, 0 failures, 0 errors.
- C = stichtingsdag = -15055671. P(0) = C.
- Voor n>=1: P(n)=P(n-1)+positieve-poortafstand(n).
- Voor n>=1: P(-n)=P(-(n-1))-negatieve-poortafstand(n).
- De twee afstandsfuncties komen uitsluitend uit de productie van DISCOVERY06. Geen oracle-import in productie.
- Omdat alle afstanden in [42,963] liggen, zijn de poortdagen strikt stijgend met de index, ook over P(-1),P(0),P(1).

## Nieuwe API en harde grenzen
- bouw-poortlijn(straal): straal is exact geheel in [0,64]. Resultaat {:straal straal, :dagen vector} met indices -straal t/m +straal op oplopende dagvolgorde.
- poortdag(lijn,index): exacte poortdag als -straal<=index<=straal.
- poort-op-of-voor(lijn,dag): exact gehele dag binnen [P(-straal),P(straal)] geeft {:index k, :day P(k)} voor unieke grootste k met P(k)<=dag. Implementatie met upper-bound binaire zoekactie; O(log(2*straal+1)) na aanleg.
- Buiten het berekende venster is een voorganger niet bewezen; functie werpt :day-outside-gate-window, geen extrapolatie. Onjuiste straal :invalid-gate-radius, index buiten venster :gate-index-outside-window, dag niet geheel :invalid-day, onjuist lijnobject :invalid-gate-line.
- Aanleg berekent 2*straal afstanden met BigInt, zonder afronding. Bovengrens 64 is een expliciete veiligheidsgrens tegen onbegrensde lineaire CPU-kosten en géén wiskundige bovengrens aan de kalender.

## Twee zelfstandige controlepaden
- Productie: twee oplopende vectoren die apart worden uitgebreid met poortafstanden, daarna samengevoegd tot de gesorteerde lijn; binary-search upper-bound voor opvolging.
- Testoracle: voor ieder index afzonderlijk de normatieve positive-gate-gap / negative-gate-gap van 1 tot |index| opnieuw optellen/aftrekken, zonder de productievectors of zoekcode.
- 17 indexwaarden (-8..8) vergeleken met oracle, exacte origin, 16 monotoniciteit/gapcontroles, alle 17 equality-lookup-witnesses, 16 witnesses net voor de volgende poort en 16 net na de vorige, nulvenster, grensinput, BigInt 10^101 en foutcodes.
- Native regressie van DISCOVERY01–06 blijft in test runner; completed+success van native en verify en de echte log vormen pas de acceptatiepoort voor DISCOVERY07.

## NEXT
Na completed Native+verify: DISCOVERY08 onderzoeken voor expliciete vensteruitbreiding en opeenvolgende jaargrenzen via reeds geverifieerde poortposities, met zelfstandig contract vóór implementatie. Niet stiekem onbeperkt scannen, geen merge naar main.