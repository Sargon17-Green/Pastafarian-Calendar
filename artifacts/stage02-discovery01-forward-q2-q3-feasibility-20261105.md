# DISCOVERY01: viabilidad matemática forward +1 en frontera q=2 y q=3

- PROJECT_ID: `PC-BRANCH-WAT-SPANISH`
- Rama: `WAT+Español`
- Base verificada antes de la investigación: `43a6a6f0c8cdacb011a2690966314967a577459c`.
- Nuevo oráculo: `tests/stage02_discovery01_forward_q2_q3_feasibility.py` (blob `ca8f5ba93638aa2308b9c36c91a578f43513b453`).
- Es una investigación nueva de Stage02 DISCOVERY01, no una reconstrucción del paquete histórico ni una prueba Native de WebAssembly.

## Modelo exacto y demostración

Sea `M=2^127-1`, `S=M^3`, `first=M-2`, `step=+1`, `k=3`. Las tres respuestas consecutivas son `M-2,M-1,M`, por lo que el valor inicial es

`x=1+(M-3)+(M-2)M+(M-1)M² = M³-M-2`.

Para `q=2`, `x` es par. Definir `N=x/2+delta`, `delta in {-1,0,+1}`: se verificó `M²<N<S`, `floor(S/N)=2` y `x-LIMIT=-2*delta`, con `LIMIT=2N`. Por ello hay un testigo real de igualdad forward en `delta=0`.

Para `q=3`, `M ≡ 1 (mod 3)`. Si `1<=first<=M-2`, se obtiene `x=first*(M²+M+1)+M² ≡ 1 (mod 3)`. Si `first=M-1` o `M`, el valor inicial es, respectivamente, `M²-1` o `M²+M`, ambos estrictamente inferiores a `3N` para todo `N>M²`. Por lo tanto `x=3N` es **imposible** en toda la ruta forward con `k=3, q=3` para este M: no buscar un testigo inexistente. Para construir vecinos posibles, definir `N=floor(x/3)+delta`, `delta in {-1,0,+1}`; entonces `x-LIMIT=1-3*delta`, y `floor(S/N)=3`.

Como el anillo wide recorre `[1,S]`, con paso positivo y `x>LIMIT` la primera aceptación se produce después de `S-x+1` desplazamientos en `1`; si `x<=LIMIT`, se acepta `x` sin desplazamientos.

| q | delta | x-LIMIT | accepted WIDE | RESULT |
| --- | ---: | ---: | --- | --- |
| 2 | -1 | +2 | 1 (wrap) | 1 |
| 2 | 0 | 0 | x | N |
| 2 | +1 | -2 | x | N-2 |
| 3 | -1 | +4 | 1 (wrap) | 1 |
| 3 | 0 | +1 | 1 (wrap) | 1 |
| 3 | +1 | -2 | x | N-2 |

## QA independiente completado (2026-11-05)

Se ejecutaron Python 3.13.5 y `python -m py_compile` contra el archivo local; ambos terminaron correctamente. El archivo publicado y el ejecutado coinciden a nivel de Git blob SHA-1 (`ca8f5ba93638aa2308b9c36c91a578f43513b453`); SHA-256 del archivo: `94866dff8483198ba1d5e222a09883d666ac1dc917967bc68075f0e3d7f964f7`.

- Pruebas construidas sobre `M={7,13,19,25,31,2^127-1}`: **36/36 PASS**, incluidas 6 de producción; 0 fallos.
- Búsqueda exhaustiva de todos los `first` y `N` legales en ventanas `q=2/3` y `k=3` para `M={7,13,19,25,31}`: **368862 pares** evaluados, con 0 coincidencias `q=3` y 15 coincidencias `q=2`.
- Reparto de pares por M, respectivamente `q2/q3`: 7: 399/203; 13: 4758/2379; 19: 21717/10868; 25: 65100/32550; 31: 153915/76973.
- La salida del script incluye `N,SPACE,initial_x,LIMIT,accepted_x,RESULT` exactos para los seis testigos de producción. No se utiliza el código WAT ni sus respuestas como oráculo.

**Alcance de la evidencia:** prueba matemática + QA Python independiente; todavía **NO** se ejecutó WAT Native para estos seis casos. No se declara PASS total de Stage02, ni un defecto histórico, ni EXPECTED_RED.

## NEXT medible

Agregar **6 exports** WAT forward para las seis filas, sobre `tests/normative_selector.wat` en la rama actual, y ampliar `tests/run_stage02_discovery01_webassembly.cjs` de 33 a 39 tests. El runner debe contrastar con `BigInt` independiente los seis campos de memoria `M,N,LIMIT,SPACE,WIDE,RESULT` en los seis casos nuevos, además de las cinco sondas antiguas, preservando las 33 regresiones. Compilar con WABT, ejecutar cada export en proceso aislado (30 s máximo), verificar `i32(1)`, `exit=0`, `stderr` vacío, cero traps/timeouts; después exigir GitHub Actions `completed/success` y comprobar el SHA real de checkout en logs antes de atribuir PASS Native. Sin cambio a `main` ni merge.
