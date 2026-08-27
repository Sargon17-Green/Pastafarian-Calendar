# Istoria de developa del monstro de spaghetti

## Stage 1 — Bootstrap

### Intende

La linia LabVIEW/G + Elefen comensa de zero. No implementa estranjer es un fonte de code, prova, fixture, resulta, tabla, cache, log, trace, o hash.

### Cosa creada

La Stage 1 defini la catalogo canonica de lingua fonte, la esceleto de projeto LabVIEW, la contratos de VIs, la proprieta de state, la separa entre state semantical e observabil, e la forma de la oracle G sola per provas.

### Crese monstruosa

Sola capas jeneral e neutral es permitida: `MonsterContext`, dispatcher base, validor base, error wrapper base, e managers de logs/metrics sin poder semantical. No flag o cicatrice de un patch futur es permitida.

### Estado real

La arquitetura e la handoff es preparada. La VIs binaria no es creada en esta ambiente, car LabVIEW no es presente. Per esta razona, la Bootstrap no es completa e no debe es marcada `GREEN` ancora.
