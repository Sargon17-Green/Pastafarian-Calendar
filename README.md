# Kalendaryong Pastafarian — PowerShell + Filipino

## Stage 19 — Patch 09

Pinananatiling pisikal ang Discovery 09 fixed-bowl scar:

```text
position 1 -> oldBowls[1]
position 2 -> oldBowls[2]
position 3 -> oldBowls[3]
```

Hindi ito binubura o inaayos sa mismong raw helper. Ang Patch 09 wrapper ay talagang nagpapatakbo muna rito at kino-capture ang raw pours.

Pagkatapos, ini-install ang alias table:

```text
bowlAlias[position] = order[position]
```

para sa positions `1..6`.

Lahat ng corrected bowl reads para sa pour positions `1,2,3` ay dumadaan sa `bowlByLegacyPosition`, kaya ang bowl ID ay mula sa current corrected permutation order.

Sa Foundation fixture, ang unang order ay:

```text
5,4,3,6,2,1
```

at ang alias table ay:

```text
0,5,4,3,6,2,1
```

Ang lahat ng 46 isolated corrected pour sets ay inaasahang GREEN.

Wala pang Stage 20 / Patch 10 `vaultOld`, pending bowl updates, o in-place bowl-update logic.
