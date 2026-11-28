# DISCOVERY24 Alternative C — streaming/admission/execution contract (2026-11-28)

Scope: test-only prototype on Clojure+Nederlands. No production source/API change, no Stage56, no merge/main, no change to the 128N search budget or 5,000,000N production shared-group ceiling.

## Input and transport

Accepted fixed grammar:
{"profile":[4..123,...],"p":1..520,"rank":"positive-decimal"}

- ASCII only; no whitespace, duplicate keys, extra keys, or trailing bytes.
- 2–33 month lengths, each 4–123; total days at most 3,569.
- Position is 1-based, less than total days, and at most 520.
- Frame at most 176,120 bytes; chunks are nonempty and at most 4,096 bytes.
- The parser stores the bounded profile and rank bytes. It does not create a whole-frame string, call JSON.parse, or convert the rank to an integer.
- The rank is converted to exact JVM arbitrary precision only after admission succeeds; its bit length is checked against W after each decimal digit.

## Admission certificate

For month count m, total days n, and target p:

- B = 2n ceil(log2(m+1)) + 2 ceil(log2(n+1)) + 8
- W = 2B + 2, Q = 1 + (p-1)m
- S = 256[Q((m+1)(n+1)+n+m+1) + p(m+1)^2 + n+p+1]
- C = 4B + 8m + 8p + 256
- T = 16(W+1)^2 S + 32C(W+1)^2
- L = W[3(n+1)+4m+p+128] + 8C + 16(W+1)

Caps: S ≤ 550,000,000,000; T ≤ 65,000,000,000,000,000,000,000; L ≤ 1,000,000,000 bits. Each cap has exact-boundary acceptance and cap-minus-one refusal tests.

For canonical year 5000, m=33, n=3569, p=520: B=42,860; W=85,722; Q=17,128; S=548,176,392,704; T=64,451,838,941,170,797,954,816; L=987,726,308 bits. This is an admission result only, not proof of successful execution.

## Arithmetic and resource semantics

- Native arithmetic uses Clojure arbitrary-precision integers backed by java.math.BigInteger; no signed-64-bit wraparound is permitted.
- The execution ledger counts BigInteger add/subtract/multiply/divide/remainder/compare operations plus explicit DP-cell and candidate-control steps.
- Bit work is a conservative schoolbook upper bound: multiplication/division/remainder use operand bit-length products; addition/subtraction/comparison use the larger operand width plus one. Every result and operand is checked against W.
- The DP-write counter is a bounded Long; each individual DP cell and candidate step is separately counted by the control ledger, so the counter itself does not add unmetered BigInteger work.
- Logical live-payload is reported as the admission formula's analytical upper bound, not misrepresented as measured heap. Actual JVM heap use is sampled separately.
- Native execution has a 90-second wall watchdog and a 256-MiB heap-delta watchdog. Heap samples occur at least every 256 counted arithmetic/control operations and at candidate boundaries. Exceeding either limit is an explicit refusal/failure, never an indefinite wait.
- The existing source raming diagnostic is reported separately and is excluded from the Alternative C arithmetic ledger.

## Independent correctness gates

- Exhaustive small profiles check complete first-occurrence and last-occurrence ordering.
- The canonical input is regenerated from the existing production/normative cross-check, then passed through the streaming parser and admission gate.
- The existing in-place insertion rank model receives only the admitted parsed profile/rank and computes p=520.
- The independent Python gap-convolution oracle must match the total, p81/p82/p520 prefix digests, and p520 month/day.
- The independent normative Clojure oracle combines the independently supplied p520 month/day with the remaining date components and requires equality of all five numeric fields.
- No full month-weaving word is materialized; the production date API is not invoked.

## Acceptance boundary

The implementation commit was [skip ci]. The repository workflow has no workflow_dispatch trigger; its Native Stage02 job runs on a normal push to this branch. This follow-up commit is that push-trigger for the exact current source. Static checks and parser/admission tests do not make Stage2 accepted. Acceptance requires a completed exact-SHA Native run, its raw job log and artifact, all p520 five-field comparisons, the arithmetic/resource ledger within caps, and both watchdogs passing. Until those gates pass, Stage2/DISCOVERY24 remain OPEN.
