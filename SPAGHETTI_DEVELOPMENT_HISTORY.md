# Historia de desenvolvemento do monstro de espaguetes

## Stage 1 — Bootstrap

### O que se construíu

O ramo comezou desde cero. Creáronse o catálogo galego de nomes, unha referencia normativa limpa para probas, as probas e casos fixos locais, e unha infraestrutura neutral de contexto, despacho, validación, erros e métricas.

### O que aínda non ocorreu

Non se introduciu ningunha hipótese histórica incorrecta. Non existe ningún compoñente `old...`, `legacy...`, parche, alias de bowls, snapshot de bowls, latch da orde 46, selector nesgado, filtro tardío de anos, cache estrutural defectuosa, cálculo fantasma nin familia virtual propia dos Stages posteriores.

### Capa de monstruosidade engadida

A única capa estrutural é un contexto por invocación cun despachador base e observabilidade neutral. Esta capa non calcula ningunha parte da data e non pode modificar semántica normativa.

### Propiedade do estado

Cada `monster_context` pertence a unha única invocación. O módulo de produción non ten estado semántico mutable compartido. O oráculo usa exclusivamente asociacións locais pasadas por argumentos para as memorias de DP e para o estado das portas. Eliminouse a dependencia de predicados dinámicos e de `assert`/`retract`; non se usa tabulación, base `recorded` nin variables globais non retrocedibles como estado do algoritmo.

Preparáronse regresións específicas para repetición, orde A→B→A e fallo seguido de reintento. A verificación nativa destas regresións segue pendente unicamente porque a contorna dispoñible non contén un runtime Prolog.
