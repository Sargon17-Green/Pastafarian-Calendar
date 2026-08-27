# Oz + hrvatski — etapa 1/55

Ovo je korijen novoga samostalnog repozitorija za implementacijsku liniju Pastafarijanskoga kalendara u jeziku Oz, s hrvatskim kao jedinim izvornim ljudskim jezikom. Repozitorij je izrađen od nule; ne pretpostavlja, ne nasljeđuje i ne treba nikakav raniji repozitorij.

Linija je izvedena iz ugrađenoga normativnog dodatka zadatka. Nije kopiran, preveden, pokrenut, uspoređen ni hashiran nijedan drugi implementacijski kod, referentni algoritam, ispitni skup, očekivani izlaz, generirana tablica ili međuartefakt druge programske linije.

## Sadržaj prve etape

- `src/SourceLanguageCatalog.oz` — zamrznuti hrvatski katalog 17 kotleta i 47 mjeseci; semantika koristi samo `canonicalIndex`.
- `src/MonsterBootstrap.oz` — neutralni proizvodni kontekst, početna validacija i ulazna funkcija koja prije povijesnih etapa namjerno ne vraća kalendarski rezultat.
- `test/NormativeReference.oz` — čisti testni normativni referentni algoritam izveden iz ugrađenoga dodatka.
- `test/Stage01Tests.oz` — lokalni Oz ispitni sklop s ručno izvedenim malim očekivanim vrijednostima i invarijantama.
- dokumentacija i artefakti etape 1 u korijenu i u `artifacts/stage-01/`.

Proizvodni kod ne uvozi testni referentni modul i nema put kojim bi mogao vratiti njegov rezultat.

## Struktura repozitorija

```text
README.md
DEVELOPMENT_STAGE.md
SOURCE_LANGUAGE_CATALOG.md
SPAGHETTI_DEVELOPMENT_HISTORY.md
HANDOFF_STAGE_01.md
MANIFEST.txt
src/
  SourceLanguageCatalog.oz
  MonsterBootstrap.oz
test/
  NormativeReference.oz
  Stage01Tests.oz
artifacts/stage-01/
  EXPECTED_FIXTURES.md
  RUNTIME_PROBE.txt
  STATIC_REVIEW.txt
  TEST_RESULTS.txt
```

## Prevođenje i lokalna provjera

Iz korijena repozitorija:

```text
ozc -c src/SourceLanguageCatalog.oz -o src/SourceLanguageCatalog.ozf
ozc -c src/MonsterBootstrap.oz -o src/MonsterBootstrap.ozf
ozc -c test/NormativeReference.oz -o test/NormativeReference.ozf
ozc -x test/Stage01Tests.oz -o stage01-tests
./stage01-tests
```

Očekivani završni redak:

```text
SVE PROVJERE ETAPE 1 SU PROŠLE
```

U radnom okruženju izrade nema `ozc` ni `ozengine`, pa izvršna provjera nije mogla biti obavljena. Zbog toga `LAST_COMPLETED_STAGE` ostaje `0` dok isti paket stvarno ne prođe gornji Oz ispitni sklop.
