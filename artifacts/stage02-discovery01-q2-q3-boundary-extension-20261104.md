# DISCOVERY01: ampliación exacta de vecindad q=2 / q=3

- PROJECT_ID: `PC-BRANCH-WAT-SPANISH`
- Rama: `WAT+Español`; referencia de código: `a7606f2ca18b0460e920040015d3d724a095f1ba`
- Objetivo: evaluar dos vecinos adicionales del rechazo en la ruta amplia k=3, sin alterar la implementación de `choose`.
- Procedencia: investigación nueva de DISCOVERY01; **no** reconstrucción del ZIP Stage02 original.

## Contrato medible

Sea `M = 2^127-1`, `S = M^3`. El flujo `first=1, step=-1` produce `(a0,a1,a2) = (1,M,M-1)`, de donde
`x = 1+(M-1)M+(M-2)M²=(M-1)(M²-1)`.

Para cada `q ∈ {2,3}` (ambos dividen `M-1`), definir `Tq=x/q` y `N=Tq+δ` con `δ∈{-1,0,+1}`.
Para `M>=5` en q=2 y `M>=7, M≡1(mod 3)` en q=3, los modelos elegidos satisfacen
`M² < N < S`, `floor(S/N)=q`, `LIMIT=qN`, `x-LIMIT=-qδ`.
La primera aceptación con paso -1 es `WIDE=min(x,LIMIT)`.

| δ | Estado inicial | WIDE esperado | RESULT esperado |
| -: | --- | --- | --- |
| -1 | Rechazado (q pasos hasta LIMIT) | `LIMIT` | `N` |
| 0 | Igual al límite | `LIMIT` | `N` |
| +1 | Aceptado debajo del límite | `LIMIT-q` | `N-q` |

- Nuevas sondas Native: `test_discovery01_k3_backward_q2_n_minus_one` y `test_discovery01_k3_backward_q2_n_plus_one`.
- Regresión anterior: 31 exports, incluidas 3 sondas numéricas q=3; total propuesto: **33**.
- Oráculo Python q=2: 9 modelos pequeños `M={5,7,9,11,13,15,17,19,21}` × 3 valores δ y 3 casos con `M=2^127-1` = 30.
- Oráculo Python q=3 existente: 27 modelos pequeños + 3 de producción = 30.
- Oráculo Node BigInt independiente: compara `M,N,LIMIT,SPACE,WIDE,RESULT` directamente de la memoria Wasm en las cinco sondas numéricas.

## Límites y criterios de evidencia

Las sondas deben devolver `i32(1)`. La suite Native ejecuta cada export en proceso independiente, con límite de 30 s, `exit=0`, salida válida y `stderr` vacío. Un timeout, trap, error de compilación o salida distinta se clasifica como fallo del test; no se convierte automáticamente en EXPECTED_RED.

Evidencia previa al CI: 30/30 casos de q=2 comprobados aritméticamente con enteros exactos fuera de WAT; 33/33 nombres de export únicos y paréntesis balanceados tras la edición del módulo. **No se afirma aún ejecución Native ni PASS de Stage02 sobre el nuevo SHA.** Se requiere run completed/log para esa afirmación.

## NEXT

Verificar workflow disparado sobre el nuevo HEAD exacto; leer ambos jobs y checkout. Exigir 33/33 Native, 30/30 Python q=2 y 30/30 Python q=3, campos numéricos exactos y cero trap/timeout/stderr. Si falla, aislar y reparar en esta rama; si pasa, continuar DISCOVERY01 con un caso distinto de borde sin dar por completado Stage02 automáticamente.
