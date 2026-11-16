# Stage02 DISCOVERY01 — k=4 / q=1 boundary probes (2026-11-16)

- Proyecto: `PC-BRANCH-WAT-SPANISH`; rama `WAT+Español`.
- Parent validado: `4017bbf8152eff82a64f78c947814e545174a85e`; CI run 43938749123 attempt 1 **completed/success**, verify and semantic checkout SHA exacto. WABT 1.0.34; 75/75 Native; 47 oráculos BigInt; 79.132/79.132 pares Python del selector corto. Fuente WAT SHA256 `9a23f68d194b690f92063e0d498ed90966ccd7a565df0d386ba76df3a6d359b6`.
- Brecha: la ruta amplia `k=4` sin pruebas de rechazo y salto. El nuevo conjunto contrasta casos q=1 en cuatro dígitos, con `M=2^127-1`, sin tocar `choose_wide`.
- Para `first=2`, `step=-1`, `x=M^4-M^3-M^2+2`; probar `N=x` (límite exacto, 0 rechazos) y `N=x-2` (dos rechazos, aceptar `LIMIT=N`, `rank=N`).
- Para `first=M-3`, `step=+1`, `x=M^4-M^2-2M-3`; probar `N=x` (límite exacto) y `N=x-1` (saltar `M^2+2M+4` rechazos hasta `WIDE=1, rank=1`).
- Oráculo independiente: reconstrucción aritmética BigInt desde cuatro dígitos del anillo; contraste de memoria `M,FIRST,CUR,N,SPACE,LIMIT,WIDE,RESULT` para cada export, sin calcular expectativas a partir de salidas WASM.
- Preflight matemático efectuado (JavaScript local en la sesión): bases 4..32, **116/116** trayectorias de paso unitario, **12.644** rechazos, 0 discrepancias; 4 expectativas algebraicas en M real. La versión ejecutable y reproducible está en `tests/stage02_k4_q1_boundary_oracle.py`; su ejecución dentro del nuevo CI aún no está validada.
- Gates nuevos: Python independiente, compilación WABT, 79/79 Native y 51 oráculos numéricos exactos, 0 traps/timeouts/stderr, SHA idéntico en ambos jobs. No afirmar PASS sin logs `completed`.
- No se modifica `main`, ni el algoritmo del selector, ni se declara Stage02 ACCEPTED/EXPECTED_RED.
