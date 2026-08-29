# Historia de desarrollo del monstruo de espagueti

## Etapa 1 — Arranque

Se inició desde cero la línea WAT + español. No se usó ninguna implementación de otro lenguaje como fuente de código, valores esperados, casos fijos, tablas, registros o resúmenes criptográficos.

### Base de producción

Se creó únicamente infraestructura neutral: contexto por invocación, despachador base, validador base, frontera de error determinista y observabilidad no semántica.

### Oráculo

Se construyó un oráculo limpio de pruebas a partir del Apéndice A. La aritmética exacta, la salsa, las puertas, los años, las familias combinatorias, el entrelazado y el resolver final se mantienen fuera de la ruta de producción.

### Catálogo

Se preparó `SourceLanguageCatalog` versión 1 con 17 nombres de chuletas y 47 nombres de meses en español. El orden semántico depende exclusivamente de `canonicalIndex`. La congelación formal queda reservada para el cierre verde de la etapa 1.

### Crecimiento monstruoso

No se añadió ninguna capa monstruosa específica de un parche. La única estructura permitida en esta etapa es la base neutral que necesitarán etapas posteriores.

Todavía no existe ningún apartado de “qué se creía”, “qué se descubrió” o “qué se rodeó”, porque el primer defecto histórico solo puede aparecer en `DISCOVERY 01`.

### Auditoría final de la etapa 1

La reconciliación final del catálogo sustituyó las traducciones semánticas incorrectas de topónimos por `Lagash`, `Acad` y `Susa`, de acuerdo con las reglas del documento autoritativo. TSV y módulo WAT quedaron sincronizados.

La familia de entrelazado pasó por varias generaciones experimentales. El motor intermedio `normative_weaving_packed_unrank_telescoped.wat` conservaba la idea de sumas telescópicas, pero al completar su cierre sintáctico seguía fallando la validación WebAssembly por residuos de pila. Antes de retirarlo se comprobó que el conocimiento útil ya estaba incorporado en `wf_unrank3` de `normative_foundation_structure_integrated.wat`, donde la misma selección telescópica está expresada con flujo de control plano. El motor empaquetado anterior también fue retirado después de comprobar mecánicamente que no tenía funciones ni globales únicos respecto del camino integrado. Su exportación de desenmallado antiguo no completaba en un tiempo razonable en la batería final. La equivalencia semántica del sucesor `wf_unrank3` quedó reforzada con `test_general_weaving_exhaustive_3x2`, que enumera en WAT todo el caso 3×2 y compara cada rango válido con la salida exacta del desenmallado.

La integración de años amplios y estructura general añadió un oráculo `oracle/normative_calendar_wide.wat`. Se corrigieron únicamente fallos demostrados de integración: separación de espacios de memoria, uso del motor BigNat correcto en tres llamadas combinatorias, parametrización de longitudes para el entrelazado y el incremento de `dayInMonth`. Las optimizaciones de `year5000`, `nextYear` y `previousYear` memorizan puertas o candidatos ya calculados sin cambiar su orden normativo ni la selección por sello.

La antigua prueba `test_next_previous_inverse_foundation` imponía una propiedad no especificada: `previousYear(nextYear(y)) == y`. Los sellos 11 y 12 son independientes. El módulo i64 que contenía esa prueba terminó siendo redundante y excesivamente costoso frente al oráculo amplio. Antes de retirarlo se trasladó la propiedad realmente autoritativa a `normative_wide_gate_year.wat`: `test_wide_next_boundary_continuity` y `test_wide_previous_boundary_continuity` comprueban por separado que el año siguiente abre en el cierre actual, que el anterior cierra en la apertura actual y que un número de año superior a `i64` cambia en ±1. Las semánticas de pertenencia de las puertas de apertura y cierre quedan cubiertas además por `test_wide_find_opening_boundary` y `test_wide_find_closing_boundary`.

Las sondas `debug_*` y `probe_*` usadas para aislar tiempos, memoria, nombres y etapas de `structure` se retiraron del árbol de entrega después de convertir sus conclusiones necesarias en pruebas o en esta historia.

### Cierre verde de la etapa 1

La auditoría final retiró además los helpers internos sin referencias `$ws_build` y `$wf_unrank` y la exportación lenta `fixture_weaving_count_bitlen_stream`. Sus sucesores activos son `ws_build_fast` y `wf_unrank3`. La retirada se hizo únicamente después de verificar que la cardinalidad seguía siendo de `26403` bits y que la estructura integrada de Fundación seguía devolviendo `(5000, 10, 949, 3, 54)` con validador `1`.

La batería final completó el camino general `findTargetYear → year5000 → estructura → entrelazado → resolver` y las pruebas de precisión amplia. Después de traducir los últimos anglicismos de comentarios se revalidaron todos los módulos afectados. La etapa 1 termina sin código de `DISCOVERY 01`, sin llamadas de producción al oráculo y con el catálogo de idioma fuente congelado.
