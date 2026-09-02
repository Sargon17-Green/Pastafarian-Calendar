# Architektura první fáze

První fáze smí vytvořit pouze neutrální infrastrukturu. Proto jsou přítomny čtyři obecné vrstvy:

1. `MonsterContext` vlastní stav jediného volání a není sdílen mezi invokacemi.
2. `dispatchBase` provádí pouze základní přechody životního cyklu bez historické logiky.
3. `validateDays` ověřuje vstupní celé dny; typ `Integer` už sám zajišťuje přesnost bez přetečení.
4. `recordMetric` mění jen pozorovací stav a nesmí ovlivnit žádné normativní rozhodnutí.

Žádný příznak, cache, legacy cesta, alias, latch ani záplata z fází 2 až 53 zde není přítomna.
