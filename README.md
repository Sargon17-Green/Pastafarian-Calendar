# Pastafarian Calendar — Prolog + galego

Este directorio é un ramo novo creado desde cero para o desenvolvemento histórico do monstro de espaguetes. O Stage 1 contén só a infraestrutura neutral permitida, o catálogo da lingua fonte e un oráculo normativo de probas derivado do apéndice normativo incorporado no encargo.

Non se empregou ningún outro ramo nin ningunha implementación noutra linguaxe como fonte de código, probas, resultados esperados ou táboas xeradas.

## Requisito de execución

Recoméndase SWI-Prolog cun soporte de enteiros de precisión arbitraria. O código normativo non emprega coma flotante.

## Execución das probas

```text
swipl -q -f test/run_tests.pl
```

## Estrutura

- `src/source_language_catalog.pl`: catálogo galego con índices canónicos fixos.
- `src/normative_oracle.pl`: referencia normativa limpa, só para probas.
- `src/monster_bootstrap.pl`: contexto, despachador, validación, erros e métricas neutras do Stage 1.
- `test/stage01_tests.pl`: probas do Bootstrap e da referencia normativa.
- `test/ownership_stage01_tests.pl`: probas específicas da propiedade e do illamento do estado.
- `test/run_tests.pl`: punto de entrada das probas normais e de propiedade.
- `docs/STATE_OWNERSHIP_STAGE01.md`: auditoría da propiedade do estado semántico.
- `DEVELOPMENT_STAGE.md`: estado formal do desenvolvemento.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`: historia escrita só ata o punto realmente alcanzado.

Para a comprobación pesada opcional:

```text
swipl -q -f test/run_heavy_tests.pl
```
