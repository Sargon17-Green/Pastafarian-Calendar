# Stage02 — DISCOVERY 01 — cota exacta de liveness para `step=+1`

**Proyecto:** `PC-BRANCH-WAT-SPANISH` · **Rama:** `WAT+Español` · **Fecha:** 2026-11-03

## Procedencia y alcance

- HEAD de entrada verificado por consulta directa a GitHub: `6365d1432d157699cb8b6c3e9cc2098c70e41b99`.
- Fuente analizada: `tests/normative_selector.wat`, función `$choose_wide`, bucle `$rej`, que comprueba `WIDE <= LIMIT` y, si no, llama a `$wide_ring_step` con `step=±1`.
- Contrato autorizado: `STAGE02_DISCOVERY01_CONTRACT.md`. No se usan implementaciones de otras ramas.
- La investigación matemática no modifica el algoritmo WAT. **No se ha ejecutado la ruta astronómica en Native**, ni se declara un timeout observado, defecto histórico reproducido, `EXPECTED_RED` o `Stage02 PASS`.

## Riesgo probado algebraicamente, sin ejecutar un bucle astronómico

Sea `M=2^127−1`, `S=M³` y el `N=M²+1` del contrato. El tamaño mínimo del espacio amplio es `S` (`k=3`).

Para `first=M−2`, `step=+1`, los dígitos consecutivos son `M−3`, `M−2`, `M−1`, de menor a mayor potencia. Por tanto:

```
x = 1 + (M−3) + (M−2)M + (M−1)M² = S−M−2
q = floor(S/N) = M−1
L = qN = S−M²+M−1
x−L = M²−2M−1 > 0
```

El valor inicial excede el límite, de modo que la versión actual del bucle rechaza `x`. Para `step=+1`, los valores posteriores son `x+1,x+2,…,S,1`; todos los anteriores a `1` siguen siendo `>L`. El **número exacto de iteraciones de rechazo** es `S−x+1=M+3=170141183460469231731687303715884105730`, y el valor aceptado tras la vuelta es `1`, con rango final `1`.

Esta cantidad es una consecuencia de la semántica actual del código. No es una duración medida, ni un fallo Native reproducido. El coste del bucle crece linealmente con el número de rechazos y cada paso incluye aritmética multiprecisión; la ruta es inviable en la práctica.

## Guard matemáticamente equivalente propuesto

Para una muestra `x` que cumpla `1 <= x <= SPACE` y `LIMIT >= 1`:

- Si `x <= LIMIT`, aceptar directamente `x` (sin rechazo).
- Si `x > LIMIT` y `step=+1`, el primer valor aceptado de la órbita circular ascendente es **`1`**: puede saltarse la parte `x+1,…,SPACE`.
- Si `x > LIMIT` y `step=−1`, el primer valor aceptado de la órbita descendente es **`LIMIT`**: puede saltarse la parte `x−1,…,LIMIT`.

El guard no altera la distribución objetivo de la especificación para cada trayectoria determinista, porque conserva exactamente el primer valor aceptado y, por tanto, `rank=1+((accepted−1) mod N)`. Reduce el número de pasos de rechazo a O(1) en ambas direcciones. **No debe hacerse pasar esta equivalencia matemática por un PASS de la implementación WAT.**

## Oracle independiente ejecutado

Script reproducible: `tests/stage02_discovery01_forward_liveness_oracle.py`. Utiliza enteros Python arbitrarios y la fórmula directa para generar dígitos a partir de `first,step,M`, sin importar ni ejecutar el WAT. En modelos acotados también simula el anillo elemento a elemento y compara su primer valor aceptado y la cantidad de iteraciones con el salto cerrado.

Comando ejecutado: `python3 tests/stage02_discovery01_forward_liveness_oracle.py` (antes del commit, sobre los mismos bytes de la fuente).

```text
PROJECT_ID=PC-BRANCH-WAT-SPANISH
TOY_WIDE_CASES=35088 PASS
TOY_REJECTION_CASES=7262 PASS
TOY_MAX_REJECTIONS=546
PRODUCTION_GAP_X_MINUS_LIMIT=28948022309329048855892746252171976962636931432568264082937646787114745987074
PRODUCTION_FORWARD_REJECTIONS=170141183460469231731687303715884105730
PRODUCTION_RESULT_RANK=1
VERDICT=ANALYTICAL_ORACLE_PASS; NATIVE_NOT_RUN; NO_STAGE02_PASS
```

El barrido acotado cubre **todos los `N` de `(M,M³]`, todos los `first` de `[1,M]` y ambos `step`** para `M∈{3,5,7,11}`. En total son 35 088 comparaciones independientes de valor aceptado y contador de rechazos; 7262 casos realmente requirieron rechazo. El caso grande de producción se prueba solo mediante identidades exactas, no por simulación del bucle.

**SHA256 del script del oracle ejecutado:** `c8b7eaa41c593c2c027922b0c841ea657c92b501372ea115028f360698e22cc8`.

## Estado y NEXT

La rama sigue **abierta / READY**; `Stage02` continúa en investigación, sin `EXPECTED_RED`, sin atribución de un defecto histórico y sin cambio de `main`.

**NEXT:** introducir un parche mínimo en la misma rama que sustituya **solo** el bucle de rechazo de `$choose_wide` por el salto exacto anterior; agregar al menos una sonda end-to-end para `N=M²+1, first=M−2, step=+1` y otra para `step=−1`; verificar fuente Git blob/SHA, ejecutar WasmKit Native con límite de 30 segundos por export y todas las regresiones, y comparar contra el oracle independiente. No ejecutar el caso astronómico en el código antiguo sin límite estricto. Aún no se autoriza `Stage02 PASS`.
