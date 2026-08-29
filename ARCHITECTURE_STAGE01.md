# Arquitectura de la etapa 1

## Propósito

La etapa 1 establece una base neutral de producción y un oráculo normativo limpio. La arquitectura histórica de espagueti todavía no se introduce: debe crecer únicamente cuando un descubrimiento y un parche posteriores lo justifiquen.

## Contexto de producción

`src/monster_bootstrap.wat` asigna un bloque `MonsterContext` independiente para cada invocación. El bloque contiene referencias opacas a `calculationDay` y `targetDay`, fase, subfase, modo, estado, campos neutrales de recuperación y manejo, código de error, contador de fallos de validación, token de confirmación y banderas de observabilidad.

En la etapa 1:

- dos invocaciones reciben bloques distintos;
- un contexto no comparte estado semántico con otro;
- los manejadores de día son opacos para el arranque y no se interpretan como valores de calendario en producción;
- no existe una operación de liberación o reutilización de contexto, porque el documento autoritativo no la exige en esta etapa;
- la asignación monotónica evita que un bloque vivo pueda ser reutilizado por otra invocación.

## Despacho, validación y errores

El despachador neutral únicamente lleva el contexto por las fases de validación, preparación y finalización. No calcula todavía una fecha de producción.

El validador comprueba la integridad estructural mínima y el modo de arranque. Un fallo produce estado de error y código determinista; no existe una ruta alternativa que fabrique una respuesta parcial.

El token de confirmación de la etapa 1 solo registra la finalización del ciclo neutral. No representa todavía un resultado semántico del calendario.

## Observabilidad

Las métricas globales cuentan invocaciones y validaciones. Son estrictamente no semánticas: ninguna decisión de despacho o validación depende de sus valores.

## Enteros exactos

`src/wide_integer.wat` representa enteros con signo mediante miembros de 30 bits. Los módulos normativos amplios reutilizan el mismo principio para días, índices, números de año y conteos que exceden `i64`.

La propiedad del área de trabajo se mantiene dentro de cada ejecución del módulo de prueba. Las funciones que usan una marca del área restauran esa marca antes de devolver cuando la vida del temporal termina.

## Separación entre producción y oráculo

El oráculo de `oracle/` y `tests/` no puede ser llamado desde `src/monster_bootstrap.wat`. Su complejidad combinatoria no convierte el esqueleto neutral en una implementación de producción anticipada.

Los módulos se separan por responsabilidad:

- `normative_sauce_wide.wat`: salsa amplia y consultas normativas;
- `normative_wide_counts.wat`: conteos y aritmética amplia;
- `normative_wide_gate_year.wat`: puertas, años y búsqueda de año con enteros amplios;
- `normative_calendar_wide.wat`: integración de año, estructura, entrelazado y resolución final;
- `tests/`: comprobaciones acotadas, casos fijos del mismo linaje WAT y validaciones de componentes.

## Puertas y años

Los días, índices de puerta y números de año se almacenan como enteros amplios. El intervalo de pertenencia es exactamente `(open, close]`.

`year5000`, `nextYear` y `previousYear` memorizan dentro de una invocación puertas o candidatos que ya fueron calculados. Esta memorización no modifica el orden normativo ni el sello de selección; evita únicamente repetir cálculos equivalentes.

La caminata hacia una puerta lejana sigue el algoritmo secuencial exigido por la especificación. No existe acceso aleatorio inventado para saltar una cantidad arbitraria de puertas.

## Estructura anual y entrelazado

La estructura general se deriva de una única salsa formada con `(calculationDay, firstDayOfYear)`. Los índices de nombres se mantienen canónicos hasta la presentación.

El entrelazado utiliza conteos exactos de precisión arbitraria. Para el caso completo se usa una tabla empaquetada y `wf_unrank3`, cuya selección telescópica mantiene el orden lexicográfico con flujo de control válido para WebAssembly.

Las optimizaciones aceptadas cumplen dos condiciones:

1. preservan exactamente la cardinalidad y el orden de la familia normativa;
2. se verifican mediante casos pequeños o mediante el caso integrado real del mismo linaje WAT.

## Resultado

La resolución final produce exactamente cinco campos canónicos:

1. número de año;
2. índice canónico de la chuleta;
3. día dentro de la chuleta;
4. índice canónico del mes;
5. número de aparición de ese mes hasta el día objetivo, incluido.

El número de año se conserva como entero amplio hasta el registro de resultado; no se reduce a `i64`.

## Lengua

Toda prosa humana escrita para esta implementación está en español. Los identificadores, nombres de exportación, nombres de archivo, instrucciones WAT y demás elementos legibles por máquina conservan su forma técnica.
