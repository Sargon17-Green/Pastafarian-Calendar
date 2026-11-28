# Alternativa B — plan de integración de producción separado

Fecha: 2026-11-28. Proyecto PC-BRANCH-WAT-SPANISH; rama WAT+Español.
Decisión expresa del usuario: conservar el bootstrap neutral y planificar una integración de producción separada. Alcance: diseño y QA de contrato, no autorización de promoción, cambio de marcador, Stage03 ni publicación.

## 1. Base inmutable y evidencia

HEAD de diseño: fa6a0276c06c751577de70f2b8027edd44e0c795.
- ARCHITECTURE_STAGE01.md: c348f6ab2815bc94fd625d9b1b2489d8dd76419d.
- DEVELOPMENT_STAGE.md: 8e9e1a01d1a1d68772b5ed4f0a1d4fc70c420226; LAST_COMPLETED_STAGE=1.
- src/monster_bootstrap.wat: a803abe599de3b8df4f9ad0afd1136c2442cb2aa.
- src/wide_integer.wat: 511e005f4cb47829aeb0d225d590774c64789027 (inventario anterior).
- STAGE02_DISCOVERY01_CONTRACT.md: 323820f4f1f644fdfb8910560e64102ba5ec2515.
- oracle/normative_calendar_wide.wat: 70267bb5730678f81d6138a2224d6b8d9a193eb8 (inventario anterior).
- Inventario: artifacts/stage02-production-entrypoint-inventory-20261127.md. El módulo histórico de producción, sin su envoltorio calendar_date, es idéntico al oráculo WAT. No se recupera en src, no se copia ni se utiliza como segunda implementación independiente.
- SAVE(M) 13/13 y CI semántico 111/111 son evidencias previas de alcance limitado; no son aceptación de integración.

## 2. Fronteras propuestas

Conservar byte a byte el arranque neutral: sus dos identificadores opacos no se interpretan como días, sus fases 0/10/20/30 y estados 0/1/-1 son de ciclo de vida, y el token de desplazamiento 48 no prueba ningún cálculo. No introducir llamadas a oracle/ ni tests/ ni alterar la propiedad exclusiva del MonsterContext de 64 bytes. El bootstrap conserva sus exportaciones y no se convierte en un calendario.

Diseñar una capa candidata aparte, sin instalarla en src ni conectarla al bootstrap durante esta autorización. Separar tres responsabilidades: (a) adaptador de entrada/salida y memoria; (b) futuro motor WAT de producción, derivado del documento autoritativo y de los descubrimientos autorizados; (c) comparador externo de QA. No compartir memoria lineal entre instancias. El adaptador serializa valores, nunca pasa punteros de una instancia a otra. La futura dependencia ejecutable podrá incluir aritmética exacta de producción, nunca el oráculo ni el arnés QA. Se prohíbe un fallback al oráculo.

Contrato lógico propuesto (no ABI publicado): dos días enteros exactos con signo, calculationDay y targetDay; salida exitosa de exactamente cinco campos canónicos (año entero exacto, índice de chuleta, día de chuleta, índice de mes, ordinal de aparición del mes hasta el día objetivo inclusive). Frontera de prueba: decimal ASCII canónico para cada entero, 0 único, sin ceros iniciales ni -0; rechazar entradas mal formadas antes de tocar memoria. Índices de nombre 1..17 y 1..47 sujetos a verificación explícita contra el catálogo congelado antes de implementar. No convertir año ni días a i64 ni a Number. La representación interna de base 2^30 es una opción del motor, no una obligación del protocolo. El español se aplica únicamente en presentación; no cambia índices, orden ni rango. Un error, trap, límite de memoria o timeout nunca produce una fecha parcial ni un token de éxito semántico. El formato binario, los códigos de error públicos y las cotas definitivas quedan sin fijar hasta la revisión del contrato autoritativo; no se inventa una política de dominio.

## 3. Independencia y derivación

