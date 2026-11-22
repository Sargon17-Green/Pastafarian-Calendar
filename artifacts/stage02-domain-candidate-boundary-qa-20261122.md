# Stage02 — Candidate-bound arithmetic gate (2026-11-22)

## Scope and provenance

- Project: `PC-BRANCH-WAT-SPANISH`; permitted branch: `WAT+Español`.
- Baseline live HEAD verified before authoring: `0a7b8b579cf93e8288fa773656fc63a597cdf3f6`; baseline tree `e52406971cd06034dd020db4e4882d63d951e603`.
- Unmodified Stage02 WAT source: `tests/normative_selector.wat`, locked blob `e23f013ab96b498b0ac365dbb1b25273c845e790`, SHA-256 `18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980`.
- Added independent, Python-stdlib-only candidate preflight `tests/stage02_domain_candidate_boundary.py`. Git blob SHA-1 `6d1fbfee619ff35b959979311f043342ac88a2a0`, SHA-256 `cc7e7590f696ed5418c15e441106374de5abaad3c8575282448176b935f4317e`, 6,158 bytes. It neither imports WAT nor invokes a WebAssembly runtime.
- Existing Native evidence inspected, not rerun: k253 run `44954094856`/job `136998240304` on QA SHA `97a602de4a9e6b154de4ad26c9882632a9b1deb5` (completed/success, `forward: PASS`, `backward: PASS`, artifact `14726874775`); k259 run `44960026911`/job `137016565982` on QA SHA `3072f5b2748d69b4308a15514d58a5af01b8cbad` (completed/success, Node 2/2, WasmKit 2/2, artifact `14728728384`). These are limited evidence and do not approve a normative domain.

## New bounded, independent test contract

- Input: exactly one `--power BASE^EXP` (positive BASE, nonnegative EXP) or `--decimal-file PATH` (strict ASCII positive integer). The preflight rejects N=0/negative, invalid expressions and inputs above 100,000 bits.
- Model: `M=2^127-1`; `k` is the least positive integer for which `M^k >= N`, using host-language exact integers and repeated multiplication; `SPACE=M^k`, `q=SPACE//N`, `LIMIT=q*N`, and `LIMIT <= SPACE < LIMIT+N`. For wide inputs `q < M` is asserted.
- Conservative storage envelope: `max(bit_length(SPACE),bit_length(M*N)) <= 1100*30`. This checks arithmetic capacity only, not code behavior, latency, or the domain policy. The M*N bound is conservative on short-route inputs.
- Nine probes for the current candidate `47^5778`: `N-1`, `N`, `N+1`; `M`, `M+1`; `M^(k-1)`, `M^(k-1)+1`; `M^k`, `M^k+1`. Exact integer fingerprints are SHA-256 of minimal unsigned big-endian bytes, **not** hashes of decimal strings.
- Output: JSON explicitly marked `STATIC_NUMERIC_CANDIDATE_ONLY`, with `normative_maximum_approved=false`, `native_or_differential_pass=false`, `stage02_accepted=false`, `source_policy_verified=false`. There is no invocation option that changes these flags to true.

## Local reproducible QA

Environment: Python 3.13.5; no external packages, CI dispatch or runtime WAT execution.

```bash
python tests/stage02_domain_candidate_boundary.py --self-test
python tests/stage02_domain_candidate_boundary.py --power '47^5778'
```

Observed self-test result: `Ran 5 tests ... OK` (exit 0). Candidate result: `STATIC_NUMERIC_CANDIDATE_ONLY`; exactly 9 probes. Candidate N has 32,095 bits; k=253; SPACE 32,131 bits; M*N 32,222 bits; 1,075 conservative 30-bit limbs of 1,100; q 37 bits. SHA-256 of candidate minimal unsigned big-endian encoding: `d478a375f19722eb786c816870829def4035bb4131109d1a17af778c700adc88`.

| Probe | k | Required limbs | Envelope |
| --- | ---: | ---: | --- |
| N−1, N, N+1 | 253 | 1,075 | FIT |
| M, M+1 | 1, 2 | 9, 9 | FIT |
| M^252, M^252+1 | 252, 253 | 1,072, 1,072 | FIT |
| M^253, M^253+1 | 253, 254 | 1,076, 1,076 | FIT |

The arithmetic and invariant tests passed locally. This does not claim Native, CI, differential or full-stage PASS. No WAT code, production source, accepted fixture, existing workflow, main or protected branch was modified. No duplicated run was dispatched.

## Still open; explicit policy gate

The source comment's `47^5778` is a stress candidate, not an authoritative maximum. To approve Stage02's domain, the authorized decision-maker must provide the bound N_max and its authoritative derivation or source. After that decision, use the parameterized preflight at the approved N_max and N_max±1, then align runtime oracle, boundary tests and acceptance contract. The original Stage02 ZIP+manifest remains unavailable under the existing provenance contract and is not reconstructed by this QA. Stage02 remains **NOT ACCEPTED**. Until the policy decision, status remains `ממתינה להכרעה` / `ממתין להכרעה`.
