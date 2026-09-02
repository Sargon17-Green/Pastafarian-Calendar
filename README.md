# Haskell + čeština — zaváděcí fáze

Tento strom vznikl od nuly pro samostatnou implementační větev. V této fázi obsahuje pouze neutrální produkční kostru, lokální normativní referenci napsanou v Haskellu, testovací infrastrukturu a zmrazený katalog českých názvů.

Normativní výpočty používají výhradně přesné celé číslo `Integer`. Kód nepoužívá plovoucí desetinnou aritmetiku, cizí runtime ani vazbu na jiný jazyk.

Produkční kostra v první fázi záměrně ještě neimplementuje historické vady ani jejich záplaty. Funkce `calendarDateSpaghetti` proto vrací explicitní stav, že autoritativní produkční cesta ještě není v této fázi dostupná. Normativní reference je oddělená v modulu `Pastafari.NormativeOracle` a produkční modul ji neimportuje.

## Spuštění

```text
cabal build all
cabal run stage01-tests
```

## Jazykový katalog

Kanonické pořadí názvů je určeno pouze polem `canonicalIndex`. Český text se používá až při prezentaci výsledku a nikdy nevstupuje do rankingu, unrankingu, výběru ani do sémantického klíče cache.

Pro známá vlastní jména se používá ustálená česká podoba, pokud existuje (`Lagaš`, `Akkad`, `Ninive`, `Babylón`). U umělých zvukových názvů je zmrazená podoba `Palguraš` a `Karšumav`. Tato podoba je součástí katalogu a po první fázi se bez výslovné změny specifikace nemění.
