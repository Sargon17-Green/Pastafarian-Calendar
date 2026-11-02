# QA nativa adicional del resolver — 2026-11-03

## Alcance y procedencia

- Proyecto: `PC-BRANCH-WAT-SPANISH`, rama `WAT+Español`.
- HEAD inicial verificado por la API de GitHub: `602016463621e63c3b2676a851e1a5268b960a35`.
- Módulo original: `tests/normative_final_resolver.wat`, blob Git `3797c9a62b42211908eed83880bb617f2ffdf076`.
- Módulo ampliado únicamente con cuatro pruebas y un helper de comprobación: blob Git `78298ab31277e8516cbddcf27e28f0cf4fc26df6`.
- Commit de cambio de pruebas: `4a9ffb55c881f22f5b7d3203d24d6225926dec52`.
- Ejecutor nativo local: `/usr/local/swift/usr/bin/wasmkit`, versión `0.1.6`.
- No se ejecutó `Stage 2`, ni se creó una implementación alternativa, ni se validó el calendario completo.

## Oráculo de borde (sin otras implementaciones)

Fixture ya existente: año `5000`, intervalo `(100,110]`, chuleta 7 en `[101,105]`, chuleta 9 en `[106,110]`; secuencia alterna de meses `1,2,1,2,1,2,1,2,1,2`; índices de nombres de mes `31,47`.

El resultado se verifica en cinco campos `(año, índice chuleta, día chuleta, índice mes, día mes)`. Se deduce directamente del fixture, no de un oráculo externo ni de otra rama.

| Exportación | Día objetivo | Salida esperada | Salida WasmKit | Exit |
| --- | ---: | --- | --- | ---: |
| `test_final_resolver_interleaved` (histórica) | 109 | `(5000,9,4,31,5)` | `i32(1)` | 0 |
| `test_resolver_first_day` | 101 | `(5000,7,1,31,1)` | `i32(1)` | 0 |
| `test_resolver_first_cutlet_last_day` | 105 | `(5000,7,5,31,3)` | `i32(1)` | 0 |
| `test_resolver_second_cutlet_first_day` | 106 | `(5000,9,1,47,3)` | `i32(1)` | 0 |
| `test_resolver_last_day` | 110 | `(5000,9,5,47,5)` | `i32(1)` | 0 |

Ejecución: cinco comandos independientes de la forma `wasmkit run tests/normative_final_resolver.wat EXPORT`, cada uno con salida literal `[WasmTypes.Value.i32(1)]`, `stderr` vacío y código `0`.

**Resultado: 5/5 PASS en QA nativa de este módulo únicamente.** El archivo WAT usado para la prueba se reconstruyó exactamente desde el blob Git original (SHA comprobado) y se extendió; el nuevo blob devuelto por GitHub coincidió exactamente con el archivo probado localmente.

## Limitación y siguiente paso

`DEVELOPMENT_STAGE.md` sigue indicando `LAST_COMPLETED_STAGE=1`. El paquete original `Stage02 / DISCOVERY 01` y su manifest siguen sin estar disponibles: no se aplica una sustitución. Al recuperarlo, verificar procedencia, SHA de cada fuente y diff contra el HEAD actual; después ejecutar los casos requeridos `M,2M,3M,M+1`, QA nativa y expected-red cuando corresponda. No declarar PASS de Stage 2 sin pruebas.

No se modificó `main`, no hubo merge ni publicación de artefactos ajenos al ramal de desarrollo.
