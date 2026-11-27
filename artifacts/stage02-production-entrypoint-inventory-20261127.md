# Inventario de puntos de entrada de producción — 2026-11-27

Proyecto PC-BRANCH-WAT-SPANISH; rama WAT+Español, no protegida; HEAD auditado c0c6eb55295d64b3b30767b7f48ab0d0b9cf6cb3, confirmado por la API de rama. Auditoría estática/documental, sin nueva ejecución Native ni modificación de módulos.

## Inventario cerrado

Git trees recursive=1 devolvió 183 entradas, truncated=false. El árbol src contiene exactamente tres módulos WAT:
- src/monster_bootstrap.wat (a803abe599de3b8df4f9ad0afd1136c2442cb2aa): 10 exportaciones (memoria, contexto nuevo, despacho neutral, fase, estado, token, dos métricas y dos pruebas). Sin importaciones. El despacho devuelve 1 tras validar el modo y cambiar fase/estado/token; no resuelve una fecha.
- src/source_language_catalog.wat (736d4359e56273c985728096e35d21ee289ab9c8): 6 exportaciones (memoria, punteros de chuleta/mes, longitud y dos pruebas); sin importaciones.
- src/wide_integer.wat (511e005f4cb47829aeb0d225d590774c64789027): 19 exportaciones (memoria, arena, enteros exactos y pruebas); sin importaciones.

No hay src/production/ ni otro módulo de producción fuera de src: el inventario de fuentes ejecutables está limitado a src/, oracle/, tests/ y workflows de QA. Los cuatro módulos oracle son salsa, conteos, puertas/años y calendario integrado; todos sin importaciones. El módulo oracle/normative_calendar_wide.wat (70267bb5730678f81d6138a2224d6b8d9a193eb8) exporta wide_calendar_date, construcción de días amplios, cinco accesores de resultado, funciones normativas y pruebas; no exporta calendar_date. tests/normative_final_resolver.wat es una prueba de resolución parcial (result_ptr y pruebas), no una API de producción. No se ha ejecutado código para esta clasificación.

El árbol recursivo del handoff 9fb7b61979879a9876ab8c2c43421ee03a414293 también devolvió truncated=false: mismas tres rutas src, mismo bootstrap, entero amplio, arquitectura y calendario oracle (catálogo anterior 5f6a59401a1a6c325c97754b576249057395b7bd). ARCHITECTURE_STAGE01.md c348f6ab2815bc94fd625d9b1b2489d8dd76419d define explícitamente producción neutral y prohíbe llamadas al oracle; DEVELOPMENT_STAGE.md 8e9e1a01d1a1d68772b5ed4f0a1d4fc70c420226 marca BOOTSTRAP, LAST_COMPLETED_STAGE=1. README concuerda.

## Comparación directa con el ZIP Stage01 Production Rebuild

Se materializó únicamente el ZIP identificado en el seguimiento: WAT_Espanol_Stage01_Production_Rebuild.zip. CRC de todos sus miembros correcto; SHA256=6a8c0458f00fbda8fbb58f89ae014f9d3bf2e7a9340a1ef56bd5b87c20049c90, coincide con la auditoría previa. Contiene un único módulo WAT, src/production/spaghetti_calendar.wat, y tres documentos. DEVELOPMENT_STAGE marca BASELINE/PATCH00, LAST_COMPLETED_STAGE=1. Su arquitectura define calendar_date como única entrada de cálculo de producción, sin importar oracle. Las menciones al bootstrap y otros módulos en esa arquitectura no implican que estén incluidos en este ZIP.

Módulo original: 221158 bytes LF, SHA256=55302c42fb54999a42574a59e8aae37b503b0c2667eb88c7e61aea57b7800dc3, Git blob=c24ac5017f0f24e024bd7085f6a444403923ff02. 45 exportaciones, cero importaciones. En líneas 3147–3154 wide_calendar_date(cDay:i32,tDay:i32)->i32 llama a find_target_year_wide y resolve_year_structure_wide; calendar_date(calculationDay:i32,targetDay:i32)->i32 llama directamente a calendar_date_wide. Las entradas i32 son punteros a enteros amplios en la memoria del módulo, no días limitados a i32; el resultado es un puntero al registro. Los accesores devuelven el puntero del año amplio y los cuatro campos restantes.

Prueba reproducible de identidad de fuente (no equivalencia inferida por nombres): en una copia en memoria del miembro ZIP, eliminar exactamente este bloque UTF-8 LF, una vez, incluyendo la línea en blanco final:
```wat
  ;; Entrada de producción: mismo motor integrado, sin dependencia de oracle/.
  (func (export "calendar_date") (param $calculationDay i32) (param $targetDay i32) (result i32)
    (call $calendar_date_wide (local.get $calculationDay) (local.get $targetDay)))

```
Resultado 220897 bytes; SHA256=0947ed11e8c4245ee367ebb659780bfb2e297c9dd950e018ed875f11382eda1f; SHA1 de "blob 220897" + NUL + bytes = 70267bb5730678f81d6138a2224d6b8d9a193eb8, exactamente el blob Git del oracle remoto. El digest SHA256 coincide además con el manifest de SAVE(M) registrado previamente. No se escribió ni alteró el ZIP. Por identidad criptográfica el resto del motor es el mismo; no constituye dos implementaciones algorítmicamente independientes.

## Puerta de decisión

Se ha resuelto el inventario, no la autorización de cambiar la línea base. Hay dos arquitecturas incompatibles: bootstrap neutral del repositorio y baseline de producción integrado del ZIP. Restaurar el ZIP o copiar el oracle a src no sería un ajuste rutinario de QA; cambiaría la arquitectura y, si se usara el mismo motor como oracle de aceptación independiente, eliminaría la independencia. No hacerlo sin autorización explícita de reconciliación de línea base y criterio de oracle independiente. Propuesta: permitir recuperación exacta del módulo histórico como candidato aislado (no promover a producción ni aceptar Stage02); definir un oracle independiente del motor, verificar identidad/contrato y plan de aceptación antes de integrar. Alternativa: conservar la línea base neutral y construir una integración autorizada separadamente. Checksum histórico independiente del ZIP y Stage03 Patch01 siguen sin verificarse; no repetir búsquedas sin referencia nueva.

SAVE(M) oracle 13/13 previamente aceptado (run 46003858169, job 140521988680, artifact 15199930356), no rerun. Stage02 NOT ACCEPTED, Stage03 NOT OPENED. No cambio de WAT, marcador, workflow, main, merge o publicación. Este commit solamente fija el inventario y la prueba de identidad.
