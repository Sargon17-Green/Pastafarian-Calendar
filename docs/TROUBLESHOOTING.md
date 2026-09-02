# Depanare Stage 1

## `jconsole` pornește o unealtă Java

Pe unele sisteme, numele `jconsole` aparține consolei JMX din Java. Pentru această linie este necesar executabilul consolei limbajului J. Unele instalări îl expun drept `ijconsole`.

Verificarea corectă este ca executabilul să raporteze o versiune J 9.7.x și să poată evalua expresii J.

## Testele nu trebuie mutate într-un alt limbaj

Dacă runtime-ul J lipsește, se instalează J; nu se rescrie generatorul, oracle-ul sau suita într-un alt limbaj.

## Fișierul de fixture-uri lipsește

Rulați `test/generate_stage01_fixtures.ijs` cu J. Fixture-urile sunt regenerate local numai din oracle-ul acestei linii.
