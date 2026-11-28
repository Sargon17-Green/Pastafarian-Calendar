# Alternativa B — recuperación de autoridad y cobertura B04
Fecha: 2026-11-28. PC-BRANCH-WAT-SPANISH, WAT+Español. Base 4bccbf13f6c6ae675d4915eaa8055cacb40c85e3, tree 095d09919f555bc55c0396e221ec25ad50f914dc. Diseño/QA documental solamente.

## Fuente normativa recuperada
La búsqueda dirigida de la referencia de la Meguilá encontró el documento hebreo completo en el repositorio de fuentes Sargon17-Green/pastafari-calendar, main fijado en 73a3ff88d34133a002f9bf6151fcdf3452b7b777, path sources/מגילת העיתים.md, blob 291353f4e5a83bb3d958b7f98e32040ee00b9f8a. Se leyó el texto original del archivo, no código de otra rama. Enlace inmutable: https://github.com/Sargon17-Green/pastafari-calendar/blob/73a3ff88d34133a002f9bf6151fcdf3452b7b777/sources/מגילת%20העיתים.md . No se afirma que este blob sea el entregado históricamente con Stage02.

| Líneas | Contrato y consecuencia |
|---|---|
| 49–76, 1027–1067 | Dos días ordenados, dominio temporal sin extremos. Si d es desplazamiento firmado desde Fundación: identificador 2d+1 para d>=0, -2d para d<0. El identificador positivo NO es cronológico; 0 como desplazamiento es Fundación, no identificador válido. Entrada decimal firmada de desplazamientos es propuesta técnica, no formato prescrito. |
| 149–179, 601–715 | M=2^127-1, SAVE en 1..M; respuestas consecutivas ±1. k mínimo con M^k>=N, dígitos little-endian, avance circular unitario conceptual, rechazo x>L. Nota 12 advierte explícitamente que la elección amplia no es probabilísticamente uniforme: no imponer uniformidad como QA. |
| 733–817 y nota 13 (1108) | Gaps 42..963, años 252..5778, >=6 gaps; 5781 es errata explícita. Intervalo (open,close]; año 0 y negativos admitidos; sin límite de i64. |
| 820–850 | 6..17 cutlets, cada uno >=1 gap; partición positiva lexicográfica, corte obligatorio en gate interior del día de cálculo. |
| 889–957 | 3..47 meses, longitud 4..123, primer y último orden de aparición crecientes; orden lexicográfico de palabra completa, no elección independiente por día. |
| 1038–1053 | Cinco campos exactamente; índice de nombre de cutlet 1..17 y mes 1..47 tras mapear entidades del catálogo congelado; ordinal de cutlet 1..5568 (5778-5*42, cota conservadora no máximo alcanzable probado); ordinal de mes 1..123. Número de año entero firmado sin cota normativa. |
 
La cota de 47^5778 para familias de Choose de calendario, k<=253, queda respaldada por los límites del texto y por el análisis de envelope anterior. Es una cota superior, no cardinalidad máxima alcanzable ni restricción de Choose genérico. 5778/42=137+remainder: máximo 137 gaps. La fuente no impone ASCII, base 2^30, punteros i32, presupuesto de memoria/tiempo, ni ABI/códigos de error: conservarlos como decisiones técnicas separadas. No prometer cálculo de días arbitrariamente remotos en tiempo fijo.

## Cobertura B04 histórica y huecos
Se contrastó el contrato 323820f4, informe de 03-11 (12/12) e informe de 21-11 (run 44923220858, jobs 136903553082 y 136903553258, artifact 14714581950; fuente 871f9b70216c16c57abcd552ec6fb0ed1010e305, WAT SHA256 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980). Informe previo documenta comprobación de los 111 logs individuales, no nueva descarga/revisión de artifact en esta sesión. Módulo actual tests/normative_selector.wat blob e23f013ab96b498b0ac365dbb1b25273c845e790. Se inspeccionaron las definiciones de las seis sondas originales: cuatro forward first=1 para N=M,M+1,2M,3M y backward first=M para 2M,3M. La prueba M+2 forward first=M-1 ya comprueba wrap en otro N; M-1 backward first=M comprueba rechazo corto. No repetir estas sondas como nueva cobertura.

Candidatos B04 adicionales (antes de escribir tests cotejar cuerpos completos de los demás exports y fuentes históricas, no inferir ausencia solo por nombre). U=M^2 para ruta amplia; L=U-U mod N. Se evaluaron las seis filas con BigInt exacto independiente en esta sesión, sin WAT ni fixtures de otras ramas:
 
| N | first | step | x inicial | pasos rechazados | rank |
|---|---|---:|---|---:|---|
| M | M | -1 | M | 0 | M |
| M+1 | M | -1 | U-M | 0 | 2 |
| 2M | 1 | -1 | U-M+1=L+1 | 1 | 2M |
| 3M | 1 | -1 | U-M+1=L+1 | 1 | 3M |
| 2M | M-1 | +1 | U-1 | 2 | 1 |
| 3M | M-1 | +1 | U-1 | 2 | 1 |

Para M+1, único valor rechazado U es inalcanzable como primera pareja de respuestas consecutivas, porque requiere a0=a1=M. Para 2M y 3M, L=U-M: los casos de rechazo de esta tabla son alcanzables en el anillo de respuestas abstracto (no afirmar que se ha encontrado un par de días de salsa que los produzca); ninguno necesita M iteraciones. Cotejar las sondas M/M+1 inversas y las cuatro de rechazo con los cuerpos completos antes de agregar solo huecos demostrados. Criterios futuros: comparar k,U,L,x inicial, valor aceptado y rank exactos; 30s/1GiB por proceso, exit/log/hash, sin duplicar corrida; ningún resultado semántico inferido de timeout. 

No nuevo Native, CI o diferencial WAT; no cambio src, oracle, tests, workflow o marker; no SAVE(M) repetido ni Stage03. Stage02 NOT ACCEPTED. La procedencia histórica de ZIP/Patch01 sigue sin autenticarse. NEXT: inventario exhaustivo de los cuerpos de export B04 para eliminar duplicados y preparar únicamente sondas de hueco en diseño, con oráculo independiente; revisar discrepancia de contrato de entrada identificador positivo vs desplazamiento firmado antes de fijar interfaz. No integración ni promoción.
