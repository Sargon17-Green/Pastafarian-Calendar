# Stage02 Option B — authoritative source traceability and QA continuation

- Project: PC-BRANCH-WAT-SPANISH
- Branch at audit: WAT+Español
- Branch HEAD at audit: be68f7b37f9045d35dc41d177fafa84eb6a005d3
- Source repository commit: 73a3ff88d34133a002f9bf6151fcdf3452b7b777
- Scope: static traceability and QA only; no production source, main, SAVE(M), Stage03, or merge changes.

## 1. Normative source recovered

The authoritative Scroll is present in the source repository at:

- Path: sources/מגילת העיתים.md
- Git blob: 291353f4e5a83bb3d958b7f98e32040ee00b9f8a
- SHA-256 recorded by sources/SHA256SUMS.txt: d36b0c944b4685d1aa1d89bb20a8dd530ee3167c897dcdf85161a7ec0dde9c96
- Published reference recorded by CONFORMANCE.md: https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html

A documentation path discrepancy was found: implementations/docs/CONFORMANCE.md links to sources/Megilat-HaItim.md, which is not present at the pinned source commit. The actual file is sources/מגילת העיתים.md; both docs/AUTHORITATIVE-ENGINE-ARCHITECTURE.md and sources/SHA256SUMS.txt identify the Hebrew filename. No source-repository document was changed.

## 2. Normative facts and implementation traceability

| Normative subject | Scroll reference | Current implementation mapping | Finding |
|---|---|---|---|
| Ordered inputs | lines 8–14 | oracle/normative_calendar_wide.wat wide_calendar_date(dayWorkPtr, dayAskedPtr) | The first day is the calculation/work day; the second is the queried/target day. This order is normative. |
| Day-number domain | lines 45–76 | src/monster_bootstrap.wat accepts opaque i32 handles; no semantic parser | External day numbers are positive. Relative offset 0 maps to 1; later offset d>0 maps to 2d+1; earlier offset d<0 maps to -2d. The resulting identifiers are unique but not chronological. Do not pass signed offsets as day IDs or sort IDs to infer date order. |
| Bowl modulus | lines 149–162 and 622–725 | tests/normative_selector.wat and the B04 QA fragment | M=2^127-1 is the response-ring bound [1,M], not a maximum day number, year number, or input-domain limit. |
| Selector | lines 622–725 | tests/normative_selector.wat; STAGE02_DISCOVERY01_CONTRACT.md | The response digits are interpreted least-significant first in base M. Wide selection uses SPACE=M^k, LIMIT=floor(SPACE/N)*N, rejects x>LIMIT by continuing the same direction on [1,SPACE], then maps the accepted rank into [1,N]. |
| Year intervals | lines 773–792 and 815–824 | oracle/normative_calendar_wide.wat lines 1086–1098 and 1490–1502 | A year is (open,close]: the opening day is excluded, the closing day included. Years are contiguous and non-overlapping; year numbering includes zero and negative values. |
| Year-length bounds | lines 782, 791–792, footnote 13 at line 1108 | oracle/normative_calendar_wide.wat year search | The main text has one isolated 5,781 value. Footnote 13 corrects it to 5,778, forced by six gaps × 963 days. The binding maximum is 5,778 days of year length, not a maximum year ordinal. |
| Cutlet catalog | lines 850–900 | catalog/source_language_catalog.tsv and src/source_language_catalog.wat | The Scroll fixes 17 ordered names. The implementation uses one-based indices 1..17 and NUL-terminated UTF-8 strings. |
| Month catalog | lines 900–1015 | catalog/source_language_catalog.tsv and src/source_language_catalog.wat | The Scroll fixes 47 ordered names; months contain 4..123 days. The implementation uses one-based indices 1..47. The source fixes list order, not a serialized numeric ABI. |
| Five result fields | lines 1027–1067 | oracle/normative_calendar_wide.wat lines 3084–3157 | Logical result: year number, cutlet name, day in cutlet, month name, day in month. No sixth logical field is defined. |
| Complexity of interleavings | footnote 14 at line 1109 | oracle/normative_calendar_wide.wat selector/counting implementation | The Scroll itself notes that enumerating all valid interleavings is infeasible; rank/counting logic is required. |

### Current WAT representation

At the audited branch HEAD:

