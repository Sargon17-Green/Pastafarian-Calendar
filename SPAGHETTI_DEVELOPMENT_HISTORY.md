# Spagetti fejlesztési történet

## 1. szakasz — induló alap

A megvalósítás üres projektfából indult, más megvalósítás forrása, tesztje, fixture-je, kimenete, gyorsítótára, naplója vagy hash-összehasonlítása nélkül.

Ebben a szakaszban csak általános és semleges infrastruktúra jött létre. A `MonsterContext` meghívásonként külön példány, a szemantikai bemenetet nem osztja meg más hívásokkal. A validációs, diszpécser-, hibaburkoló- és metrikaréteg még nem tartalmaz történeti hibához vagy későbbi folthoz kötött viselkedést.

A tesztelési célú normatív referencia közvetlenül a beágyazott A függelék műveleteit követi. A termelési út nem hívja ezt a referenciát, és nincs oracle-alapú visszaesési út.

A magyar `SourceLanguageCatalog` a kanonikus indexeket változatlanul őrzi, és a névszöveget csak megjelenítési feloldáskor használja. Az indexek sorrendjét semmilyen magyar rendezési szabály nem módosíthatja.

Történeti hibamechanizmus vagy javítófolt ebben a szakaszban még nem került a termelési kódba.
