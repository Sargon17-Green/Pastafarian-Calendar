# Fase 2 — DISCOVERY06 — keuzestromen en poortafstanden

Status: nieuw zelfstandig contract, geen bewering dat er een historisch DISCOVERY06-document was. Native en verify worden uitsluitend uit de afgeronde CI-log afgeleid. Stage 2 blijft open.

## Voorwaarde en bewijs
- Tak: Clojure+Nederlands; voorafgaand HEAD 00e098707da9997ba2e438ec2e3b4346450c56f5.
- DISCOVERY05 plus aanvullende modulo-tests: GitHub Actions run 41117926755, beide jobs completed SUCCESS; 31 tests, 3358 assertions, 0 failures/errors.
- Geen wijziging van de vijf uiteindelijke datumcomponenten, geen gebruik van een testoracle in productie.

## Nieuw wiskundig contract (op basis van het bestaande normatieve testoracle)
- Exacte modulo-M ring met M=2^127-1 en SAVE(x)=1+((x-1) mod M).
- Invoer van vraag-kom: zes SAVE-eindkommen, een permutatie van [1..6], kom-id q in [1,6], een positieve geheeltallige zegel s. Het volgende id is de cyclische opvolger van q in de bewaarde druppel-46-volgorde.
- first=SAVE((bowl[q]+s+181)^2+179*bowl[next]+s).
- directionNumber=SAVE((first+s+194)^2+193*first+197*bowl[6]).
- step=+1 voor oneven directionNumber, anders -1. De stroom x(k)=SAVE(first+step*k) voor k>=0.
- Voor een exacte geordende familie van grootte n>=1: neem de kleinste macht ruimte=M^w met ruimte>=n.
- Indien w=1 is candidate=first. Anders candidate=1+sum_{j=0}^{w-1}(x(j)-1)*M^j.
- Acceptatiegrens L=floor(ruimte/n)*n. Verwerp candidate>L; elke volgende kandidaat wordt 1+((candidate-1+step) mod ruimte). Het resultaat is rang 1+((candidate-1) mod n) in [1,n].
- Voor poortindex t>=1: bereken de zes sauskommen met (stichtingsdag, stichtingsdag+t), respectievelijk (stichtingsdag, stichtingsdag-t). Selecteer kom 1, zegel 1, familie n=922. De exacte poortafstand is 41+rang, dus [42,963].
- Deze laag bepaalt uitsluitend poortafstanden, niet de kalenderpoortposities, jaarnummers of de uiteindelijke datum.

## Grenzen, onafhankelijke controle en Native-poort
- Een zelfstandig Python-BigInt-anker voor twee dagparen controleert first, step, twee korte rangen en de overgang n=M+1.
- Testoracle gebruikt een eigen implementatie met factorial/partiële permutaties en bredesample, nooit ingeladen door productie.
- 49 paren maal twee zegels maal acht checks = 784 differentiële vergelijkingen, plus 24 indexvergelijkingen poortafstanden, grenzen [42,963], index 10^101, ring-M-periode en 10 ongeldige inputs.
- Controle op negatieve dagrichting, exactheid van BigInt, n=1, n=M, n=M+1, n=M^2+1, n=10^100.
- Alleen completed Native+verify met log van concrete tests/assertions laat DISCOVERY06 slagen. Geen rerun van eerdere succesvolle SHA, geen merge/main.

## NEXT
Na geverifieerde Native/verify: Stage2 DISCOVERY07 — een van beide richtingen van de monotone poortlijn met begrensde index-opzoeking, onafhankelijk differentieel testoracle en beginanker op stichtingsdag. Geen volledige jaartoekenning zonder apart contract.
