# Logo+Ido Stage 2 — isolated cutlet-partition QA

Project: PC-BRANCH-LOGO-IDO
Canonical parent: ad001c6aeeb6c758f5004b206a656fec5d6fc403
Scope: QA-only. No production-source edits, no ASK(2,21) call, no canonical-branch update, no merge/main, and no Stage 3.

## API and bounds

The frozen year-pair contract requires at least 6 gate-index intervals and at most 5,778 elapsed days. Each interval is at least 42 days: nr.gate.gap returns 41 plus a rank in 1..922. Therefore production G is 6 <= G <= floor(5778/42) = 137. The candidate's defensive API ceiling is 5778; the tests exercise production boundary values and small mathematical edges. The normative cutlet selector uses 6 <= K <= min(17,G), while the API accepts 1 <= K <= G.

G, K, and required are small integer coordinates, matching the normative caller's bi.to.small conversion. required is -1 (no required prefix) or an internal prefix r with 1 <= r < G.

- qa.cp.count G K required: canonical arbitrary-precision BI count; invalid input -> []; valid empty domain -> bi.zero.
- qa.cp.rank G K required parts: canonical one-based lexicographic BI rank; invalid composition -> [].
- qa.cp.unrank G K required rank1: composition at one-based BI rank; invalid, zero, or out-of-range rank -> [].
- qa.cp.ask.allowed G K required: pure nonempty-domain predicate. This QA module never calls ASK; future integration must check this gate before ASK(2,21).

For K=1 with an internal prefix, the input is valid but the domain is empty: a one-part composition has no internal prefix. Count is zero; rank/unrank return []; ASK is not dispatched.

## Independent breakpoint model

For a positive composition p=(p1,...,pK) summing to G, define breakpoints c_i=p1+...+p_i, 1<=i<K. Then 1<=c1<...<c_(K-1)<=G-1. This bijection preserves lexicographic order between part vectors and breakpoint tuples.

Thus:
- no required prefix: N=C(G-1,K-1);
- required internal prefix r: fix breakpoint r, remove it, and map other x to x if x<r, else x-1. This is an order-preserving bijection to (K-2)-subsets of {1,...,G-2}, so N=C(G-2,K-2) for K>=2, and N=0 for K=1.

The Logo candidate ranks subsets using the hockey-stick block formula:

rank(S)=1+sum_i [C(n-s_(i-1),m-i+1)-C(n-s_i+1,m-i+1)], with s_0=0.

Unranking binary-searches the next lexicographic block. When m>n/2, complement subsets are used and the rank order is reversed: rank(S)=C(n,m)-rank(S^c)+1. Binomials use BI multiplication and exact division, checking every remainder. Count/rank arithmetic uses BI, not floating-point values or modular reduction; the binary-search midpoint operates only on bounded small coordinates. The largest production count is C(136,16)=261429178502421685800, greater than 2^64-1 but below the 127-bit ASK modulus nr.M. The component imposes no modular cap.

## Independent oracle and tests

qa/logo_cutlet_partition_oracle.py uses Python integers and itertools.combinations; it does not load or execute the Logo candidate or test/normative_reference.logo.

Host exhaustive audit: G=1..12, all K, and required=-1 plus every internal prefix:
- 650 domain/count comparisons
- 4,095 compositions
- 66 empty domains
- 24,576 lexicographic index and inverse checks
- zero mismatches

Native small shard: exhaustive G=1..8, all K/prefixes: 204 domains, 1,024 valid rank/unrank pairs, plus invalid input and empty-domain gate cases.

Native large-boundary shard: G={6,71,137}, K={6,17} where valid, and required={-1,1,floor(G/2),G-1}: 20 domains and 84 rank/unrank pairs at first, second, middle, penultimate and last ranks. This includes counts above 64-bit range at G=137,K=17.

Host and Native markers are distinct. Native acceptance requires both shards at the same QA commit SHA, exact counts, no Logo error markers, and retained logs/fixtures/SHA-256 manifests. Host PASS is not Native PASS; component PASS is not whole Stage 2 acceptance.

## Locks

- src/exact_integer.logo blob: f2c1a8aa5822423402cd5825255891183f0fc83c
- src/stage02_context.logo blob: f8451359e6ddcf38bb823ff2b78c9acbfbcf7830
- UCBLogo 6.2.5 source commit: a0215433f07384e4c42fe247525867f11e6f32f7
- Native shard timeout: 900 seconds; Actions job timeout: 25 minutes.
- Only QA files and a QA-only workflow are added. No cross-branch implementation/fixture is reused.
