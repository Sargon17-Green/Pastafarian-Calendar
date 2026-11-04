# Etapa 2 / DISCOVERY01 — viabilidad de la frontera q=3, paso +1 (2026-11-04)

- Proyecto: `PC-BRANCH-WAT-SPANISH`; rama exclusiva: `WAT+Español`.
- Fuente de entrada congelada: commit `7110d5e846e48ec67cfe608f4090b4b4ae9972f4`.
- Blob WAT no modificado: `2b67a790162f9e0e08644d501a90344e2d3b1c0d` (`tests/normative_selector.wat`).
- Herramienta independiente nueva: `tests/stage02_discovery01_q3_forward_feasibility.py`; blob verificado `36906b19c3fe4792de8d70e4edc24e2456de3513`; SHA-256 `ac9a9c6ac46b35bd9110e1c2a61d39ebf31d8b55fe7798cb5ad34707c48912b6`.

## Resultado: la frontera ausente es matemáticamente inalcanzable

En la rama amplia de tres dígitos, `M=2^127-1`, `S=M^3`, `M^2 < N <= S`, `q=floor(S/N)=3`, `LIMIT=3N`. Los dígitos se generan por `$ring_step`, empezando por `first=a` y aplicando `step=+1` sobre el anillo `[1,M]`. `$choose_wide` construye `x = a_0+(a_1-1)M+(a_2-1)M^2`.

1. Para `1 <= a <= M-2`, los tres dígitos son `a,a+1,a+2`. Por tanto `x=a(M^2+M+1)+M^2`. Como `M = 2^127-1 ≡ 1 (mod 3)`, se cumple `M^2+M+1 ≡ 0 (mod 3)` y `M^2 ≡ 1 (mod 3)`. Por ello `x ≡ 1 (mod 3)` y nunca puede ser `3N`.
2. Para `a=M-1`, los dígitos son `M-1,M,1`, dando `x=M^2-1`. Como `N>M^2`, necesariamente `x<3N`.
3. Para `a=M`, los dígitos son `M,1,2`, dando `x=M^2+M<3N`.

Estos tres casos agotan `first∈[1,M]`. Luego `q=3, step=+1, x=LIMIT` **no admite ninguna entrada legal de esta familia**. No se debe marcar la ausencia como fallo de cobertura Native, ni inventar un `EXPECTED_RED`. La prueba depende de la semántica de tres respuestas consecutivas; no pretende descartar un selector con otra fuente de dígitos.

## Control de no-vacuidad — dirección inversa

Para `first=1, step=-1`, los dígitos son `1,M,M-1`, luego `x=S-M^2-M+1`. Es divisible por 3 y define `N=x/3`. Para el `M` de producción, `N>M^2`, `floor(S/N)=3` y **`x=LIMIT=3N`**. Por tanto la igualdad en la frontera es alcanzable en dirección inversa y permite una prueba Native concreta futura.

## QA independiente, ejecutado en este ciclo

Ejecución: `python -m py_compile tests/stage02_discovery01_q3_forward_feasibility.py` y `python tests/stage02_discovery01_q3_forward_feasibility.py` con Python 3.13.5; ambos código de salida 0.

- Enumeración exhaustiva de `first × N` en ventanas `q=3` para `M={4,7,10,13,19,31,43}`, todos `M≡1(mod 3)`: **376,191 parejas verificadas; 0 contraejemplos**; 9,981 valores de `N` agregados.
- Comparación entre construcción de dígitos con módulo y fórmula por casos para cada `first`.
- **6 testigos inversos** para `M>=7`, todos `q=3` y `x=LIMIT`.
- Pruebas numéricas de congruencia y de los tres casos en el `M=2^127-1` de producción, incluido testigo inverso; salida `pass=true`.
- SHA-256 del JSON generado localmente: `4413f1f2595a7570da7c0b4812ab9297b3520fdbd694f3db0cf3d1a74b84264f`.
- **Naturaleza de las pruebas:** Python independiente y demostración matemática; NO WasmKit/Native en este ciclo, NO diferencial contra la ejecución del módulo WAT.

## Verificación del CI de la fuente de partida

GitHub Actions **run 41791607829** (push, `WAT+Español`, `7110d5e846e48ec67cfe608f4090b4b4ae9972f4`): `completed/success`; job `126446035615`, `completed/success`. El log confirma `git fetch` y `checkout` sobre el SHA exacto. El único paso de verificación es **Canonical Names Lock**; no prueba la semántica de WAT ni el código Python añadido en commits posteriores.

## Estado y siguiente paso

`DISCOVERY01` permanece **OPEN / READY**. Los anteriores 35/35 casos differential Native y 1/1 control negativo conservan su propia evidencia en el informe anterior; no fueron repetidos. `Stage02 PASS` no está declarado. No se alteró `main`, no hubo merge ni publicación.

**NEXT:** verificar el push-run del nuevo HEAD (sin confundir names lock con Native). Añadir un caso Native end-to-end independiente para el testigo legal `first=1,step=-1,N=(M^3-M^2-M+1)/3`, usando oracle externo y salida exacta; después valorar la integración de pruebas semánticas al workflow del propio branch, con límites explícitos.
