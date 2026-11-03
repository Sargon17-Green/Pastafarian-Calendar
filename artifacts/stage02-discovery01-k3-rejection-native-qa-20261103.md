# Stage02 / DISCOVERY 01 — Límite de rechazo y wrap de anillo k=3

**Fecha:** 2026-11-03  
**PROJECT_ID:** `PC-BRANCH-WAT-SPANISH`  
**Rama:** `WAT+Español`. No se modificó `main` ni se ejecutó merge/publicación.

## Identidad del código y reproducibilidad

- Código WAT: `tests/normative_selector.wat`; Git blob SHA-1 `c14c5dee9df264b24e24ef7eedac4cc8ea86e589`, SHA-256 `1df2343fb6090d139c20bb0e2a8b0775d9821a40aa6a3c0ce6d6289328d72a4f`, 32501 bytes.
- [Commit de 4 sondas WAT](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/28aa0454fe20946fb0559f43a66e6ec80f5a28c1). El blob devuelto por GitHub coincide exactamente con el blob del fichero ejecutado.
- [Oráculo matemático independiente](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/1ed28cb638cb3ea4758fd4b4a7a268fd8f24bbd0/tests/stage02_discovery01_k3_rejection_oracle.py), commit `1ed28cb638cb3ea4758fd4b4a7a268fd8f24bbd0`.
- Entorno: Linux, `WasmKit 0.1.6`. Cada export se invocó como un proceso nuevo: `wasmkit run tests/normative_selector.wat EXPORT_NAME`. Timeout por proceso: 30 s.
- Verificación exhaustiva de este lote: `exit=0`, `stdout="[WasmTypes.Value.i32(1)]\\n"`, `stderr=""`, `timeout=false`. Las duraciones se midieron con `time.monotonic()`.
- Oráculo: `python3 tests/stage02_discovery01_k3_rejection_oracle.py`. Resultado literal final `ORACLE 6/6 PASS`. No importa WAT ni utiliza el runtime WASM.

## Derivación aritmética independiente

Sean `M=2^127−1`, `N=M²+1`, `S=M³`. Entonces:
- `q=floor(S/N)=M−1`;
- `L=q*N=M³−M²+M−1`;
- `S−L=M²−M+1`, así que `1 <= L < S`;
- `rank(x)=1+((x−1) mod N)` para cualquier `1<=x<=L`.

Las pruebas unitarias ejecutan helpers reales del WAT: `divmod_q_lt_m`, `mul`, `cmp`, `wide_ring_step`, `sub_small` y `add_small`.

| Prueba | Valor inicial | Paso | Evidencia esperada |
|---|---|---|---|
| `k3_reject_l_plus_one_backward` | `L+1` | `−1` | inicialmente `>L`; luego `L` aceptado y `rank(L)=N`; además `q=M−1` |
| `k3_reject_space_forward_wrap` | `S` | `+1` | `S>L`, wrap a `1<=L` |
| `k3_one_backward_wraps_to_rejected_space` | `1` | `−1` | wrap a `S>L` |
| `k3_limit_bidirectional_boundary` | `L` | `+1,−1,−1` | `L` aceptado, `L+1` rechazado, vuelta a `L` y finalmente `L−1` |

**Límite del ensayo:** las cuatro sondas configuran directamente `$WIDE` y `$SPACE` para alcanzar el umbral en tiempo constante. No fuerzan al selector `choose_wide` a generar `L+1` a partir de una secuencia de tres dígitos. En particular, no prueban una ejecución end-to-end que requiera `O(M²)` pasos de rechazo. Tampoco se debe reclamar que un resultado verde pruebe todos los dominios.

## Evidencia Native — 20/20 PASS

Incluye 4 regresiones originales + 12 sondas anteriores + 4 sondas nuevas.

| # | Export | Segundos | exit | stdout | stderr | timeout | Resultado |
|---:|---|---:|---:|---|---|---|---|
| 1 | `test_short_n1` | .0267 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 2 | `test_short_rejection_from_m_backward` | .0283 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 3 | `test_wide_m_plus_1` | .0273 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 4 | `test_wide_m_squared` | .0305 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 5 | `test_discovery01_short_at_m` | .0223 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 6 | `test_discovery01_wide_at_m_plus_one` | .0302 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 7 | `test_discovery01_wide_at_two_m` | .0260 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 8 | `test_discovery01_wide_at_three_m` | .0245 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 9 | `test_discovery01_backward_two_m_limit` | .0272 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 10 | `test_discovery01_backward_three_m_limit` | .0260 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 11 | `test_discovery01_short_m_minus_one_reject_backward` | .0243 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 12 | `test_discovery01_wide_m_plus_two_reject_wrap` | .0237 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 13 | `test_discovery01_k3_from_one` | .0248 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 14 | `test_discovery01_k3_backward_from_m` | .0227 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 15 | `test_discovery01_k3_forward_near_limit` | .0264 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 16 | `test_discovery01_k3_backward_wrap_from_one` | .0247 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 17 | `test_discovery01_k3_reject_l_plus_one_backward` | .0230 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 18 | `test_discovery01_k3_reject_space_forward_wrap` | .0230 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 19 | `test_discovery01_k3_one_backward_wraps_to_rejected_space` | .0234 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |
| 20 | `test_discovery01_k3_limit_bidirectional_boundary` | .0232 | 0 | `[WasmTypes.Value.i32(1)]` | vacía | no | PASS |

**Resultado:** 20/20 procesos Native PASS; 0 trap; 0 timeout; 0 `i32(0)`, 0 salida de error.

**Oráculo 6/6:** `quotient_and_remainder`, `limit_formula`, `l_plus_one_backward`, `space_forward_wrap`, `one_backward_wrap`, `limit_bidirectional`.

## Estado de etapa y próximo experimento

Sin defectos reproducidos; no se crea `EXPECTED_RED`. La evidencia no es `Stage02 PASS`: falta el contrato de aceptación completo y no se reconstruyó el ZIP histórico original. La ejecución CI de `Canonical Names Lock` se verificará a nivel de commit del informe y no constituye QA semántico.

**NEXT:** Examinar si es factible generar con `first`, `step` válidos un caso `choose_wide` k=3 que requiera pocos rechazos, o demostrar analíticamente el mínimo de rechazos para los intervalos críticos. Si no se obtiene un camino acotado, diseñar pruebas de propiedad de los helpers con inyección controlada en un wrapper de pruebas, sin modificar la semántica productiva. Mantener oracle independiente y regresiones de 20 exports.
