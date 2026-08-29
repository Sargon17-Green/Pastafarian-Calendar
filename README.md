# WAT + español — etapa 1

Esta línea es una implementación independiente iniciada desde cero para WebAssembly Text Format (WAT), con español como única lengua humana canónica. No se ha usado código, pruebas, casos fijos, salidas, resúmenes criptográficos ni artefactos de otra implementación.

## Alcance

La etapa 1 implementa únicamente el arranque exigido por el documento autoritativo:

- `SourceLanguageCatalog` completo para 17 chuletas y 47 meses;
- esqueleto neutral de producción;
- enteros con signo de precisión arbitraria;
- oráculo normativo de prueba escrito en WAT;
- salsa normativa, selectores, puertas, años, combinatoria de estructura, entrelazado completo y resolución final;
- pruebas de propiedad del contexto, precisión amplia y semántica de intervalos.

No contiene rutas heredadas, compatibilidad histórica ni parches correspondientes a `DISCOVERY 01` o a etapas posteriores.

## Árbol de entrega

```text
catalog/source_language_catalog.tsv
src/monster_bootstrap.wat
src/source_language_catalog.wat
src/wide_integer.wat
oracle/normative_sauce_wide.wat
oracle/normative_wide_counts.wat
oracle/normative_wide_gate_year.wat
oracle/normative_calendar_wide.wat
tests/normative_sauce.wat
tests/normative_selector.wat
tests/normative_gate_year.wat
tests/normative_month_lengths.wat
tests/normative_weaving_fast_count.wat
tests/normative_foundation_structure_integrated.wat
tests/normative_final_resolver.wat
ARCHITECTURE_STAGE01.md
DEVELOPMENT_STAGE.md
SPAGHETTI_DEVELOPMENT_HISTORY.md
TEST_REPORT_STAGE01.md
artifacts/stage01-verification.log
artifacts/stage01-final-runs/*.log
```

La lista anterior describe únicamente archivos que existen en la entrega final. Los nombres antiguos mencionados en documentos de continuación anteriores no se recrearon artificialmente.

## SourceLanguageCatalog

El catálogo conserva `canonicalIndex` como única clave semántica. Las cadenas españolas se resuelven únicamente como presentación y no intervienen en ordenación normativa, selección, rango, reconstrucción por rango ni claves semánticas.

Reglas aplicadas:

- los nombres con significado léxico se traducen por significado;
- los topónimos usan una forma española asentada cuando existe o una transcripción latina estable;
- los nombres inventados sin significado léxico conservan una transliteración determinista;
- las fracciones se traducen como expresiones completas;
- ningún orden alfabético, Unicode o de configuración regional sustituye a `canonicalIndex`.

La reconciliación final de los topónimos fija `Lagash`, `Acad` y `Susa` en los índices canónicos correspondientes.

## Producción neutral

`src/monster_bootstrap.wat` contiene solo infraestructura neutral:

- contexto separado por invocación;
- asignación monotónica de bloques de contexto independientes;
- validador estructural base;
- despachador base;
- frontera de error mediante códigos deterministas;
- métricas no semánticas;
- token de confirmación neutral.

La etapa 1 no implementa liberación o reutilización de contextos porque el documento autoritativo no la exige en este punto. No existe estado semántico global mutable y las métricas no participan en decisiones semánticas.

## Precisión arbitraria

`src/wide_integer.wat` y los módulos de `oracle/` usan enteros exactos en base `2^30`. Las pruebas cubren valores situados por encima de `i64`, aritmética con signo y cruce por cero.

La salsa amplia acepta días por encima de `i64`. Los registros de año conservan números de año amplios; `nextYear`, `previousYear`, intervalos y la capa de estructura no reducen esos números a `i64`.

La búsqueda de una puerta situada a una distancia astronómica del ancla continúa siendo, por definición normativa, una caminata secuencial de puertas. No se introduce una fórmula de acceso aleatorio que el documento autoritativo no especifica. Esta propiedad de coste no modifica la precisión de la representación.

## Oráculo normativo

El oráculo se mantiene separado de producción y se construyó en WAT a partir del documento autoritativo. Cubre:

- conteos normativos de trabajo;
- salsa, piedras, gotas, vasijas, agitaciones y consultas;
- selector corto y selector amplio;
- puertas de índices positivos y negativos;
- `year5000`, `nextYear`, `previousYear` y `findTargetYear`;
- intervalo autoritativo `(open, close]`;
- composiciones acotadas y partición en chuletas;
- selección de nombres canónicos distintos;
- número y longitudes de meses;
- conteo exacto y reconstrucción por rango del entrelazado completo;
- estructura anual general;
- resolución final de exactamente cinco campos.

El caso integrado de Fundación devuelve:

```text
(5000, 10, 949, 3, 54)
```

Con el catálogo español, los índices de nombre correspondientes son `Escorpión` y `Codo`.

## Entrelazado

Se conservaron únicamente las variantes que aportan cobertura o conocimiento vigente. La variante experimental telescópica que no validaba en WebAssembly y el motor empaquetado anterior fueron retirados después de comprobar que no contenían funciones ni estado únicos frente al camino integrado. La idea útil de selección telescópica está incorporada en `wf_unrank3`, que la expresa con flujo de control plano. `test_general_weaving_exhaustive_3x2` contrasta exhaustivamente ese desenmallado con una enumeración lexicográfica independiente realizada íntegramente en WAT.

La comprobación independiente de cardinalidad se conserva en `tests/normative_weaving_fast_count.wat`; el desenmallado normativo activo pertenece al camino integrado y se verifica además mediante el caso exhaustivo pequeño en WAT.

## Verificación

El entorno usado es:

```text
WasmKit 0.1.6
/usr/local/swift/usr/bin/wasmkit
```

Cada prueba del conjunto final se ejecuta mediante una orden WasmKit independiente. No se usa un bucle de shell como arnés y no se usa otra lengua de programación para calcular oráculos, casos fijos o valores esperados.

Las órdenes, salidas y observaciones están en `TEST_REPORT_STAGE01.md` y `artifacts/stage01-verification.log`.

## Etapa siguiente

La etapa siguiente es `DISCOVERY 01`. No forma parte de esta entrega y no debe iniciarse hasta que la etapa 1 haya sido subida como su propio estado verde.
