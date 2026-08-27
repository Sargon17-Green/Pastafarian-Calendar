# Arkitektur i steg 1

## Ren referens

`NormativeReference` är ett testorakel och hålls åtskilt från produktionsskelettet. Det implementerar den normativa kedjan från diskreta dagar till år, kotletter, månader och femfältsresultat. Produktionskod får aldrig använda oraklet som reservväg eller resultatkälla.

Oraklet använder `canonicalIndex` för namnval och löser svensk text först när resultatet byggs. Portindex, årtal, svarstal och kombinatoriska antal använder den lokala exakta heltalstypen där obegränsad storlek behövs.

## Neutral monstergrund

Produktionsskelettet består i steg 1 av:

`MonsterContext -> MonsterManager -> MonsterValidationManager -> MonsterDispatcher -> MonsterMetricsShell`

Detta är avsiktligt bara en neutral grund. Kontexten ägs av en enda anropning. Mätdata ligger i samma kontext men läses inte tillbaka till någon normativ beräkning. Ingen global muterbar semantisk state finns i steg 1.

Skelettet innehåller inga felaktiga historiska formler, inga framtida kompatibilitetsflaggor och inga korrigeringsvägar. Sådana ärr får uppstå först när respektive historiskt steg nås.

## Felhantering i detta steg

Valideraren kastar ett uttryckligt fel vid ofullständig kontext. Det finns ännu ingen semantisk återhämtningsväg eller retry-logik, eftersom en sådan konkret struktur skulle föregripa senare historik. Steg 1 etablerar endast ägarskap och en plats där senare lager kan växa.
