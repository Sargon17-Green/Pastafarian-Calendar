# Stage56 B5: external gate witness exporter, QA-only (2026-11-21)
PROJECT_ID: PC-BRANCH-PHP-MALAY
Authorized branch: PHP+Bahasa-Melayu
Parent HEAD: ad44b6cce7d2a77bb80a00b29727b3d833cefa6c

New source: tools/stage56_export_external_gate_witness.py

This is a new, source-pinned **external boundary-witness exporter**, not PHP
production-year output and not an independent Scroll oracle. It requires:
a clean exact pinned checkout of Sargon17-Green/pastafari-calendar
@cc2cf0b422757a5e7c33218ce30cffa8f99c6786, canonical Python and
adjacent JS Git-byte hashes, a SHA-256-pinned *external reference-only* JSON,
and explicit calculation_jdn. The output is written outside the checkout and
retains the source provenance, contextual Year5000, three year boundaries,
every gate index/day and exact input digest. It checks the original external
month lengths and weaving against the executed pinned Python source and
rejects years whose gate endpoints/contiguity disagree. No PHP claim is made.

Reproducible reference scenario: calculation_jdn=-13334246 and external
reference SHA256=46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880
(from earlier accepted reference artifact; only use if identical bytes).
Invocation after verifying clean external checkout and obtaining those bytes:

python3 -B tools/stage56_export_external_gate_witness.py \
  --canonical-repo /external/clean/pastafari-calendar \
  --source-commit cc2cf0b422757a5e7c33218ce30cffa8f99c6786 \
  --calculation-jdn=-13334246 \
  --reference /evidence/reference.json \
  --reference-sha256 46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880 \
  --output /evidence/external-gates.json

Local QA (no external canonical checkout available): Python py_compile PASS,
--help exit=0, invalid source directory exit=2 with no output, and five
isolated synthetic interface-contract tests PASS (normal boundaries, bad
context, bad source digest, changed weaving, bad gate endpoint). Local
stub implemented only the test interface, NOT the canonical algorithm.
Do not claim external source executed, Native PASS, PHP full year exports,
three actual-year profiles or Stage56 ACCEPTED from those results.

Previous exact-SHA CI #44905461392 completed/success at ad44b6cce7d2a77bb80a00b29727b3d833cefa6c
with stage56-structure-provider-native job #136849959349 completed/success.
Downloaded artifact #14708796184: SHA256
fefba4593bf4a38c164e2a07bae2c6777d0e7f3112edf63b69794da664622abe,
2353 bytes, 13/13 CRC, exit arch/lints/chooser/provider=0, stderr empty,
PHP8.3.37 64-bit, selector checks=170, synthetic provider assertions=275.
This accepts only the exact-SHA synthetic PHP provider microgate.

NEXT: run the new exporter in a pinned canonical checkout, check its
SHA/exit/stderr and exact reference comparison, then build a fail-closed PHP
QA adapter supplying those gate/year witnesses to buildVerified for real
4999/5000/5001. Independently compare structures with the Scroll-derived
oracle, demonstrate production PHP source attestation and three isolated
900s/512MiB count/rank/unrank profiles; do NOT certify Stage56 prematurely.
No PATCH22/PATCH23 integration, merge/main or publication.

## Exact-source CI execution gate (follow-up)

The authorized Canonical Names Lock workflow now runs the existing Python
gate-witness exporter **after** the canonical Python reference export has
succeeded and **before** the independent semantic differential. This is the
same immutable clean external checkout and reference JSON, not a replacement
oracle or production PHP source. The script checks exact external source
bytes, the contextual Year5000 anchor and real years; the new workflow
checks the output SHA-256 sidecar, consecutive gate indices, distances,
boundaries, all three year envelopes, exit status, stderr and checkout
cleanliness. Evidence is retained in the existing external artifact:
`external-gates.json`, `external-gates.json.sha256`,
`gates.stdout`, `gates.stderr`, `gates.exit`,
`canonical-post-gates-status.txt` and
`stage56-evidence-files.sha256`.

The workflow change is **QA-only** and does not change PHP production
providers, PATCH22/PATCH23, main, merge or publication. A green run
establishes source-bound external gate witness execution at its exact
feature-branch SHA, not independent gate oracle acceptance, not
source-attested PHP callbacks, not genuine PHP 4999/5000/5001 exports,
not 900s/512MiB profiling, and not Stage56 acceptance.

Predecessor `00247fe0a4016d60c9ab270aa31cfc95cb9fcc46`
push run #44910098924: completed/success, 30/30 jobs,
including provider PHP8.3 64-bit synthetic QA (170 chooser checks,
275 provider assertions with `synthetic=YES` and
`source_attested=NO`) and external 271-tuple independent
Scroll-derived differential. External job exported reference JSON
SHA256 `46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880`;
the new gate-witness script was *not* executed by that predecessor.
