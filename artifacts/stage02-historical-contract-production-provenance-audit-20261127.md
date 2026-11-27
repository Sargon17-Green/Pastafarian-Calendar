# Auditoría de aceptación Stage02: procedencia y separación producción/oráculo — 2026-11-27

Proyecto: PC-BRANCH-WAT-SPANISH. Rama: WAT+Español. HEAD auditado: 15911dedb4db99b5167e324a3abe372a70ae6662. Auditoría documental y estática; no se ejecutó de nuevo ninguna prueba Native ni se modificó WAT.

## Identidad de archivos recuperados

Se leyeron directamente los cuatro ZIP recuperados, se recalculó SHA-256 de los bytes y se comprobó CRC sin errores. Los hashes identifican los ejemplares actuales; no son certificaciones históricas independientes.

| Archivo | SHA-256 |
|---|---|
| WAT_Espanol_Stage01_Production_Rebuild.zip | 6a8c0458f00fbda8fbb58f89ae014f9d3bf2e7a9340a1ef56bd5b87c20049c90 |
| WAT_Espanol_Stage02_Discovery01(1).zip | a84b11b327901ccbc4cecf5f5a3e6b211bc6179bc28b5a092868c0682af2e53f |
| WAT_Espanol_Stage02_Discovery01.zip | 52b894d4b11715c5446d511f7cf8c05afe00ffd0bb9e36cd83b21326a47218fa |
| Pastafarian_Work_to_Chat_Handoffs_2026-09-16.zip | e38c7c75ce108adf16899f86db5502ce810a620e7c734544598537c48657bb24 |

Los 19/19 hashes internos del handoff coinciden. MANIFEST.json y 06_WAT_Espanol.md identifican explícitamente la variante (1) y el siguiente archivo WAT_Espanol_Stage03_Patch01(1).zip, pero sus hashes no figuran en SHA256SUMS.txt: esa lista cubre únicamente los documentos del handoff. No se confunden las dos variantes: la sin sufijo tiene src/scar_save.wat y tests/discovery_01_save.wat; la (1) contiene src/production/spaghetti_calendar.wat y DEVELOPMENT_STAGE.md, que declara RED y CURRENT_PATCH=00. No se ha recuperado Patch01 ni una suma histórica independiente.

## Delta histórico comprobado byte a byte

SHA-256 del módulo de producción Stage01: 55302c42fb54999a42574a59e8aae37b503b0c2667eb88c7e61aea57b7800dc3.
SHA-256 del módulo Stage02(1): d44e5529f868a7bad1f223e11e895d8eeb027e65511d8094cc4cf0e73577a32f.

El diff completo de líneas tiene un único bloque: dos líneas sustituidas (comentario y una instrucción) en save_big. Stage01 copia M cuando len(TMP6)=0; Stage02 copia TMP6 incondicionalmente. El predicado test_save_m no cambia. Según las pruebas Native históricas ya registradas en el seguimiento, el resultado observado de los módulos originales fue 1 frente a 0; no se repite esa ejecución. El contrato matemático es SAVE(x)=1+((x-1) mod M), M=2^127-1, para x entero; por tanto SAVE(M)=M. La regresión histórica queda localizada, no inventada.

## Contraste con el remoto

Se comprobó el commit de referencia del handoff, 9fb7b61979879a9876ab8c2c43421ee03a414293, además de HEAD. En ambos, DEVELOPMENT_STAGE.md (blob 8e9e1a01d1a1d68772b5ed4f0a1d4fc70c420226) declara LAST_COMPLETED_STAGE=1. La ruta src/production/spaghetti_calendar.wat devuelve 404 en ambos. En ambos existe oracle/normative_calendar_wide.wat con el mismo blob 70267bb5730678f81d6138a2224d6b8d9a193eb8, que ya contiene el tratamiento de residuo cero correcto. En HEAD, src/monster_bootstrap.wat (blob a803abe599de3b8df4f9ad0afd1136c2442cb2aa) exporta el despachador neutral y pruebas de contexto, no calendar_date; no hay import del oráculo en ese archivo. Esto NO prueba la integración del motor de producción; tampoco acredita Patch01 ni un cambio nuevo. La arquitectura de Stage01 recuperada identifica src/production/spaghetti_calendar.wat como único módulo de producción; la ruta no está en los dos commits comprobados. No se presupone ausencia de cualquier ruta alternativa sin inventario completo.

## Matriz del contrato reanudado

STAGE02_DISCOVERY01_CONTRACT.md, blob 323820f4f1f644fdfb8910560e64102ba5ec2515, idéntico en a264a3cac63b66af2325a14a3a89fed10292e5dc y HEAD, define una investigación distinta del selector, no reconstrucción de la entrega histórica.

1. SHA y blob congelados: documentados en artifacts/stage02-discovery01-native-qa-20261103.md (commit 7d2d17a57f3ef389dc7ce4c0658714e7b67aa3d0).
2. Seis sondas y regresiones: ese informe registra 4/4 regresiones, 6/6 sondas iniciales y 2/2 adicionales; no se atribuyen a SAVE ni al HEAD actual.
3. Native WasmKit 0.1.6: informe de 12/12 con salida literal, exit y tiempos; revisión documental de evidencia anterior, no nueva ejecución.
4. Hipótesis de defecto del selector: no confirmada en esa investigación. El RED histórico recuperado pertenece a otro módulo y a SAVE.
5. Investigación ampliada: no autoriza cerrar Stage02.
6. Sin reconstrucción de ZIP, sin main/merge, sin aceptación global.

El seguimiento documenta Native SAVE(M) 13/13 en el oracle exacto, run 46003858169, job 140521988680, artifact 15199930356, con manifiesto 38/38; esta auditoría no descargó de nuevo ese artifact ni el paquete de evidencia histórica (este último no fue accesible en la sesión). El PASS del oráculo no sustituye al RED histórico de producción ni a la identidad del parche.

## Decisión y puerta siguiente

Stage02 NOT ACCEPTED; Stage03 NOT OPENED. Conservar Stage01 y toda evidencia. No aplicar ZIP ni alterar marcador de etapa, no volver a ejecutar SAVE(M) aceptado en el mismo blob. La recuperación nominal y los hashes actuales no cierran la procedencia histórica. El siguiente paso técnico es inventariar exclusivamente los puntos de entrada de producción de la rama y compararlos con la arquitectura Stage01 recuperada; no promover código hasta resolver la discrepancia. Para validar checksum/Patch01, únicamente buscar una nueva referencia de origen fechada e independiente que contenga el ZIP exacto o su digest histórico; no repetir búsquedas ya infructuosas. Si no aparece, cualquier sustitución del requisito de procedencia o reconstrucción de etapa necesita decisión explícita, no una aceptación implícita.
