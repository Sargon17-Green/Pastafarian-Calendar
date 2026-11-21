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
