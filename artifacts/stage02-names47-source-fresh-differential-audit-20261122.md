# Stage02 Names47 focused source-fresh CI and independent differential audit (2026-11-22)

PROJECT_ID: PC-BRANCH-WAT-SPANISH

## Provenance
Authorized branch before integration: WAT+Español at fdc6bb4e94f3d69e229998f86e768b71e9571ae8.
Isolated QA run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45066080002
Run attempt 1, completed/success, QA SHA 2fd261156c1d91d5b2b2af38ce9fe2dd3dd48ab6, job 137342396159 completed/success.
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45066080002/artifacts/14771940537
ZIP bytes 16,217; ZIP SHA256 a77ba011424dcd1833326a1d499460c8cad53248717b4ded19995f5d75a9cf03; CRC integrity checked.
Locked tests/normative_selector.wat Git blob e23f013ab96b498b0ac365dbb1b25273c845e790; source SHA256 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980.
Source-fresh instrumented.wasm SHA256 fa579a0a8d6e2d35ec4b0cad44688f4f3122bb2759e9a068c6af95343590a202.
Workflow: WABT 1.0.34, Python 3.12.3, Node v22.23.5, fresh wat2wasm and wasm-validate PASS. The instrumentation adds two QA-only exports; the locked source WAT is not edited.

## Focused CI Native
Oracle N=47! = 258623241511168180642964355153611979969197632389120000000000 (198 bits), family DistinctNames(47,47).
forward: PASS, decimal rank SHA256 af77b83c02097ff201ed0848390024fb04773c58b236a09dfa5ea2dbf3b3adce, n_limbs 7, result_limbs 5, rejection false.
backward: PASS, decimal rank SHA256 b3cafdb279a6d89eb83c8cf0647bdb383d73cf4102ddf07c71dc1b09f885cfc5, n_limbs 7, result_limbs 7, rejection true.
Both outputs independently matched Python oracle and artifact forward/backward.result.json, summary.json and native.log. This is FOCUSED_NATIVE_PASS only.

## Additional differential verification (local Node Native on verified artifact, not another CI run)
Code: tests/stage02_names47_differential_oracle.py (independently implemented mathematical oracle) and tests/stage02_names47_differential_native.cjs (SHA-locked imported artifact runner).
14 N values, each forward and backward: total 28 PASS, 0 FAIL. k=1: 6; k=2: 16; k=3: 4; k=4: 2. Five rejection observations by independent math.
N values: 1, 10, M; M+1; 47!-1, 47!, 47!+1; M^2-M-1, M^2-M, M^2-M+1, M^2, M^2+1; M^3, M^3+1, where M=2^127-1.
Independent oracle calculates smallest k with M^k>=N, positional ring digits, acceptance limit floor(M^k/N)*N, direction-dependent rejection jump, and 1-based residue. Native cases match expected decimal integer and SHA256, preserving N.
Local differential verified against instrumented.wasm from the above downloaded artifact, NOT a fresh local WAT compilation. This does not replace source-fresh CI.
The generated differential vector JSON sha256 was bfaf5447a3d0c3690138dfa9c36c6030cbab7def1fcfbb2e1b82dbe66825f959 and result JSON sha256 ec5b908f77c7c261a2d5117537323bd22426c33c8238668fffda0faf44e40329.

Reproduce after downloading and extracting artifact 14771940537:
python3 tests/stage02_names47_differential_oracle.py differential-vectors.json
node tests/stage02_names47_differential_native.cjs instrumented.wasm differential-vectors.json

## Scope and gaps
The original Stage02 ZIP+manifest remain unavailable/unverified. The test-only source selector and instrumented exports are not claimed to validate production calendar integration. Stage02 globally NOT ACCEPTED. The Native focused gate and differential 28/28 are accepted ONLY within their defined scopes. No main, merge, release or policy change.
NEXT: source-aware calendar-invoked call-chain evidence tying bounded canonical Choose families to their runtime paths, without replaying already accepted SHA tests; re-evaluate remaining historical provenance requirement separately.
