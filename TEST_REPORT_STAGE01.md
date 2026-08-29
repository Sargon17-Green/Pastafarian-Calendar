# Informe de pruebas de la etapa 1

## Resultado

**ETAPA 1: APROBADA.**

La batería final no contiene ningún fallo semántico conocido. El camino general de calendario, la aritmética de precisión arbitraria, las puertas y años amplios, la estructura anual, el entrelazado exacto y el resolver final han sido verificados únicamente con WAT del mismo linaje.

## Entorno

- ejecutor: `/usr/local/swift/usr/bin/wasmkit`
- versión: `WasmKit 0.1.6`
- lenguaje de implementación, oráculo y pruebas: WebAssembly Text Format (WAT)
- lenguaje humano canónico: español

Cada prueba se ejecutó mediante una orden WasmKit independiente. No se utilizó un bucle de shell como arnés de pruebas y no se utilizó otra lengua de programación para calcular oráculos, casos fijos o valores esperados.

## Batería semántica final

La batería semántica principal comprende los registros `01` a `45` de `artifacts/stage01-final-runs/`.

### Producción neutral y catálogo

- propiedad exclusiva de `MonsterContext` por invocación: PASS;
- despacho neutral: PASS;
- catálogo completo: PASS;
- reconciliación explícita de `Lagash`, `Acad` y `Susa`: PASS.

### Enteros y conteos amplios

- entero mayor que `i64`: PASS;
- cruce por cero con signo: PASS;
- conteos normativos de Fundación: PASS;
- conteos por encima de `i64`: PASS.

### Salsa y puertas

- `SAVE`: PASS;
- rangos de orden 1 y 720: PASS;
- coincidencia del caso Fundación con los casos fijos del mismo linaje WAT: PASS;
- pasos de puerta en índices unitarios: PASS;
- separación de puerta para un índice `2^90+5`: PASS;
- estabilidad del área de trabajo de salsa: PASS.

### Selector y longitudes de mes

- selector corto para `N=1`: PASS;
- rechazo corto en dirección inversa desde `M`: PASS;
- selector amplio para `M+1`: PASS;
- selector amplio para `M^2`: PASS;
- composición acotada pequeña: PASS;
- suma de las 45 longitudes del caso Fundación: `4922`.

### Entrelazado y estructura

- longitud en bits de la cardinalidad exacta del entrelazado: `26403`;
- comparación exhaustiva `3×2` de `wf_unrank3` contra enumeración lexicográfica independiente escrita en WAT: PASS;
- estructura integrada de Fundación: `(5000, 10, 949, 3, 54)` y validador `1`;
- resolver final intercalado: PASS.

La variante directa y lenta de conteo y el antiguo desenmallado sin referencias fueron retirados después de comprobar que no aportaban semántica ni estado únicos frente a `ws_build_fast` y `wf_unrank3`.

### Años y semántica de intervalos

Casos fijos del mismo linaje WAT:

- separación de puerta `+1`: `216`;
- separación de puerta `-1`: `949`;
- longitud del año 5000 en Fundación: `4922`;
- índice de apertura: `-5` — WasmKit lo muestra como `4294967291` al presentar el `i32` sin signo;
- índice de cierre: `6`.

Camino amplio:

- puertas en índices unitarios: PASS;
- separación de puerta para índice mayor que `i64`: PASS;
- pertenencia de intervalo de año con datos amplios: PASS;
- incremento/decremento de número de año mayor que `i64`: PASS;
- `nextYear` con número de año amplio: PASS;
- `previousYear` con número de año amplio: PASS;
- continuidad del límite de `nextYear`: PASS;
- continuidad del límite de `previousYear`: PASS;
- `year5000` para Fundación: PASS;
- `findTargetYear`: PASS;
- una puerta de apertura pertenece al año anterior: PASS;
- una puerta de cierre pertenece al año actual: PASS.

### Calendario general

- estructura y resolución con el año conocido de Fundación: PASS;
- conservación exacta del número de año `2^90+5000` a través de estructura y resolución: PASS;
- `calendarDate` de extremo a extremo para Fundación, pasando por `findTargetYear → year5000 → structure → weaving → resolver`: PASS.

El algoritmo autoritativo localiza puertas lejanas mediante una caminata secuencial desde el ancla. Por ello no se pretende ejecutar un caso de `calendarDate` a una distancia astronómica mayor que `i64`: eso exigiría una cantidad astronómica de pasos normativos. La precisión arbitraria no se sustituye por acceso aleatorio inventado; se verifica directamente en los enteros, la salsa, los índices de puerta, los intervalos, los números de año y la capa de estructura.

## Validación posterior a la auditoría lingüística

Después de la batería semántica se tradujeron únicamente comentarios humanos residuales (`callers`, `handles`, `little-endian`, `padding`). No cambió ninguna instrucción WAT.

Los registros `46` a `54` vuelven a validar, mediante órdenes WasmKit independientes, todos los módulos afectados por esas ediciones de comentarios. Todos completaron correctamente.

La auditoría final no encontró caracteres hebreos en WAT, Markdown o TSV. Los términos técnicos que permanecen en inglés son identificadores, nombres de archivo, nombres de exportación, instrucciones o formatos legibles por máquina, permitidos por la especificación.

## Limpieza final del entrelazado

Tras comprobar que `$ws_build` y `$wf_unrank` no tenían llamadas y que sus sucesores conservaban el conocimiento útil, se retiraron esos helpers muertos y la exportación lenta `fixture_weaving_count_bitlen_stream` del módulo integrado.

Los registros `55` y `56` verifican después de esa retirada:

- cardinalidad rápida: `26403` bits;
- estructura de Fundación: `(5000, 10, 949, 3, 54, 1)`.

## Estado de la entrega

- no existe llamada de producción al oráculo;
- no se ejecutó runtime de otro lenguaje;
- no se usaron artefactos, hashes, salidas ni pruebas de otra implementación;
- no se realizó ninguna operación Git/GitHub;
- `SourceLanguageCatalog` queda congelado al cerrar la etapa 1;
- la siguiente etapa es `DISCOVERY 01`, pero no forma parte de esta entrega.

Las órdenes y salidas exactas están en `artifacts/stage01-verification.log` y en los 56 registros individuales de `artifacts/stage01-final-runs/`.
