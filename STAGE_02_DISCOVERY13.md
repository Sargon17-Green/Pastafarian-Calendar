# Fase 2 — DISCOVERY13 — unieke koteletnamen, kom 5 en zegel 22

## Verifieerbare voorganger
- Tak: `Clojure+Nederlands`; ouder-HEAD: `fc26c88195ca8d63247abdf58dd944a8df7684ad`.
- DISCOVERY12: GitHub Actions run `41205672819`, Native job `124550143841` completed SUCCESS: **61 tests, 6307 assertions, 0 failures, 0 errors** in de ruwe log. `verify` job `124550143629` completed SUCCESS.
- Geen claim dat Fase 2, de vijf datumcomponenten, maanden of kalenderreconstructie afgerond zijn.

## Contract: zuivere invoer, uitvoer en begrenzing
- `pastafari.koteletnamen/aantal-naamreeksen(n,k)` met exacte gehele `1<=n<=17`, `1<=k<=n` geeft het exacte aantal geordende reeksen zonder herhaling `n!/(n-k)!`.
- `namen-op-rang(n,k,rank)` gebruikt eengebaseerde rang `1<=rank<=P(n,k)` en geeft de lexicografisch gerangschikte vector van precies `k` **unieke naamindices** in `1..n`. Deze indices zijn geen vertaalde labels.
- `kies-namen(lijn,berekeningsdag,doeldag[,budget])` behoudt alle velden van het bewezen resultaat van `koteletverdeling/kies-verdeling`; voegt `:name-indices` en `:name-family-count` toe.
- De **structuursaus** behoort aan de **eerste dag na de open-poortdag** van het bewezen doeljaar. Vraag uitsluitend kom `5`, zegel `22`. Selecteer via `keuzestroom/kies-rang` uit `P(17,cutlet-count)` namenreeksen. De bestaande jaar-, partitie- en foutgrenzen blijven ongewijzigd.

## Scheiding van algoritmen
- Productie gebruikt een direct gemengd-radix-quotient op de **nulgebaseerde** rang, telkens gedeeld door de resterende vakgrootte, met filtering van gebruikte indices. Geen opsomming van mogelijke permutaties.
- De bestaande normatieve oracle `normative-oracle/choose-cutlet-names` gebruikt een eigen eengebaseerde aftellus over `falling-factorial`-blokken en verwijdert per index uit de rij. Zij wordt uitsluitend in tests aangeroepen.
- Afzonderlijke testoracle: expliciete recursieve enumeratie voor `n=1..6`, alle `k=1..n`, elke rang. Daarnaast vergelijking met de normatieve onafhankelijke saus voor drie berekeningsmomenten en telkens drie doeljaren.

## Terminatie, fouten en grenzen
- Productie: hoogstens 17 naamstappen, 17 exacte productfactoren en per naamstap maximaal 17 filtervergelijkingen. Geen onbegrensde zoekactie, enumeratie of netwerk.
- Bij ongeldige `n` code `:invalid-name-pool`; bij ongeldige `k` code `:invalid-name-count`; bij ongeldige `rank` code `:invalid-name-rank`. Bestaande fouten van jaar/poort/saus/keuzestroom blijven doorgegeven.
- Randgevallen: `P(17,17)=17!`, eerste rang `[1..17]`, laatste rang `[17..1]`, bij `k=6` laatste rang `[17,16,15,14,13,12]`. Controleer eerste/laatste, 100-cijferige invoer, decimale/nil-waarden en geerfde fouten.

## Acceptatiepoort
1. Geautomatiseerde brute-force vergelijking voor **alle** kleine rangwaarden, niet alleen steekproeven.
2. Normatieve `choose-cutlet-names` en oorspronkelijke jaar/partitiebewijs gelijk aan productie bij negen doeljaarcombinaties; rechtstreekse versus verlengde lijn gelijk.
3. Tests voor unieke indices, familieomvang, kom 5/zegel 22, eerste/laatste rang, expliciete foutcodes en fouten van onderliggende lagen.
4. Statische delimiters en GitHub source/test/runner/workflow/marker/contract readback, dan exact één nieuwe SHA met Native `clojure -M:test` en `verify` op GitHub Actions.
5. DISCOVERY13 mag pas worden aanvaard na **beide** completed SUCCESS op diezelfde SHA plus ruwe aantallen Native tests/assertions en nul failures/errors. Tot dan: uitsluitend commit/QA gereed.

## NEXT
Na acceptatie: DISCOVERY14 — materialiseer grenzen van de bewezen koteletten uit de positieve partitie en gekozen unieke naamindices met een eindig poortindexcontract, zelfstandig normatief orakel en behoud van open- en sluitdagen. Geen main/merge, geen Stage 3 of datum-PASS.
