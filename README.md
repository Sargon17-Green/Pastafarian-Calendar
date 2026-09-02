# Pergamí dels Temps — línia R + català

Aquest arbre és el Bootstrap independent de la implementació en R. S'ha creat des de zero a partir de la referència normativa incrustada al plec de treball. No reutilitza codi, proves, fixtures, resultats, taules generades, traces ni hashes de cap altra implementació.

## Abast de Stage 1

Stage 1 conté quatre peces deliberadament limitades: aritmètica d'enters arbitraris escrita en R base, un oracle normatiu només per a proves, un catàleg font català congelat i un esquelet general de context/dispatcher/validació/observabilitat. Encara no existeix cap defecte legacy ni cap pedaç històric dels stages posteriors.

La funció de producció `calendarDateSpaghetti` existeix només com a punt d'entrada estructural i rebutja l'execució semàntica. Això és intencionat en el Bootstrap: la ruta històrica de producció creixerà exclusivament quan arribin els stages de descobriment i pedaç corresponents.

## Execució de proves

No hi ha dependències de paquets R. Amb una instal·lació de R:

```text
Rscript tests/run_tests.R
Rscript tests/oracle_smoke.R
```

La primera ordre comprova aritmètica exacta, `SAVE`, recomptes de dies, pedres, permutacions, famílies virtuals petites, el catàleg font i l'aïllament del context. La segona fa una prova de fum determinista de la salsa normativa.

## Separació entre oracle i producció

Els fitxers `normative_*.R` són exclusivament de referència i proves. L'esquelet de producció no els crida i no disposa de cap fallback cap a l'oracle. Les proves de Stage 1 inspeccionen també aquesta separació.

## Ordre dels noms

La semàntica de noms usa únicament `canonicalIndex`. El text català es resol al final, a la capa de presentació. L'ordre alfabètic, Unicode, col·lació de locale i case-folding no poden alterar cap rank, unrank, selecció o clau semàntica.
