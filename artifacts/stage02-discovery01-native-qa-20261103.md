# Stage02 — DISCOVERY 01 — Native QA de selector (2026-11-03)

**Identidad y bloqueo de fuente:** `PC-BRANCH-WAT-SPANISH`; rama `WAT+Español`. Módulo `tests/normative_selector.wat`, **blob SHA Git** `c9d70ccb76d30f4c03781697b3c9734b8130a450`, **SHA-256** `c10860f3785bb9551b8ecca1d58f4a292c76f899fcbfe15e89bc7c4ab1c65fa0`. Código de pruebas ampliadas guardado en commit `b5dfdce98c56df1b50217601d267d42f7f5c54fd`. Se verificó el blob del archivo en la ejecución local y su identidad después del commit en GitHub; las 12 ejecuciones corresponden exactamente al mismo contenido.

**Entorno:** WasmKit `0.1.6` en entorno Linux de ejecución de ChatGPT. Comando por export: `wasmkit run tests/normative_selector.wat EXPORT_NAME`; tiempo máximo 30 s por export. Criterio: `exit=0`, `stdout=[WasmTypes.Value.i32(1)]\n`, `stderr` vacío y sin timeout. Cada export se inició en un proceso nuevo. No hay reutilización de resultados históricos.

## Evidencia Native — 12 ejecuciones de 12 satisfactorias

| # | Export | Segundos | Exit | Stdout | Stderr | Timeout | Estado |
|---:|---|---:|---:|---|---|---|---|
| 1 | `test_short_n1` | 0.035 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 2 | `test_short_rejection_from_m_backward` | 0.025 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 3 | `test_wide_m_plus_1` | 0.030 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 4 | `test_wide_m_squared` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 5 | `test_discovery01_short_at_m` | 0.036 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 6 | `test_discovery01_wide_at_m_plus_one` | 0.037 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 7 | `test_discovery01_wide_at_two_m` | 0.055 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 8 | `test_discovery01_wide_at_three_m` | 0.029 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 9 | `test_discovery01_backward_two_m_limit` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 10 | `test_discovery01_backward_three_m_limit` | 0.032 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 11 | `test_discovery01_short_m_minus_one_reject_backward` | 0.028 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |
| 12 | `test_discovery01_wide_m_plus_two_reject_wrap` | 0.023 | 0 | `[WasmTypes.Value.i32(1)]` | vacío | no | PASS |

Contabilidad: **4/4 regresiones Stage01**, **6/6 sondas iniciales Stage02**, **2/2 sondas nuevas de ampliación**. **12/12 Native PASS, 0 traps, 0 timeouts, 0 stderr no vacío**. Las duraciones se midieron con `time.monotonic()` alrededor de cada proceso. No son mediciones de rendimiento del algoritmo.

## Oráculo matemático independiente para las dos sondas nuevas

Sea `M=2^127-1`. Para la ruta corta con `N=M-1`, `first=M`, `step=-1`: `q=floor(M/N)=1` y `L=M-1`; se rechaza `M`, el siguiente valor es `M-1`, se acepta y el rango esperado es exactamente `M-1`.

Para la ruta amplia `N=M+2`, `first=M-1`, `step=+1`: `k=2`, espacio `S=M^2`, valor inicial `x=M^2-1`; como `M^2 mod (M+2)=4`, `L=M^2-4`. Se rechaza `x=M^2-1`, se rechaza `M^2`, el siguiente valor del anillo es `1`, que se acepta; rango esperado `1`. Todos los valores y expectativas se derivan de la definición, no de la salida de WAT.

## CI y alcance

GitHub Actions, run `41538125745`, sobre commit anterior `a264a3c` terminó `completed/success` pero **solo comprobó Canonical Names Lock**. El estado del CI del commit de las sondas nuevas debe consultarse por separado. No se contabiliza como Native ni como PASS de Stage02.

**Resultado de la investigación:** Las 12 sondas previstas/extendidas están GREEN. La hipótesis de defecto **no quedó confirmada**. No hay evidencia de EXPECTED_RED, no se abre PATCH correctivo, no se reconstruye el ZIP histórico, no se fusiona a `main` y **no se declara terminada la etapa**.

**NEXT:** Ampliar investigación de la ruta amplia al punto de cambio `k=2→3` para `N=M^2+1`, con expectativas de rango derivadas en forma independiente y tiempo acotado, y verificar CI del nuevo HEAD mediante logs de jobs completados.
