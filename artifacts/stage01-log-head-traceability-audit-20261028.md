# Auditoría estática del registro de Stage 01 — 2026-10-28

## Identidad y límites

- Proyecto: `PC-BRANCH-WAT-SPANISH`; implementación `WAT+Español`.
- Repositorio: `Sargon17-Green/Pastafarian-Calendar`.
- Commit exacto auditado (antes de añadir este documento): `0df9cadba5b3bc241e5e9cb495fa019194841ec3`.
- Registro de referencia: `artifacts/stage01-verification.log` (blob Git `bd33a996bc4811cbf1490bc6300e056f5b076cad`).
- Tipo: **auditoría estática de trazabilidad**, NO ejecución nativa nueva ni validación de resultados semánticos.

## Comprobaciones efectuadas

Se extrajeron del registro todas las líneas `$ wasmkit run ARCHIVO.wat EXPORT` y se consultaron directamente los archivos WAT del commit exacto indicado. Se comprobó que cada ruta existe y contiene la declaración `(export "EXPORT"` correspondiente. Se contó también la presencia de una línea de resultado `[WasmTypes.Value.…]` y un `TIEMPO_REAL=` por comando registrado.

| Comprobación | Resultado |
| --- | ---: |
| Comandos históricos en el registro | 56 |
| Comandos distintos (archivo + exportación) | 49 |
| Archivos WAT distintos consultados | 14 |
| Referencias a archivos inexistentes | 0 |
| Exportaciones referenciadas no encontradas | 0 |
| Comandos sin línea registrada de resultado | 0 |
| Comandos sin línea registrada de duración | 0 |

Estos hechos **no prueban** que las 56 ejecuciones hayan sido repetidas ahora, ni que su salida sea correcta; solo establecen coherencia documental con los archivos actuales. La reverificación nativa aislada de dos exportaciones del catálogo está documentada por separado en `artifacts/stage01-catalog-native-recheck-20261028.md`. La CI disponible para este commit verifica el bloqueo de nombres canónicos, no la batería nativa integral.

## Identificadores de blobs Git auditados

| Archivo | SHA del blob Git |
| --- | --- |
| `src/monster_bootstrap.wat` | `a803abe599de3b8df4f9ad0afd1136c2442cb2aa` |
| `src/source_language_catalog.wat` | `736d4359e56273c985728096e35d21ee289ab9c8` |
| `src/wide_integer.wat` | `511e005f4cb47829aeb0d225d590774c64789027` |
| `oracle/normative_wide_counts.wat` | `63b44e24ee090e430deb1e261824a6ff6ec13b4a` |
| `oracle/normative_sauce_wide.wat` | `1047901e6eebbc09bc919a188a6f4c0bcad6a68b` |
| `tests/normative_selector.wat` | `026c98e66c201b62f71e977ca51babb58d845be9` |
| `tests/normative_month_lengths.wat` | `398970cc19c3ee62689b262dc286f417af8ab314` |
| `tests/normative_weaving_fast_count.wat` | `efd5163ad9fc60fe1495e72271e3c941b4b6fcfb` |
| `oracle/normative_calendar_wide.wat` | `70267bb5730678f81d6138a2224d6b8d9a193eb` |
| `tests/normative_foundation_structure_integrated.wat` | `812f2de51c666e402115da55e103e9b7d38ad742` |
| `tests/normative_final_resolver.wat` | `3797c9a62b42211908eed83880bb617f2ffdf076` |
| `tests/normative_gate_year.wat` | `8cca817c7b5838134b7b8db0620967d5f267a750` |
| `oracle/normative_wide_gate_year.wat` | `30879e58dc61197162b6dc8595ab95ef521cbd93` |
| `tests/normative_sauce.wat` | `c055dd348c220bb361a9020bbbee0de1b71248e7` |

## Continuación sin alterar la etapa

`LAST_COMPLETED_STAGE=1`; ninguna ruta de producción de `Stage02 / DISCOVERY 01` se incorporó. La autorización histórica para trabajar la etapa 2 existe, pero el paquete original y su manifiesto/criterios de aceptación no están recuperados. Se mencionan entregas no equivalentes en conversaciones previas; no se debe sustituir una por otra por su nombre. Próxima acción: recuperar el paquete original de Stage 2, identificar su procedencia y manifest, hacer diff contra el HEAD verificado, comprobar los casos `M,2M,3M,M+1` y los PASS de contexto, y solo entonces decidir la aplicación del primer cambio ausente. No crear prototipo alternativo, no modificar `main`, no fusionar PR, no declarar `Stage 2` completado por esta auditoría.