El oráculo existente puede servir como referencia de regresión, pero no como prueba suficiente de una integración basada en él. Para la investigación de Stage02 derivar las expectativas directamente de la especificación: selector corto q=floor(M/N), L=qN; selector amplio k mínimo con M^k>=N, x=1+sum((a_j-1)M^j), límite floor(M^k/N)N, rango 1+((x-1) mod N), M=2^127-1. Usar enumeración explícita de espacios pequeños y derivaciones algebraicas independientes para transiciones y conteos; no copiar las implementaciones, fixtures ni salidas de otras ramas. Para resultados completos derivar por separado los intervalos (open, close], estructura anual, cardinalidad y orden lexicográfico de familias y resolución de cinco campos. El caso Fundación de README es regresión del mismo linaje, no evidencia independiente de calendario completo. Toda optimización debe preservar cardinalidad, orden, pasos de consulta y observabilidad semántica. Si falta el documento autoritativo de una operación, registrar el hueco sin sustituirlo por una hipótesis normativa.

## 4. Matriz de aceptación propuesta

| ID | Prueba | Evidencia exigida |
|---|---|---|
| B01 | Inmutabilidad | SHA de bootstrap, catálogo, arquitectura, marcador y oráculo; comparación exacta de blobs; ningún import nuevo |
| B02 | Frontera de valores | cero, ±1, ±(2^30-1), ±2^30, ±2^63, ±(2^127-1), dos días independientes; rechazo de decimal no canónico; round-trip exacto |
| B03 | Aislamiento | dos contextos con identificadores distintos; intercalación A/B/A; dos memorias independientes; no fuga entre invocaciones ni uso semántico de métricas/token |
| B04 | Selector | M, M+1, 2M, 3M; ambos pasos; igualdad en límite, rechazo y vuelta circular; rango exacto; no repetir SAVE(M) ya aceptado |
| B05 | Año | frontera open excluida/close incluida, años negativos/positivos y ancla; derivar expectativas antes de observar motor |
| B06 | Estructura y entrelazado | enumeración exhaustiva de familias pequeñas, primera/última selección y vecinos; comparar cardinalidad, orden y cinco campos |
| B07 | Fallos | puntero fuera de memoria, longitud no válida, recursos agotados, trap y timeout diferenciados; ninguna fecha fabricada |
| B08 | Dependencias | inventario de imports y grafo de llamadas/archivos; ningún enlace a oracle/ ni tests/ en candidato de producción; comparación separada |
| B09 | Evidencia | compilación fresh desde SHA exacto, versión WABT/WasmKit, manifiesto SHA256, entradas y salidas crudas, exit codes, tiempo y memoria; sin duplicar ejecuciones |
| B10 | Aceptación | separar diseño, estática, Native, diferencial, etapa y promoción; ninguna etapa aceptada por un subconjunto |

B01–B10 son etiquetas de QA propuestas, no etapas nuevas. No hay resultados de estas pruebas en este documento. Los casos de B02 son valores de frontera de representación, no promesa de que el cálculo calendario completo para días remotos termine en plazo. Presupuesto inicial de sondas locales acotadas: 30 s y 1 GiB por proceso; para cálculo completo definir presupuesto antes de ejecutar. Timeout es un resultado de recursos, no EXPECTED_RED semántico.

## 5. Siguiente trabajo autorizado

Preparar una auditoría estática del contrato de frontera: localizar en fuentes autoritativas y catálogo WAT las representaciones de enteros, accesores del resultado, bases de índices y semántica de intervalos; construir una matriz de trazabilidad por símbolo/ruta, con huecos explícitos. Derivar expectativas de B02/B04 y preparar el contrato de pruebas de aislamiento sin modificar src. Revisar qué parte de B01–B10 corresponde al DISCOVERY 01 ya autorizado y cuál es integración futura. La construcción o conexión de un motor de producción, cambios de etapa, incorporación de arquitectura histórica y promoción requieren la puerta correspondiente; no se autorizan por esta nota.

No se cambia código WAT, workflow, main, merge, release ni DEVELOPMENT_STAGE. No se realiza ejecución nueva. Stage02 NOT ACCEPTED; Stage03 NOT OPENED.
