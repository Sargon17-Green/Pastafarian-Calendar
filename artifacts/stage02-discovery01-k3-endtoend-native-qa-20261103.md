# Stage02 — DISCOVERY 01 — rechazo end-to-end acotado con k=3

**Fecha de ejecución:** 2026-11-03. **Proyecto:** `PC-BRANCH-WAT-SPANISH`. **Rama:** `WAT+Español`.

## Identidad del código y evidencia

- **Source WAT realmente ejecutado:** `tests/normative_selector.wat`, Git blob SHA-1 `f95036627224adab63c5b2358b73afada134319d`; SHA-256 `c58f33f48723c0bb0c7b6bd2ed72c8b7820167b91b0602134926e6108fd09f56`, **35 792 bytes**. GitHub confirmó exactamente el mismo blob tras [el commit de seis nuevas sondas](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/108cb45f84a8236576a1ee405bea506bb8006c37).
- **Oráculo de enteros independiente:** `tests/stage02_discovery01_k3_full_rejection_oracle.py`, Git blob `85a8173a898a75ec1f329caa8463a2fc2de0d2c4`, SHA-256 `133f08f08e00440dafe42699caf5ec27b3513f249fc278ccff41c2c973fac55f`, [commit](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/b1ebd42cecc975b9c91e49bcd6f0350b6f21b9d6).
- **Runner de regresión reproducible:** `tests/run_stage02_discovery01_native.py`, Git blob `6b4aea326c4a72ea5a658ab9187a163aea96b8ab`, SHA-256 `0c5852ed85edfae707759e81b9805c9a0ee0068a450c769b83bc88b11511ee26`, [commit](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/e84acd564cf6978c19288d9ca7e7508382488dfe). El runner no instala herramientas ni modifica repositorios.
- **Runtime Native:** WasmKit 0.1.6, Linux; un proceso nuevo por export, límite 30 s/proceso. Se hicieron dos pases completos sobre el mismo WAT: la ejecución directa inicial **26/26 PASS**, y la ejecución del runner versionado **26/26 PASS** (`python3 tests/run_stage02_discovery01_native.py --json-out native_second_run.json`; JSON local verificado con `executions=26, passed=26`).
- **Criterio por export:** `exit=0`, `stdout=[WasmTypes.Value.i32(1)]\n`, `stderr` vacío, sin timeout/trap. Las duraciones de la tabla son del primer pase, medidas con `time.monotonic()`; no son estimaciones.
- **Oráculo Python:** `python3 tests/stage02_discovery01_k3_full_rejection_oracle.py` → `ORACLE 6/6 PASS`. No importa ni ejecuta WAT.

## Derivación matemática independiente

Sea `M=2^127-1`, `S=M³`. Las respuestas sucesivas `a_j=1+((first-1+j*step) mod M)` dan `x=1+Σ(a_j-1)M^j`. Para `N>M²` y `N<=S` se usan tres dígitos, `k=3`. El límite es `L=floor(S/N)*N=qN`. Cada muestra `x>L` es rechazada y avanza por el anillo `1..S` en dirección `step`; la respuesta final es `1+((accepted-1) mod N)`.

Para `first=2, step=-1`, los dígitos son `[1,0,M-1]` y `x=S-M²+2`. Los valores `N=x-t`, para `t=1,2,3`, cumplen `q=1`, `L=N`, requieren exactamente `t` rechazos y devuelven rango `N`.

Para `first=1, step=-1`, la secuencia cruza el borde de respuestas, dígitos `[0,M-1,M-2]`: `x=S-M²-M+1`; con `N=x-1` también hay un rechazo real y rango `N`.

Como `2` y `3` dividen `M-1`, para `q∈{2,3}` puede elegirse `N=((M-1)/q)M²`: `floor(S/N)=q`, `x=qN+2`. Se rechaza dos veces, se acepta `qN` y el rango es `N`.

