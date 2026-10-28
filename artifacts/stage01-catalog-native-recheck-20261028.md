# Reverificación nativa del catálogo — 28-10-2026

## Procedencia y alcance

- Repositorio: `Sargon17-Green/Pastafarian-Calendar`.
- Rama: `WAT+Español`.
- HEAD verificado antes de esta entrega: `483b1a89201fc6d0f0095ec4b08e261bd4ca9279`.
- Archivo ejecutado: `src/source_language_catalog.wat`, recuperado de ese HEAD.
- SHA-256 del archivo reconstruido y verificado contra `CANONICAL_NAMES_LOCK.sha256`:
  `bee74489cffacb8fba66ae824cd0e91a882e7d1a14017ec669ec299162434641`.
- Ejecutor nativo: WasmKit `0.1.6`, `/usr/local/swift/usr/bin/wasmkit`.
- La prueba se realizó sin modificar el código WAT. No es una nueva ejecución de las 56 pruebas de la etapa 1.

## Ejecuciones nuevas, aisladas

```text
$ wasmkit --version
0.1.6
$ wasmkit run src/source_language_catalog.wat test_catalog_complete
[WasmTypes.Value.i32(1)]
$ wasmkit run src/source_language_catalog.wat test_catalog_reconciled_toponyms
[WasmTypes.Value.i32(1)]
```

Los dos resultados valen `1`; ambas comprobaciones nativas del catálogo aprobaron. La entrada usada para WasmKit fue idéntica, byte por byte, a la versión bloqueada de GitHub por la comprobación SHA-256 anterior.

Una invocación adicional, `wasmkit run ... catalog_cutlet_ptr 8`, **no aprobó**: WasmKit terminó con `CLI/Run.swift:239: Fatal error: unknown type` e `Illegal instruction`. El fallo ocurrió al interpretar un argumento del CLI; no demuestra un defecto semántico del módulo, pero tampoco constituye una prueba válida de esta exportación. No se repitió la misma invocación fallida.

## Continuación documentada

La documentación de la rama mantiene `LAST_COMPLETED_STAGE=1`; la etapa 2 (`DISCOVERY 01`) no aparece en el árbol remoto actual. La comparación del commit `9fb7b61979879a9876ab8c2c43421ee03a414293` con el HEAD inspeccionado muestra únicamente el workflow y los hashes de bloqueo de nombres, más cambios en el catálogo, sin incorporar el módulo de la etapa 2.

Se recuperó evidencia de autorización previa para comenzar/preparar la etapa 2 el 29-08-2026, y una instrucción posterior de preparar más etapas el 14-09-2026. Sin embargo, las entregas ZIP previamente enumeradas (`WAT_Espanol_Stage02_Discovery01(1).zip` y posteriores) no se encontraron en las ubicaciones de archivos y Drive accesibles durante esta verificación. Los equipos remotos de Desktop Commander figuran desconectados.

**Siguiente acción:** recuperar el paquete original y la evidencia de aceptación de `Stage02_Discovery01`, contrastarlos con el HEAD actual y sus bloqueos de nombres; aplicar únicamente el primer cambio ausente después de comprobar compatibilidad. Ejecutar las pruebas nativas normativas y la regresión correspondiente, distinguiendo `EXPECTED_RED` de `PASS`, antes de registrar la etapa o avanzar. No crear una implementación alternativa del descubrimiento ni incorporar a ciegas la serie de nueve ZIP. No modificar `main` ni fusionar PR.

Esta entrega solo añade evidencia de verificación y continuidad; no declara completada la etapa 2, no altera la semántica del calendario y no constituye una prueba nativa integral ni una nueva aprobación del conjunto de 56 casos.
