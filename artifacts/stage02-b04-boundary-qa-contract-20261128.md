# WAT+Español — B04 focused boundary QA contract

- Project: PC-BRANCH-WAT-SPANISH
- Branch: WAT+Español
- Base HEAD at authoring: 8da736cb3103d469fda02191e1243642903e4fe3
- Locked selector test source: tests/normative_selector.wat
- Locked Git blob: e23f013ab96b498b0ac365dbb1b25273c845e790
- Locked source SHA-256: 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980
- Scope: QA only. The locked base WAT is not edited; a temporary augmented module is assembled in the runner's temp directory.

## Mathematical contract

Let M=2^127-1 and U=M^2. For a positive N, choose the least k with M^k>=N and set SPACE=M^k, q=floor(SPACE/N), LIMIT=qN. Starting from first, generate k response digits by literal ±1 transitions on the ring [1,M]. Interpret them little-endian as:

x = 1 + Σ((a_j - 1) M^j).

If x>LIMIT, continue the same ±1 transition on [1,SPACE] until y<=LIMIT. The exact output is RESULT=((y-1) mod N)+1.

## Candidate matrix

| Case | N | first | step | k | Initial x | LIMIT | Accepted y | Rejections | RESULT |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| C1 | M | M | -1 | 1 | M | M | M | 0 | M |
| C2 | M+1 | M | -1 | 2 | U-M | U-1 | U-M | 0 | 2 |
| C3 | 2M | 1 | -1 | 2 | U-M+1 | U-M | U-M | 1 | 2M |
| C4 | 3M | 1 | -1 | 2 | U-M+1 | U-M | U-M | 1 | 3M |
| C5 | 2M | M-1 | +1 | 2 | U-1 | U-M | 1 | 2 | 1 |
| C6 | 3M | M-1 | +1 | 2 | U-1 | U-M | 1 | 2 | 1 |

C1 is the short path: verify RESULT and LIMIT; SPACE is not written by the short-path routine. C2-C6 must verify RESULT, LIMIT and SPACE=U. C5/C6 are one parametric WAT export that executes both N values and checks each call; the C5 intermediate RESULT/LIMIT/SPACE/N are copied into reserved QA observation cells so the external differential can inspect both executions.

## Independent oracle and execution

1. stage02_b04_boundary_oracle.py: Python arbitrary-precision integers; no imports from the selector, prior oracle, or another branch. It derives k, builds the digit stream using literal ring transitions, performs at most two literal rejection transitions, computes the exact rank, and cross-checks the six explicit algebraic witnesses.
2. stage02_b04_boundary_differential.cjs: instantiates the temporary module in Node WebAssembly and compares actual memory fields RESULT/LIMIT/SPACE (plus N and FIRST) against the independent oracle. C5 and C6 are both checked from actual memory, not merely inferred from the combined export's final state.
3. wat-stage02-b04-boundary-native.yml: compiles with WABT, validates the module, and runs five focused exports in fresh WasmKit 0.1.6 processes. Each process has a 30-second timeout and a 1 GiB virtual-address-space cap. Raw stdout, stderr, exit codes, manifests and generated module hashes are preserved as an Actions artifact, including on failure.

## Acceptance boundaries

- Static Python compilation and WABT validation are separate from Node differential and WasmKit Native.
- A WasmKit export passes only with exit code 0, exact i32(1) output, and empty stderr.
- TIMEOUT, kill, runtime error and unexpected return are distinct outcomes; none is silently converted to PASS or EXPECTED_RED.
- This QA does not modify production src, the locked base selector WAT, SAVE(M), main, or Stage03. No merge is performed.
- A successful five-export QA gate is not acceptance of Stage02. Historical Stage02 ZIP/manifest provenance and the other Stage02 gates remain separate.
