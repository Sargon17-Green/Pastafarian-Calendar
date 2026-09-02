# Arquitectura neutral do Stage 1

O Stage 1 crea só a infraestrutura xeral autorizada. Non existe aínda ningún camiño herdado nin ningún parche histórico.

`monster_context` pertence a unha única invocación e contén unicamente identidade de entrada, fase, estado, traza básica, métricas neutras e erro. Non contén bowls, drops, gates, caches semánticas nin bandeiras asociadas aos parches 01–26.

`monster_manager_execute/3` chama un despachador base con tres estados útiles: entrada, validación e preparado. A validación comproba só que os dous días sexan enteiros. As métricas están contidas no propio termo da invocación e son observabilidade non semántica.

`calendar_date_spaghetti/3` non devolve unha data no Stage 1. Tras validar o Bootstrap, produce un erro máquina explícito que indica que a ruta de integración pertence ao Stage 54. Isto impide que a produción use o oráculo como atallo e evita introducir antes de tempo os defectos herdados.

A referencia limpa de `src/normative_oracle.pl` é exclusivamente de proba. Non é chamada polo módulo de produción. O seu estado auxiliar de DP e de portas é funcional: créase por cálculo e pásase mediante argumentos usando asociacións persistentes, sen predicados dinámicos nin estado global mutable.

A auditoría detallada da propiedade do estado está en `docs/STATE_OWNERSHIP_STAGE01.md`.
