# Fase 2 — DISCOVERY18 — exacte grote maandweving-telling

## Gecontroleerde voorloper
- Branch `Clojure+Nederlands`, DISCOVERY17 SHA `baf57791f44c9c243ab626c2e8b068b79044e5c9`.
- GitHub Actions run 41244595871: Native job 124665287086 completed SUCCESS; ruwe log: 84 tests, 39004 assertions, 0 failures, 0 errors; verify job 124665287344 completed SUCCESS.
- Geen Stage2-PASS en geen volledige vijfdelige datum.

## Invoer, uitvoer en grenzen
- Nieuwe, gescheiden functie: `aantal-wevingen-groot(maandlengtes)`.
- Invoer: geordende maandlengtes 1..47, elk geheel getal 4..123, som <= 5778.
- Uitvoer: exact niet-negatief BigInt aantal multisetwoorden met eerste én laatste maandvoorkomens oplopend in maand-ID.
- Illegale invoer: `:invalid-weaving-family`; geldige lengtes buiten maxima: `:weaving-bound-exceeded`.
- DISCOVERY17 `aantal-wevingen`, `weving-op-rang` en `kies-maandweving` behouden hun bewezen 1..5-maanden/32-dagen grens. Geen datum-/ranguitbreiding op basis van een telbewijs alleen.

## Constructieve, zelfstandige afleiding
- Bij een geldig woord met maanden 1..k staat de **laatste** letter altijd gelijk aan k. De eerste positie van k, p, is daarom de enige toestand die voor toevoeging van maand k+1 nodig is.
- `F_k(p)` telt geldige woorden met eerste k op positie p; start `F_1(1)=1`.
- Schrijf `T=sum_{i<=k} a_i` en `b=a_{k+1}`. Voeg b gelijke nieuwe letters toe in de T+1 gaten van het oude woord. Als het eerste nieuwe gat u is, moet u>=p; het laatste nieuwe gat moet T zijn.
- De nieuwe eerste-positie is u+1, en het aantal invoegingen met dit eerste gat is `C(b+T-u-2,T-u)` (ook voor u=T, waarde 1). Dus:
  `F_{k+1}(u+1) = C(b+T-u-2,T-u) * sum_{p<=u} F_k(p)`, voor 1<=u<=T.
- Prefixsommen geven iedere volgende positie in O(1) BigInt-operaties. De gewichten `w(t)=C(b+t-2,t)` volgen exact via `w(0)=1; w(t+1)=w(t)*(b+t-1)/(t+1)` met gehele deling.
- Totale complexiteit: O(m*N) BigInt-bewerkingen (rekening houdend met groeiende operandgrootte), O(N) BigInt-geheugen; N<=5778, m<=47. Er worden geen woorden of restvectorproducten gematerialiseerd.

## Onafhankelijke controles en acceptatie
- Compareer met de oudere bottom-up restvector-DP voor 11 kleine families; deze is algoritmisch verschillend.
- Compareer met `C(a+b-2,a-1)` voor vier 2-maandsfamilies, inclusief [123,123].
- Omkeerbijectie op drie asymmetrische families.
- Eindige ankers: 47x4 geeft resultaat modulo 1000000007 = 223578939; [123]x46+[120] (precies 5778) geeft 368726924. Deze ankers komen van een apart Python-referentiemodel met dezelfde invoegrecurrence en gelden niet als onafhankelijk algoritmisch bewijs.
- Foutcodes en onveranderde DISCOVERY17-ranggrens moeten slagen. Log niet-afgedwongen runtime voor 47/5778. CI-job heeft timeout van 20 minuten.
- Alleen een exacte SHA, Native `clojure -M:test` plus `verify` beiden completed SUCCESS, en ruwe test-/assertionaantallen zonder fouten vormen DISCOVERY18 Native-acceptatie.
- Geen main/merge, geen Stage2-/datum-PASS.

## NEXT
DISCOVERY19: exacte lexicografische rangbepaling voor grote maandfamilies ontwerpen en begrensd bewijzen, met een onafhankelijk rangoracle op kleine families en expliciete bescherming tegen combinatorische explosie. Pas na afzonderlijk bewijs mag de productie-selectiefunctie grote families aan.
