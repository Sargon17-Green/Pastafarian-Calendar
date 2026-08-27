# Beslut 1A: de tolv efteromrörningarna

Den bindande läsningen i denna implementeringslinje är:

```text
savedBowlSum = SAVE(sum(oldBowls) + 149 * stirNumber)
```

Samma sparade värde används både för att bestämma skålordningen i den aktuella omrörningen och som den summa som läggs till i varje skåls blandning.

Det skapas alltså inte ett separat sparat värde för den råa summan av de sex gamla skålarna. Beslutet är fast för denna specifikation och får inte ändras under den historiska utvecklingen.
