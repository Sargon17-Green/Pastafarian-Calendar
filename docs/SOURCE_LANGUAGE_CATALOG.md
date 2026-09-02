# SourceLanguageCatalog 1.0.0

Kjeldekatalogen er frosen etter Stage 1. Den normative rekkjefølgja kjem berre frå `canonicalIndex`. Tekst, Unicode-rekkjefølgje, alfabetisering, kasusbøying og locale-collation får aldri påverke rank, unrank, cache-nøklar eller val.

## Omsetjingsregel

Ord og uttrykk med vanleg tyding er omsette etter tydinga til naturleg nynorsk. Fleirordsuttrykk blir halde samla som eitt namn. Døme er `fire delar av ni`, `tre delar av fem`, `den tomme krukka` og `den stengde døra`.

## Regel for namn og lydformer

Etablerte stad- og kulturnamn bruker ei stabil latinsk form som er vanleg i norsk fagtekst, til dømes `Lagash`, `Akkad`, `Eridu`, `Uruk`, `Ninive` og `Babylon`. Oppdikta lydformer utan leksikalsk tyding blir ikkje omsette semantisk. For dei lydformene som finst i denne katalogen, er translittereringa frosen som `Palgurash` og `Karshumab`.

Når den kjeldeortografiske forma blir lesen bokstavleg for slike oppdikta namn, bruker denne lina følgjande relevante konsonantverdiar: p, b, g, k, l, m, r og `sh` for sj-lyden. Vokalteikn blir attgjevne med a, i eller u når dei er uttrykte i kjelda. Den frosne katalogtabellen under er endeleg autoritet for presentasjonsstrengen i denne implementasjonslina.

## Kottletnamn

| canonicalIndex | nynorsk kjeldestreng |
|---:|---|
| 1 | bronse |
| 2 | rev |
| 3 | nyre |
| 4 | Lagash |
| 5 | tanke |
| 6 | fire delar av ni |
| 7 | Palgurash |
| 8 | papyrus |
| 9 | klase |
| 10 | skorpion |
| 11 | oske |
| 12 | kveite |
| 13 | elv |
| 14 | latter |
| 15 | Akkad |
| 16 | horn |
| 17 | den tomme krukka |

## Månadsnamn

| canonicalIndex | nynorsk kjeldestreng |
|---:|---|
| 1 | leire |
| 2 | granateple |
| 3 | olboge |
| 4 | misunning |
| 5 | Eridu |
| 6 | tannkrem |
| 7 | tre delar av fem |
| 8 | Karshumab |
| 9 | leopard |
| 10 | tinn |
| 11 | tåke |
| 12 | virak |
| 13 | handtein |
| 14 | ribbein |
| 15 | johannesbrød |
| 16 | Uruk |
| 17 | skam |
| 18 | kamel |
| 19 | kopar |
| 20 | brønn |
| 21 | eggeplomme |
| 22 | stjerne |
| 23 | honning |
| 24 | milt |
| 25 | kalkstein |
| 26 | glede |
| 27 | fiken |
| 28 | Ninive |
| 29 | frosk |
| 30 | tjøre |
| 31 | lys |
| 32 | den stengde døra |
| 33 | sesam |
| 34 | nakke |
| 35 | sølv |
| 36 | lilje |
| 37 | storm |
| 38 | esel |
| 39 | mjøl |
| 40 | anger |
| 41 | Babylon |
| 42 | tunge |
| 43 | lin |
| 44 | salt |
| 45 | pære |
| 46 | boge |
| 47 | sand |

## Locale-regel

Eventuelle framtidige locale-lag skal berre omsetje frå den frosne nynorske kjeldestrengen. Semantikken går alltid frå `canonicalIndex` til kjeldestreng og deretter til locale-presentasjon, aldri motsett veg.