- src/wide_integer.wat (blob 511e005f4cb47829aeb0d225d590774c64789027) stores signed integers using sign, length, capacity and little-endian base-2^30 limbs. The current capacity ceiling is 1,100 limbs.
- Static review found that the header setter does not enforce the canonical equivalence sign=0 iff length=0, and the allocator's i32 size arithmetic has no explicit overflow guard. The limb setter checks limb range/capacity but does not establish pointer ownership. These are static risks, not claimed runtime failures.
- src/source_language_catalog.wat (blob 736d4359e56273c985728096e35d21ee289ab9c8) exposes one-based catalog indices and NUL-terminated strings. Existing checks establish pointer presence for all 17 and 47 entries and reconcile three named entries; they do not prove the semantic translation of all 64 Spanish labels against the Scroll.
- src/monster_bootstrap.wat (blob a803abe599de3b8df4f9ad0afd1136c2442cb2aa) carries opaque i32 handles. It is not a day-number parser or a complete host adapter.
- oracle/normative_calendar_wide.wat (blob 70267bb5730678f81d6138a2224d6b8d9a193eb8) uses a 20-byte global result record. Its fields are: year pointer, cutlet-name pointer, day-in-cutlet i32, month-name pointer, day-in-month i32. The no-argument accessors read that shared record; a subsequent calculation overwrites it. It is therefore not a reentrant per-instance result API.
- The five logical fields are defined by the Scroll, but the pointer layout, string ownership, memory lifetime, error codes, concurrency semantics, and host serialization are implementation choices. The Scroll does not specify JSON or an ASCII decimal wire format.

## 3. B04 coverage and result

The original Stage02 discovery contract covers six selector cases: four forward +1 witnesses from first=1 for N=M, M+1, 2M and 3M; and two backward -1 exact-limit witnesses from first=M for N=2M and 3M.

The additional B04 cases are distinct in direction, starting point, rejection behavior or divisor:

- C1: short path, N=M, first=M, step=-1, equality at LIMIT.
- C2: wide path, N=M+1, first=M, step=-1, accepted without rejection.
- C3/C4: N=2M/3M, first=1, step=-1, x=LIMIT+1 and one rejection.
- C5/C6: N=2M/3M, first=M-1, step=+1, x=SPACE-1 and two rejections. These share the same x witness as the existing M+2 wrap case; the added coverage is the distinct N and exact LIMIT for each divisor, both checked from memory.

Evidence:
- B04 implementation commit: 1f66a9631212f732280682498b1e4881b3125796
- CI run: 46152186058
- B04 focused Native job: 141001362094
- Existing semantic job: 141001019230, 111/111
- B04 independent Python oracle: 6/6
- Node WebAssembly memory differential: 6/6
- WasmKit 0.1.6 Native: 5/5; every export exited 0, returned i32(1), and wrote empty stderr.
- Artifact: 15265914498. It contains the manifest, source and generated-module hashes, oracle and differential JSON, per-export stdout/stderr, and native-cases.tsv.
- The original selector WAT remains Git blob e23f013ab96b498b0ac365dbb1b25273c845e790 and SHA-256 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980. The B04 module is assembled in a temporary runner path; the locked source file is not edited.

## 4. B02 reference oracle

Added tests/stage02_b02_integer_boundary_oracle.py and its deterministic output artifact. The oracle uses Python arbitrary-precision integers and a base-2^30 limb model. It is independent of the WAT implementation.

Local self-check results:
- 17 signed representation values round-trip exactly.
- 289 ordered operand comparisons, with antisymmetry and diagonal checks.
- 16 non-canonical candidate decimal literals rejected.
- Seven normative offset-to-day-number samples match the Scroll.
- Eight positive values are valid day-number-domain samples; zero and negative values are not external day numbers.
- 64 of the 289 operand pairs have two positive day-number operands.
- Zero calendar calculations, zero Native runs, and zero differential claims.

The ASCII decimal pattern is a provisional QA candidate only, not a public ABI. The 17 signed values are representation probes; they must not be described as 17 valid external day IDs. The matrix reaches five base-2^30 limbs; it does not test the WAT allocator's 1,100-limb ceiling or prove the current WAT setters safe.

- Script SHA-256: 09d84b24ddd248f7b58cfbc9f4a6d4ec909bf308a89ca38debb52666fc7c5baf
- Output SHA-256: 68aacaea46b42ff92fc3fab76b09dc39b9dbd06cc30eae6d16d19e319c4a17b3

## 5. B03 isolation contract

A separate B03 contract is prepared. It requires isolated baselines A and B, then A1/B1/A2 interleaving with deep copies of all five result fields. A1 must equal A2; interleaved B1 must equal isolated B; a failed B call must not mutate A or expose a partial result. Raw pointers must not be compared across instances.

B03 is not executed: the current bootstrap has opaque handles, while the oracle exposes a shared global result record and no per-instance result ownership contract. A host adapter must copy the exact year value and both UTF-8 strings before the next call. No public serialization or ownership ABI is being claimed.

## 6. Gate classification and next step

B04 focused QA is accepted as a gate only. Stage02 as a whole remains NOT ACCEPTED: historical ZIP/manifest provenance remains unverified, the host ABI is not ratified, and the remaining Stage02 gates are separate. Stage03 remains unopened. No production source, SAVE(M), main, or merge was changed.

NEXT: prepare a QA-only host adapter and B03 isolation harness around positive day numbers in the normative input order, exact arbitrary-precision year copy-out, and deep-copied UTF-8 catalog strings. Keep the candidate decimal format and error/resource policy explicitly provisional; do not publish or integrate a public ABI.
