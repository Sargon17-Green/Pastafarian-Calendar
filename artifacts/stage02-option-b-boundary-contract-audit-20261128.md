# Auditoría estática de frontera — alternativa B, 2026-11-28

PC-BRANCH-WAT-SPANISH / WAT+Español. Base HEAD verificada: 5a7ae6c373274a88a2fabcc2b26787ec7b430afb. Alcance documental de la alternativa B aprobada; no cambios en src, oracle, tests, workflow o marcador. No se repite SAVE(M).

## Trazabilidad y autoridad

| Propiedad | Fuente de contrato y referencia de implementación (en HEAD base) | Resultado / hueco |
|---|---|---|
| Arranque neutral | ARCHITECTURE_STAGE01.md c348f6ab2815bc94fd625d9b1b2489d8dd76419d; src/monster_bootstrap.wat a803abe599de3b8df4f9ad0afd1136c2442cb2aa, 72–120 | Handles opacos, no días ni fecha; token 48 no semántico. |
| Enteros exactos | ARCHITECTURE_STAGE01; src/wide_integer.wat 511e005f4cb47829aeb0d225d590774c64789027, 9–109 | signo, longitud, capacidad, miembros little-endian base 2^30. Puntero i32 no es el valor. |
| Catálogo | catalog/source_language_catalog.tsv cc03345cd5786fde57badece1f943e90b8a0db62; src/source_language_catalog.wat 736d4359e56273c985728096e35d21ee289ab9c8, 73–93 | 17 y 47 filas consecutivas; índices 1..17 y 1..47; fuera de rango devuelve puntero 0. Presentación no ordena. |
| Intervalo | ARCHITECTURE_STAGE01; oracle/normative_calendar_wide.wat 70267bb5730678f81d6138a2224d6b8d9a193eb8, 1086–1096, 1490–1502 | open < t <= close; comparación amplia; navegación secuencial. |
| Cinco campos | ARCHITECTURE_STAGE01; mismo oracle 3084–3157 | año es puntero amplio; nombre de chuleta, día de chuleta, nombre de mes y ordinal de aparición. Registro global s_RESULT_RECORD, 20 bytes; accesores sin argumento. |
| Selector | STAGE02_DISCOVERY01_CONTRACT.md 323820f4f1f644fdfb8910560e64102ba5ec2515 | contrato local de investigación, no prueba de dominio completo de producción. |
| Autoridad externa | documentos de rama consultados declaran derivación del documento autoritativo | texto autoritativo original completo no localizado en esta lectura dirigida; no afirmar que ABI, máximos, códigos de error, política de recursos ni orden normativo completo están ratificados. |

README 00b137dcc46d652ab649c00e8bc7d9fd04f7d2eb corrobora los cinco campos y catálogo; Fundación (5000,10,949,3,54) es regresión del mismo linaje, no expectativa independiente. DEVELOPMENT_STAGE.md 8e9e1a01d1a1d68772b5ed4f0a1d4fc70c420226 conserva LAST_COMPLETED_STAGE=1.

## B02 — derivación independiente de representación

Sea B=2^30. Para entero z, s=sign(z), d_i=floor(abs(z)/B^i) mod B, n mínimo con abs(z)<B^n (n=0 para cero). Reconstrucción z=s sum(d_i B^i). Para cada magnitud no nula ejecutar ambos signos en futura QA. Tabla calculada con BigInt puro mediante división y resto, sin ejecutar WAT:

| Magnitud | Miembros (menos significativo primero) |
|---|---|
| 0 | [] |
| 1 | [1] |
| 1073741823 | [1073741823] |
| 1073741824 | [0,1] |
| 9007199254740992 | [0,8388608] |
| 9223372036854775807 | [1073741823,1073741823,7] |
| 9223372036854775808 | [0,0,8] |
| 170141183460469231731687303715884105727 | [1073741823,1073741823,1073741823,1073741823,127] |
| 170141183460469231731687303715884105728 | [0,0,0,0,128] |

17 valores firmados, producto cartesiano ordenado 289 pares de días; son sondas de representación, NO 289 cálculos calendario. Comparar entrada, reconstrucción y serialización exacta por valor, sin Number/i64 para días/año. ASCII canónico de prueba: ^(0|-?[1-9][0-9]*)$ con coincidencia de toda la cadena; rechazar vacío, -0, +1, 01, -01, espacios, salto final, dígitos Unicode, decimal, exponente, NUL y entrada truncada. No publicar como ABI. Política de tamaño aún abierta; un límite explícito es error de recursos, no fecha.

