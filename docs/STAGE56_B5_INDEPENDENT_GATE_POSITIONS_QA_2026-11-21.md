# Stage56 B5 independent Scroll gate-position comparator (QA only)
PROJECT_ID: PC-BRANCH-PHP-MALAY
Authorized branch: PHP+Bahasa-Melayu
Parent SHA: b6237c384854a401522db0b3719738ec38a5a614
Date: 2026-11-21

## Missing subgate addressed
The prior SHA ran the pinned external Python gate exporter successfully: 27 positions for indices -12..14 and three adjacent years, with source/JSON SHA, ZIP CRC and 271 independent semantic tuples. That did NOT independently reproduce every gate position. Run #44922742206 has now completed/success 30/30 at the parent SHA; that success does not certify Stage56.

The new independent verifier invokes ReferenceGateTable.position(index) for each gate, deriving values by the Scroll-derived reference-oracle gateGap/sauce calls, NOT by reading the external Python gate map. It reads only a clean canonical checkout at cc2cf0b422757a5e7c33218ce30cffa8f99c6786, checks source origin, exact HEAD, Git byte equality and independent reference-oracle SHA256 21c103d3540eb5481445a190cef98f2628de7eb90b7240879fede0d519cf4a95, checks the gate artifact SHA sidecar, exact scenario calculation_jdn=-13334246, external source/reference identities, 27 gate indices and all six year endpoints, then requires every position to match independently. Any mismatch fails with exit 2 and produces no PASS report. The output report is created only on successful completion and explicitly marks PHP profiles=0, Stage56 accepted=false.

Implementation: tools/stage56_verify_independent_gates.mjs. Negative comparator tests: tests/stage56_independent_gates.test.mjs. CI step runs inside the existing external-reference-differential job after gate export, with timeout 1200 seconds; retains stdout/stderr/exit/report alongside existing per-run SHA evidence. The local tests exercise only the injected comparator (synthetic), not the canonical source itself.

This is a QA-only oracle-strengthening change. It does NOT establish a PHP-authenticated production source callback, a PHP structure differential, or three real 4999/5000/5001 900s/512MiB profiles. Stage56 is NOT ACCEPTED. No PATCH22/PATCH23 integration, main, merge or publication.

NEXT: inspect new SHA-bound completed CI step and ZIP artifact for exact independent 27-position match. Then implement a fail-closed PHP QA adapter over independently authenticated source-bound witness callbacks, verify PHP-owned structure against Scroll, and conduct three resource-bounded real-year profiles; keep separate provenance and gate statuses.
