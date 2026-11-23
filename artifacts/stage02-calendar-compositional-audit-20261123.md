# Etapa 02 / WAT+Español — auditoría composicional independiente (23-11-2026)

## Identidad y material examinado

- Proyecto `PC-BRANCH-WAT-SPANISH`, rama autorizada `WAT+Español`.
- HEAD de la evidencia Native: `d05ce85128ab0eabcf4f1b1712f3c97da35886a7`.
- WAT normativo congelado: blob Git `70267bb5730678f81d6138a2224d6b8d9a193eb8` (SHA-256 del archivo: `0947ed11e8c4245ee367ebb659780bfb2e297c9dd950e018ed875f11382eda1f`).
- GitHub Actions: [run 45087126165](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087126165), [trace job 137408195912](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087126165/job/137408195912), [artifact 14779309057](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45087126165/artifacts/14779309057).
- ZIP descargado y verificado independientemente SHA-256 `2a3d163485b610a49290a087624b27514ef83c3543005e361ee39b2fc3b170ba`.
- El artifact declara expresamente `NATIVE_INSTRUMENTED_COPY`, `independent_five_field_oracle:false`, `overall_stage02_accepted:false`.
- El job Native devolvió `TRACE_NATIVE_PASS cases=3 event_counts=46,54,70`. Se observan los 11 sellos `1,10,11,12,20,21,22,30,31,32,33` y navegación real en ambos sentidos. El job `wat-stage02-wasmkit-native` figura **skipped**, no PASS.

## Entregable reproducible

Script QA **solo lectura**: [`tests/stage02_calendar_trace_compositional_oracle.py`](../tests/stage02_calendar_trace_compositional_oracle.py). Python 3, biblioteca estándar. Ejecutar después de descargar el artifact intacto:

```sh
python3 tests/stage02_calendar_trace_compositional_oracle.py --selftest /ruta/al/wat-calendar-runtime-trace.zip > audit-result.json
```

Exit code 0 significa que todos los contratos auditados pasan; exit code 1 identifica la primera discrepancia. **No hay dependencia del archivo WAT, de un fixture de otra rama ni de resultados esperados codificados para ninguno de los tres casos.** Los eventos del trace son entradas observadas, no expectativas.

### Contrato / oráculo

- **Entrada:** el ZIP del run exacto; `identity.txt`, `native-results.json`, `source.json`, `sha256.txt`, `instrumented.wasm`.
- **Identidad y SHA:** verificar proyecto, run, SHA, attempt, blob WAT, origen sin mutar, checksums de miembros presentes y WASM, y cobertura de sellos.
- **Selección:** recomputar con enteros Python de precisión arbitraria cada rango a partir de `first`, dirección y cardinalidad. Se comprueba también el número de dígitos `k`.
- **Puertas:** consumir todos los eventos de sello 1 en su secuencia real, obtener gaps `41+rank`, y reconstituir las puertas hasta las cotas del año. Los rangos de candidatos se cuentan y ordenan por longitud y apertura. Los sellos 10/11/12 seleccionan el año; se valida la igualdad de puertas finales.
- **Chuletas:** enumeración matemática de composiciones positivas por estrellas-y-barras, imponiendo la puerta interior obligatoria cuando exista; inversión lexicográfica por cardinalidades. Nombres distintos mediante sistema factorial. Los sellos 20/21/22 determinan independientemente la chuleta y el número de día en ella.
- **Meses (comprobaciones parciales):** composición acotada `[4,123]`, inversión lexicográfica por inclusión-exclusión y recuento de tejidos mediante convolución combinatoria de enteros exactos. Se verifican las cardinalidades y rangos de los sellos 30/31/32/33 y la permutación de nombres. La inferencia del ID del mes a partir del nombre **no** es un oráculo independiente del tejido mensual. También se exige que el día en el mes observado no exceda la longitud calculada.
- **Límites:** puertas `42..963`; año `252..5778` días y al menos seis huecos de puerta; fecha objetivo en `(apertura,cierre]`; entre 3 y 47 meses, de longitud 4 a 123; cardinalidades anchas con `k<=253`; no se trunca el entero a i64.
- **Semántica de error:** error en identidad, SHA, orden de llamadas, aritmética, cardinalidad, año o campos recalculados => código 1. Timeout o ejecución pendiente nunca equivale a PASS. Script solo valida el artifact proporcionado, no ejecuta Native.

## Resultado auditado localmente sobre el artifact exacto

| Caso | Año | Chuleta | Día chuleta | Mes / día observados (NO independientes) | Gaps | Meses | Eventos |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| `foundation` | 5000 | 10 | 949 | 3 / 54 | 11 | 45 | 46 |
| `future_navigation_probe` | 5001 | 3 | 84 | 26 / 78 | 8 | 42 | 54 |
| `past_navigation_probe` | 4998 | 1 | 94 | 23 / 96 | 7 | 37 | 70 |

`STATIC_SELFTEST_PASS` y análisis completo: código de salida 0. Se comprobaron cuatro mutaciones negativas aisladas, todas rechazadas con código 1: año de salida incorrecto, sello de puerta reemplazado, cardinalidad de tejido alterada e identidad de proyecto ajena. Todas las mutaciones fueron en copias temporales de ZIP; no se cambió la evidencia original.

## Puertas de aceptación: distinción obligatoria

- **Código:** nuevo script QA de auditoría independiente; **no** cambia la implementación WAT ni los algoritmos normativos.
- **Static / local:** comprobadas aritmética, estructura, tres ternas de fecha y pruebas negativas; **PASS parcial** en el alcance indicado.
- **CI histórico de origen:** jobs semantic/trace/verify `completed/success` en el SHA `d05...`; no se repitieron.
- **Native histórico:** tres casos instrumentados ejecutados con Node WebAssembly/WABT 1.0.34; **PASS de trace**, no WasmKit y no del Stage02 completo.
- **Diferencial:** esta auditoría rederiva tres campos y cardinalidades exactas a partir de la traza observada; no constituye una comparación Native nueva ni un oráculo externo de cinco campos.
- **Stage02 completo:** **NO ACEPTADO**. No se verificaron el ZIP y manifest originales, y faltan los oráculos independientes para `month` y `day_in_month` (inversión exacta del tejido mensual).

**NEXT:** construir oráculo independiente de la secuencia de tejido mensual condicionada por las longitudes y el rango del sello 32, derivar ID de mes y ordinal de día sin apoyarse en el resultado WAT; contrastar en los tres casos y ampliar límites sin repetir los run CI ya aceptados. No hacer merge/main/publicación. El script nuevo puede incorporarse en CI como puerta separada cuando exista artifact pertinente; la auditoría local no es un run CI nuevo.