| Nueva sonda end-to-end | first | step | q | rechazos esperados | rango esperado |
|---|---:|---:|---:|---:|---|
| `full_backward_one_rejection` | 2 | −1 | 1 | 1 | N |
| `full_backward_two_rejections` | 2 | −1 | 1 | 2 | N |
| `full_backward_three_rejections` | 2 | −1 | 1 | 3 | N |
| `full_backward_digit_wrap_one_rejection` | 1 | −1 | 1 | 1 | N |
| `full_backward_q2_two_rejections` | 2 | −1 | 2 | 2 | N |
| `full_backward_q3_two_rejections` | 2 | −1 | 3 | 2 | N |

Las sondas nuevas llaman al `$choose` original y recorren `$choose_wide`, no llaman al helper de paso de manera aislada. La cantidad de rechazos se obtiene del oráculo independiente; la prueba WAT observa el resultado normativo `N`, no un contador interno de iteraciones.

## Primera ejecución Native — 26/26 PASS

| # | Export | Duración (s) | exit | stdout | stderr | timeout | Veredicto |
|---:|---|---:|---:|---|---|---|---|
| 1 | `test_short_n1` | 0.0484 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 2 | `test_short_rejection_from_m_backward` | 0.0239 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 3 | `test_wide_m_plus_1` | 0.0310 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 4 | `test_wide_m_squared` | 0.0384 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 5 | `test_discovery01_short_at_m` | 0.0244 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 6 | `test_discovery01_wide_at_m_plus_one` | 0.0280 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 7 | `test_discovery01_wide_at_two_m` | 0.0332 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 8 | `test_discovery01_wide_at_three_m` | 0.0250 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 9 | `test_discovery01_backward_two_m_limit` | 0.0266 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 10 | `test_discovery01_backward_three_m_limit` | 0.0246 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 11 | `test_discovery01_short_m_minus_one_reject_backward` | 0.0221 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 12 | `test_discovery01_wide_m_plus_two_reject_wrap` | 0.0243 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 13 | `test_discovery01_k3_from_one` | 0.0236 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 14 | `test_discovery01_k3_backward_from_m` | 0.0318 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 15 | `test_discovery01_k3_forward_near_limit` | 0.0274 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 16 | `test_discovery01_k3_backward_wrap_from_one` | 0.0247 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 17 | `test_discovery01_k3_reject_l_plus_one_backward` | 0.0295 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 18 | `test_discovery01_k3_reject_space_forward_wrap` | 0.0235 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 19 | `test_discovery01_k3_one_backward_wraps_to_rejected_space` | 0.0247 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 20 | `test_discovery01_k3_limit_bidirectional_boundary` | 0.0231 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 21 | `test_discovery01_k3_full_backward_one_rejection` | 0.0232 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 22 | `test_discovery01_k3_full_backward_two_rejections` | 0.0396 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 23 | `test_discovery01_k3_full_backward_three_rejections` | 0.0244 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 24 | `test_discovery01_k3_full_backward_digit_wrap_one_rejection` | 0.0305 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 25 | `test_discovery01_k3_full_backward_q2_two_rejections` | 0.0244 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |
| 26 | `test_discovery01_k3_full_backward_q3_two_rejections` | 0.0267 | 0 | `[WasmTypes.Value.i32(1)]\n` | vacío | no | PASS |

**Segunda ejecución automática:** 26/26 PASS con el runner reproducible. Ningún export mostró `i32(0)`, `trap`, `timeout` ni stderr. **Oráculo independiente:** 6/6 PASS.

## Alcance y próxima tarea

Las seis sondas prueban rechazo end-to-end de duración 1–3 en dirección negativa y tres valores del cociente, manteniendo 20/20 regresiones previas. **No prueban exhaustivamente** el espacio de `N`, ni el camino de rechazo hacia adelante (`step=+1`). No se declara `Stage02 PASS`, ni se reconstruye un ZIP histórico, ni se ha detectado un fallo real en los casos ensayados. CI `Canonical Names Lock` tiene alcance independiente y no constituye Native QA.

**NEXT:** analizar el rechazo `step=+1` cuando `first=M-2`, cuyo valor inicial es `x=S-M-2`. Verificar matemáticamente el número de pasos hasta el wrap para distintos `N` válidos y la factibilidad de la ruta productiva; no ejecutar una prueba potencialmente astronómica sin límite estricto de tiempo. Documentar cualquier riesgo de liveness solo si las condiciones del contrato realmente lo admiten.
