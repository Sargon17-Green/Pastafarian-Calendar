# Stage02 DISCOVERY01 — inventario de procedencia y contrato WasmKit (2026-11-21)

**Proyecto:** `PC-BRANCH-WAT-SPANISH` · **rama autorizada:** `WAT+Español` · **estado:** investigación abierta, sin aceptación global de Stage02.

## Identidad congelada y evidencia ya aceptada

| Elemento | Identidad comprobada | Alcance |
| --- | --- | --- |
| Commit de código original para esta auditoría | `871f9b70216c16c57abcd552ec6fb0ed1010e305` | `compare(base, WAT+Español)` devolvió `identical` (ahead=0, behind=0) al comenzar |
| Archivo WAT | `tests/normative_selector.wat`; blob Git `e23f013ab96b498b0ac365dbb1b25273c845e790`; SHA-256 de bytes `18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980` | No modificar |
| Pruebas exportadas | 111 funciones únicas `test_*` con firma `() -> i32`; la memoria exportada no es función de prueba | Inventario estático sobre WAT, no es ejecución |
| Node WebAssembly / oráculo BigInt | Run `44890181699`, jobs `136804091107` (names lock) y `136804091294` (semántica), `completed/success` | 111/111 Native Node y 83 comprobaciones numéricas independientes; **solo** este gate ya se aceptó |
| Artefactos del run Node | Ninguno según listado del run | Logs de los jobs preservan salida literal |
| ZIP original Stage02 + manifiesto original | Sin archivo, hash ni identificación de entrega verificable en el contrato `STAGE02_DISCOVERY01_CONTRACT.md` | **Procedencia NO VERIFICADA**; no reconstruir ni atribuir equivalencia |

## Viabilidad técnica del gate WasmKit

La documentación oficial del proyecto `swiftwasm/WasmKit` anuncia ejecución de módulos WebAssembly con CLI, soporte de Linux y compatibilidad con toolchains Swift de `swift.org`. En 2026 la versión más reciente exige al menos Swift 6.3. La existencia de esta capacidad **no** constituye una ejecución válida del WAT local.

Referencia: https://github.com/swiftwasm/WasmKit

La propuesta es una comprobación **distinta** en GitHub Actions, sin lanzar de nuevo la matriz de Node ni alterar el módulo WAT:

1. Fijar el `checkout` al commit anterior, y comprobar que `git rev-parse HEAD` y SHA-256 del WAT coincidan exactamente.
2. Registrar imagen del runner, versión de Swift, ruta/hash del binario WasmKit, versión WABT y SHA-256 del `.wasm` compilado.
3. Compilar `.wat` con WABT, validar el módulo y enumerar **111 exportaciones únicas** de prueba mediante una expresión regular sobre el WAT inmóvil. Una cifra distinta de 111 es un fallo de inventario, no un PASS.
4. En el runtime **WasmKit** (no Node/Wasmtime), ejecutar primero las seis funciones originales de `DISCOVERY01` y después las 105 regresiones restantes. Límite por invocación: 30 segundos.
5. Criterio binario estricto: exit code `0` y resultado explícito `[I32(1)]` (o notación `[i32(1)]` si la versión la usa). `0`, `trap`, falta de resultado, salida inesperada, timeout (124), error de instalación o compilación deben constar por separado y **no** son `EXPECTED_RED` automático.
6. Emitir `manifest.tsv`, `cases.tsv`, salida completa individual y `summary.txt` como artifact de Actions **incluso cuando haya fallo**. Registrar SHA y enlace de la ejecución real para la revisión de aceptación.

**Oráculo:** las seis expectativas matemáticas y sus condiciones de frontera están fijadas de manera independiente en `STAGE02_DISCOVERY01_CONTRACT.md` (casos `N=M`, `M+1`, `2M`, `3M`, y dos inversos de igualdad). Las otras funciones comprueban condiciones semánticas declaradas en el WAT y han pasado anteriormente con un motor distinto; su ejecución por WasmKit aporta independencia de motor, no un nuevo oráculo numérico independiente para las 111.

## Puertas de aceptación

- **WasmKit Native:** pendiente de logs, salida literal y artifact del run nuevo. No se autoriza PASS por la mera creación del workflow.
- **Diferencial por motores:** solo puede declararse para pruebas que realmente ejecuten ambos motores a igual fuente; el PASS anterior de Node permanece histórico.
- **Proveniencia histórica:** continúa `UNVERIFIED` hasta identificar el ZIP *original* y manifiesto verificables (hashes y cadena de custodia). Ningún ZIP sintetizado cuenta como sustituto.
- **Stage02 global:** `NOT ACCEPTED`, aunque la futura suite WasmKit pase, mientras persista el hueco de procedencia o falten otros gates contractuales.

**Reglas de cambio:** QA y archivos de evidencia solo en la rama `WAT+Español`; sin merge, main ni release. El SHA de código congelado no debe confundirse con un HEAD posterior que contenga exclusivamente QA.
