# Stage02 DISCOVERY01 — extremos N=1,2,4,11; preflight y gate Native

- Proyecto: PC-BRANCH-WAT-SPANISH; rama: WAT+Español; fecha: 2026-11-16.
- Base verificada: `fc9595a986a0dc0faca6bbc284bb5dbbe616156d`. Run anterior 42390629195 attempt 1, **completed/success**, jobs verify 128457259238 y semantic 128457258976; ambos checkout exacto `fc9595a986a0dc0faca6bbc284bb5dbbe616156d`.
- Native anterior (WABT 1.0.34, Node WebAssembly): 67/67; BigInt 39/39; Python q4/q5 27.700/27.700 y 12.812 rechazos; fuente WAT SHA256 `e85c989414aa77139f00d697f1b43a74de0b33cc53267c16181425b20d5d89b5`.
- Brecha elegida: extremo de cociente corto. Para N=1,2,4,11, M=2^127-1, first=M y step=±1, se comprueba `limit=floor(M/N)N`, primera aceptación y rango exacto. N=1 prueba el caso q=M, diferente de q=1..5; N=4/11 generan 3/6 rechazos hacia atrás, sin iteraciones astronómicas.
- Preflight ejecutado en Python (sin WASM): 81 módulos acotados, **79.132/79.132** casos en anillo exhaustivo, **14.908** pasos de rechazo, **4.724** pares con al menos un rechazo, 0 diferencias; 8 casos algebraicos de producción y control de mutación en N>1. `python -m py_compile` PASS.
- Cambio WAT: solo helper de test y 8 exports de producción; código de `choose_short/choose_wide` intacto. Runner agrega 8 oráculos BigInt exactos de 6 celdas de memoria y exige **75/75 Native, 47** verificaciones numéricas. Workflow incluye nuevo oracle Python.
- Criterio de aceptación local: todos los tests Python, canonical lock, compilación con WABT, 75/75 exports y 47/47 oráculos BigInt, cero trap/timeout/stderr, checkout SHA de los dos jobs. **Este informe no afirma Native nuevo sin CI completed+logs**.
- Stage02 queda abierto; no EXPECTED_RED sin defecto reproducido; no modificación de main, merge ni release.
