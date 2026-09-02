# Arquitectura de Bootstrap

Stage 1 introdueix només infraestructura general i neutral.

`new_monster_context` crea un context propietat d'una única invocació. Conté identitat, estat de cicle de vida, tres espais transaccionals genèrics i observabilitat no semàntica. No conté flags, latches, aliases, caches ni camps específics de cap defecte futur.

`bootstrap_dispatch` valida l'entrada i modifica només l'estat local del context. Les mètriques del Bootstrap no són entrada de cap decisió normativa.

L'oracle viu en fitxers separats i no forma part de la ruta de producció. La seva aritmètica d'enters arbitraris usa dígits enters en base 10000 perquè cada producte elemental quedi molt per sota del límit de l'enter signat de 32 bits de R. La multiplicació normalitza el carry durant cada cel·la i la divisió llarga tria cada dígit del quocient per cerca binària entera entre 0 i 9999.

La memòria semàntica mutable de l'oracle es limita al cache de portes. Cada porta és una funció només del seu índex i, per tant, aquest cache no depèn de l'historial de consultes. No hi ha cache de resultats finals ni de l'estructura anual en Stage 1.

No s'ha afegit cap component històric dels 26 pedaços. La complexitat específica s'ha de crear només en el seu stage corresponent.