Hallazgo estático: wide_set_header (97–103) comprueba signo -1..1 y longitud <=capacidad, normaliza miembros altos cero, pero permite signo 0 con magnitud no cero y por ello no es validador externo completo. wide_set_limb verifica valor y capacidad, no propiedad del puntero; alloc/new (26–59) usan aritmética i32 en tamaños/end, por lo que una longitud hostil requiere validación previa de multiplicación y suma sin wrap. No se afirma fallo Native. Contrato candidato: validar forma, cap>=max(1,n), signo coherente, miembro superior no cero, cada miembro <B, región propia y longitud completa antes de construir; escribir miembros antes de header que normaliza. Rechazar objetos inválidos sin tocar instancia. No exponer arena_restore a entrada hostil.

## B04 — derivación independiente

M=2^127-1. U=M para N<=M, U=M² para M<N<=3M; L=U-(U mod N); rank=1+((x-1) mod N). Desde respuesta 1 con paso +1, x=1 en ruta corta y x=M+1 en amplia. Desde M con paso -1, x=M en corta y x=M²-M en amplia. Cálculo BigInt independiente (sin WAT):

| N | k | U-L | rank + | rank - |
|---|---|---|---|---|
| M | 1 | 0 | 1 | M |
| M+1 | 2 | 1 | M+1 | 2 |
| 2M | 2 | M | M+1 | 2M |
| 3M | 2 | M | M+1 | 3M |

Todos los x iniciales anteriores son aceptables. Para N=2M,3M, M-1 divisible por 2 y 3, de modo que x=L. Para N=M+1, M≡-1 (mod N), M²≡1 y x≡2. En cualquier caso x=L acepta rango N. En el anillo de valores sintetizados de tamaño U (no respuestas individuales), si L<U: x=L+1 con paso -1 rechaza una vez y acepta L/rango N; con +1 rechaza U-L veces y vuelve a 1/rango 1. x=U con +1 rechaza una vez y vuelve a 1. N=M no tiene región de rechazo. No confundir sondas de frontera sintéticas con entradas alcanzables por dos respuestas consecutivas del anillo de salsa: x=U requiere a0=a1=M y no es alcanzable como par consecutivo ±1. Para 2M/3M no ejecutar M iteraciones: derivación algebraica o sonda de salto con equivalencia demostrada, bajo presupuesto. No reclamar nuevas ejecuciones ni repetir SAVE(M); antes de una sonda nueva cotejar cobertura histórica y seleccionar únicamente huecos.

## B03/B07 — aislamiento y resolución

Contrato QA futuro: A y B entradas serializadas distintas (incluyendo signos opuestos), instancias con memorias independientes. Capturar A1 por copia de valor, intercalar B1 y A2, exigir A1=A2 y B1 igual a B aislada; no exigir A!=B porque pueden resolver misma fecha. Verificar que la memoria de A no cambia durante llamada B y viceversa (comparar snapshot de regiones válidas, no direcciones numéricas entre instancias). Inyectar fallo de validación en B; A sigue íntegra. Copiar año y cuatro campos antes de otra llamada o restore; accesores existentes leen registro global sobrescrito, no un resultado persistente por puntero. Prohibir entrada cruda de puntero entre instancias y fallback oracle; resultado atómico, sin campos parciales tras trap/error. Métricas bootstrap no son semánticas. Una instancia nueva por invocación es opción inicial conservadora, no ABI ratificado; no se promete concurrencia dentro del oracle existente.

Para año y chuleta: si t=open, excluido; t=open+1 primer día; t=close incluido; t=close+1 excluido. Si intervalos contiguos (confirmar con fuente autoritativa), frontera compartida corresponde al intervalo anterior. En resolución, offset=t-open, índice de palabra offset-1; para segmento (a,b], ordinal de chuleta=offset-a; nombre de mes por identificador de palabra en offset-1, ordinal=conteo inclusivo de ese identificador en prefijo. Año no reducir a i64. Límites i32 de offsets internos no se extrapolan a dominio público. Sonda matemática con intervalos sintéticos no es fecha normativa. El orden de entrelazado completo y cotas exactas requieren autoridad adicional.

B04 pertenece a DISCOVERY 01 acotado; B01/B02/B03/B07/B08 son preparación contractual/estática, B05/B06 requieren derivación normativa separada, B09/B10 evidencia y puertas. Ninguna de estas etiquetas abre etapa nueva. No se ha ejecutado WAT, CI, Native ni diferencial nuevo. Stage02 NOT ACCEPTED; Stage03 NOT OPENED. NEXT: localizar de forma dirigida el documento autoritativo original o su referencia exacta; contrastar límites, semántica de serialización y cobertura histórica B04 antes de diseñar sondas no duplicadas. Sin integración ni promoción.
