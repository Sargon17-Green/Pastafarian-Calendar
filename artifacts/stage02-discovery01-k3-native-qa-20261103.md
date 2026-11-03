# Etapa 2 / DISCOVERY 01 — transición exacta k=2 → k=3 (2026-11-03)

## Procedencia verificable
- **Proyecto**: `PC-BRANCH-WAT-SPANISH`; **rama**: `WAT+Español`.
- HEAD de código antes de escribir este informe: `2f360ff6a96d39b310679f2662932b1f71d3f439`.
- Cambio WAT: [commit e3be307](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/e3be307048fffabd84480440da2f0af534477bc1).
- Oráculo independiente versionado: [tests/stage02_discovery01_k3_oracle.py](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/2f360ff6a96d39b310679f2662932b1f71d3f439/tests/stage02_discovery01_k3_oracle.py) (commit `2f360ff6a96d39b310679f2662932b1f71d3f439`).
- Módulo ejecutado: `tests/normative_selector.wat`: Git blob SHA-1 `cf515f9515573d1d92aeaede3e6a20a9e3ee1c5e`, SHA-256 `cbbaa5914077dc69442b67776d787cbbb4d2ee94141fc55897bb2310f1d4c6e0`. Se comparó el Git blob del archivo local ejecutado con el blob devuelto por GitHub antes y después de subirlo. Fuente histórica de 12 exports: Git blob `c9d70ccb76d30f4c03781697b3c9734b8130a450`; se conservaron sin modificación los 12 exports.
- Runtime: WasmKit `0.1.6` en Linux. Cada export se ejecutó como proceso separado mediante `wasmkit run tests/normative_selector.wat EXPORT_NAME`, timeout por ejecución de 30 s.

## Contrato de la ampliación

`M=2^127-1`. Se contrastan `N=M²`, donde `k=2`, con `N=M²+1`, donde `k=3`. Para el segundo `N`, `S=M³`, `q=floor(S/N)=M-1`, `L=q*N=M³-M²+M-1`. El oráculo directo usa respuestas `a_j=1+((first-1+j*step) mod M)`, valor `x=1+Σ(a_j-1)M^j`, rango `r=((x-1) mod N)+1`, y comprueba `x<=L`.

| Caso nuevo | first / step | x matemático | rango esperado |
|---|---|---|---|
| `k3_from_one` | `1, +1` | `2M²+M+1` | `M-1` |
| `k3_backward_from_m` | `M, -1` | `(M-2)M²-M` | `N-2M+2` |
| `k3_forward_near_limit` | `M-3, +1` | `M³-M²-2M-3` | `N-3M-2` |
| `k3_backward_wrap_from_one` | `1, -1` | `M³-M²-M+1` | `N-2M+2` |

El caso cercano al límite verifica `L-x=3M+2>0`. Ninguno de los cuatro casos obliga a recorrer una cantidad astronómica de rechazos: todos los valores iniciales son aceptados. Esto delimita el alcance; **el rechazo real en la ruta k=3 aún requiere otra prueba acotada**.

## Evidencia Native — 16 procesos, 16/16 PASS

Las duraciones en segundos se midieron mediante `time.monotonic()` y redondearon a tres decimales. Los outputs se verificaron literalmente y se observaron `exit=0`, `stderr` vacío, sin timeout en todos los casos.

| # | Export | Tiempo (s) | Exit | stdout | stderr | Timeout | Resultado |
|---:|---|---:|---:|---|---|---|---|
| 1 | `test_short_n1` | 0.049 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 2 | `test_short_rejection_from_m_backward` | 0.027 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 3 | `test_wide_m_plus_1` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 4 | `test_wide_m_squared` | 0.029 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 5 | `test_discovery01_short_at_m` | 0.031 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 6 | `test_discovery01_wide_at_m_plus_one` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 7 | `test_discovery01_wide_at_two_m` | 0.042 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 8 | `test_discovery01_wide_at_three_m` | 0.027 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 9 | `test_discovery01_backward_two_m_limit` | 0.044 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 10 | `test_discovery01_backward_three_m_limit` | 0.031 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 11 | `test_discovery01_short_m_minus_one_reject_backward` | 0.026 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 12 | `test_discovery01_wide_m_plus_two_reject_wrap` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 13 | `test_discovery01_k3_from_one` | 0.035 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 14 | `test_discovery01_k3_backward_from_m` | 0.027 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 15 | `test_discovery01_k3_forward_near_limit` | 0.030 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 16 | `test_discovery01_k3_backward_wrap_from_one` | 0.039 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |

Cobertura del lote: **4 regresiones Stage01**, **8 sondas anteriores Stage02** y **4 nuevas sondas Stage02** = **16/16 Native PASS**. No hay trap, timeout, ni divergencia `i32(0)`.

## Oráculo independiente

Se ejecutó `python3 tests/stage02_discovery01_k3_oracle.py` en Python local, con enteros de precisión arbitraria, sin importar ni ejecutar WAT. Se comprobaron **5/5 escenarios**: el límite k=2 con `N=M²` y los cuatro escenarios nuevos con `N=M²+1`. Cada caso valida `k`, `x<=L`, rango dentro de `1..N` y valor esperado derivado de fórmulas. Resultado literal final: `ORACLE 5/5 PASS`.

## CI y conclusiones

La ejecución de `Canonical Names Lock` del commit del oráculo `2f360ff6a96d39b310679f2662932b1f71d3f439` fue [completed/success, run 41651826861](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41651826861). Este CI **no** comprueba los outputs del selector; Native y oráculo son evidencias locales distintas. La verificación del CI del nuevo commit de este informe debe consultarse aparte.

**Conclusión:** Las nuevas sondas no reproducen un fallo. No se declara `EXPECTED_RED`, ni `PASS` global de Stage02. No se reconstruye el ZIP Stage02 histórico, no se altera `main` ni se fusiona.

**NEXT recomendado:** Una prueba mínima de los operadores `wide_ring_step` y del umbral `L` con espacio k=3, inicializando `x=L+1` para comprobar rechazo de un paso, además de `x=S` y `step=+1` para comprobar el wrap a 1, sin realizar `O(M²)` rechazos ni inventar un defecto.
