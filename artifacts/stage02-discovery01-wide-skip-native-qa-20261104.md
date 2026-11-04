# Stage02 DISCOVERY01 — rechazo de tiempo acotado: PATCH y QA Native (2026-11-04)

**Proyecto:** `PC-BRANCH-WAT-SPANISH` · **Rama:** `WAT+Español` · **sin merge/main**.

## Fuente y trazabilidad

- HEAD inicial comprobado: `a99e48252590d9a4cbd7bfb7f068e81c69eb02df`.
- WAT antes del parche: Git blob `f95036627224adab63c5b2358b73afada134319d`.
- Parche + dos nuevos exports: commit `4df493f59414dd01fd7f2dfb6be7e12f5c475a17`.
- Actualización del runner de 26 a 28 exports: commit `8f5c14332f811fffe96f6701b9260c7b5e91dc5d`.
- WAT ensayado: **Git blob `2b67a790162f9e0e08644d501a90344e2d3b1c0d`**, comprobado byte-for-byte con los datos del repositorio. SHA-256 `2a8ff56939bd25986a8ef7c062d9c99dc18ea11f5a860b1e22d1df956e42cc42`.
- Entorno Native: `wasmkit --version` = `0.1.6`, 28 invocaciones de proceso independientes, timeout de 30 s por export.

## Cambio en el algoritmo

Sólo se sustituyó en `$choose_wide` el bucle `$rej` por una selección exacta de primer elemento admisible: si `WIDE <= LIMIT`, no hay cambio; si `WIDE > LIMIT`, `step=+1` salta a `ONE`, `step=-1` salta a `LIMIT`. `$wide_ring_step` se conservó porque sus pruebas auxiliares lo utilizan. El argumento de equivalencia y sus precondiciones se documentaron en `artifacts/stage02-discovery01-forward-liveness-analysis-20261103.md`. No se afirma un fallo histórico reproducido ni `EXPECTED_RED`.

## Native QA efectuado

**28/28 PASS** con `exit=0`, `stdout=[WasmTypes.Value.i32(1)]`, `stderr` vacío, `timeout=false` en cada prueba. Incluye 26 exports preexistentes y estas dos nuevas pruebas end-to-end:

1. `test_discovery01_k3_forward_astronomical_skip`: `M=2^127-1`, `N=M²+1`, `first=M-2`, `step=+1`; rango esperado `1`.
2. `test_discovery01_k3_backward_near_limit_no_skip`: mismos `N` y `first`, `step=-1`; rango esperado `N-4M+2` (sin rechazo).

Se verificó que los 28 nombres exportados son únicos, y el módulo tiene paréntesis equilibrados. Duración agregada de las 28 ejecuciones Native: **1.567 s**, tiempo máximo por export **0.216 s**; 0 traps, 0 timeouts, 0 errores de salida. Las cifras se derivan de los resultados crudos del runner local de este turno, no de una corrida de CI de GitHub.

## Oráculo independiente (nueva ejecución)

Modelo de Python con enteros de precisión arbitraria, sin leer el código WAT ni usar su salida: **35 088/35 088** casos exhaustivos de ruta amplia para `M∈{3,5,7,11}`, cada `N∈(M,M³]`, `first∈[1,M]` y `step∈{-1,+1}`. **7 262** casos incluyeron rechazo; máximo observado **546** pasos en el modelo pequeño. Las identidades simbólicas de producción comprueban `M+3=170141183460469231731687303715884105730` rechazos en la ruta `+1` anterior al parche, y rango `1` tras el salto; para `-1`, rango `N-4M+2`.

## Límites de la conclusión

- **PATCH + QA Native + oráculo: verificados sobre el WAT fijado**.
- No se realizó ejecución astronómica de la implementación antigua, por seguridad.
- El contrato completo Stage02/DISCOVERY01 no se declara finalizado y no existe `Stage02 PASS` global.
- CI de GitHub para el nuevo HEAD: distinguir de la presente QA Native y verificar sólo si existe evidencia completed/job log del mismo SHA; no inferir que Canonical Names Lock sea una validación semántica.

**Siguiente acción:** completar un conjunto differential independiente para el selector WAT con sondas de rechazo en ambos signos, distintos `q` y fronteras (`LIMIT`, `LIMIT+1`, `SPACE`), con límites estrictos; conservar este patch sin merge.