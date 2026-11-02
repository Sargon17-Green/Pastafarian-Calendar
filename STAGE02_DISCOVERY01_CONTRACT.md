# Etapa 2 — DISCOVERY 01 — contrato de investigación reanudada

## Procedencia y decisión de continuidad

- Proyecto: `PC-BRANCH-WAT-SPANISH`, rama `WAT+Español`.
- Base inicial verificada de la investigación: `126e2990e854847be8a176708a610942636f986e`.
- La etapa 1 permanece completada y su catálogo sigue congelado.
- Se autorizó históricamente iniciar la etapa 2. El ZIP original de `Stage02` y su manifiesto no están disponibles; **este documento no los reconstruye ni afirma equivalencia con esa entrega**.
- Ante la solicitud de reactivar la rama del 3 de noviembre de 2026, se abre una nueva investigación verificable dentro de `DISCOVERY 01`, sin modificar ni inventar el contenido de la entrega ausente. La procedencia de cada artefacto nuevo se distinguirá de la historia original.

## Pregunta de descubrimiento

¿La transición de la selección normativa de ruta corta a ruta amplia, junto con el límite de rechazo y el paso circular, conserva el rango `1 <= rank <= N` exactamente para `N=M, M+1, 2M, 3M`, donde `M=2^127-1`?

La investigación es de código local de la rama: `tests/normative_selector.wat`. No se presume que exista un fallo histórico, ni se marca `EXPECTED_RED` hasta que una ejecución del código de la rama lo reproduzca. No se usan salidas, fixtures, parches ni código de otras implementaciones.

## Semántica y oráculo matemático independiente

Selección corta (`N <= M`): `q=floor(M/N)`, `L=qN`; recorrer las respuestas del anillo hasta `x<=L` y devolver `((x-1) mod N)+1`.

Selección amplia (`N>M`): tomar el mínimo `k` con `M^k>=N`. Construir `x=1+sum_{j=0}^{k-1} (a_j-1)M^j` desde respuestas consecutivas del anillo `[1,M]`; rechazar avanzando en `[1,M^k]` hasta `x<=floor(M^k/N)N`; devolver `((x-1) mod N)+1`.

Para el caso acotado de respuestas iniciales `a_0=1`, `a_1=2` y paso `+1`, la derivación independiente da:

| N | Ruta | k | Valor aceptado | Rango esperado |
| --- | --- | ---: | --- | --- |
| `M` | corta | 1 | `1` | `1` |
| `M+1` | amplia | 2 | `M+1` | `M+1` |
| `2M` | amplia | 2 | `M+1` | `M+1` |
| `3M` | amplia | 2 | `M+1` | `M+1` |

Para los tres valores amplios, `M^2>=N`, `x=M+1` y `x<=floor(M^2/N)N` (ninguna consulta requiere recorrer astronómicamente el anillo). El valor `M+1` está dentro del rango `1..N` y por ello la fórmula de rango lo conserva. Para `N=M`, la ruta corta acepta la primera respuesta.

La verificación también debe cubrir el paso inverso `-1` desde `a_0=M`, con `a_1=M-1`; en la ruta amplia `x=M^2-M`. Para `N=2M` y `N=3M`, `M-1` es divisible por `2` y `3` respectivamente (pues `M=2^127-1` es impar y `M mod 3=1`). En ambos casos `x=floor(M^2/N)N` y el rango esperado es exactamente `N`. Esto son casos de igualdad en el límite de aceptación, no resultados de ejecución aún.

## Entradas, salidas y límites

- Entrada: `first` en `[1,M]`, `step` en `{-1,+1}`, `N` positivo (sin exceder las cotas normativas de la especificación).
- Salida: un índice natural exacto en `[1,N]` representado sin reducción a `i64`.
- Primer lote: cuatro valores de `N` por `step=+1`, y dos casos inversos de igualdad para `N=2M,3M`.
- Cada caso de WAT debe retornar `i32(1)` solo si el valor exacto coincide; cualquier salida `i32(0)`, trap, timeout o error de parseo debe documentarse separadamente.
- Límite de tiempo para cada ejecución Native: 30 segundos. Un timeout no es una prueba semántica de `EXPECTED_RED`.

## Criterios de aceptación de DISCOVERY 01

1. Congelar SHA de la rama y blob del módulo antes de cualquier cambio.
2. Mantener las pruebas antiguas intactas y agregar las seis sondas descritas. El oráculo de expectativas de este documento no se calcula desde la salida del módulo.
3. Ejecutar las sondas y las regresiones Native en WasmKit con versión y salida literal capturadas, sin reutilizar un PASS histórico como nueva evidencia.
4. Si aparece una desviación, aislar el menor caso que falla, comprobarlo de nuevo con los datos exactos y registrar el fallo real antes de decidir `EXPECTED_RED` y abrir un parche.
5. Si las sondas pasan, registrar explícitamente «hipótesis no confirmada»; ampliar la investigación sin fabricar un fallo ni cerrar la etapa como completada.
6. No modificar `main`, no fusionar, no dar por reconstruido el ZIP histórico, no usar implementaciones ajenas y no anunciar PASS de etapa sin evidencia completa.

**Estado de este contrato:** investigación nueva abierta. No constituye por sí solo éxito semántico, reproducción de defecto ni terminación de la etapa 2.
