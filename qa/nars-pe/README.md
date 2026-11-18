# APL+Deutsch — exact-version NARS2000 PE structural audit

The analysis program `inspect_pe.py` reads but does not execute its input. By default it refuses all input except the official NARS2000 0.5.14.11 Windows x64 installer with exactly **9,430,788 bytes** and SHA-256 `28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b`, independently observed on prior Windows v20 and at official URL in CI. The upstream executable is unsigned, so the observed hash is an identity lock, *not a publisher signature*.

Run `python -m unittest discover -s qa/nars-pe -p 'test_*.py' -v` to test the parser. Then, for an authenticated exact-file copy, run `python qa/nars-pe/inspect_pe.py NARS2000-0.5.14.11.exe --out pe_structural_evidence.json`.

The parser validates DOS/PE headers, section geometry, file overlay, resources and heuristic nested-file signatures. Found signatures, resources, or embedded PE headers are **not** proof of a working extractor or an unattended APL command interface. It does not write to the analyzed executable or extract/execute any payload. It will never report Stage1 PASS.

Scope: QA branch only, source APL+Deutsch remains pinned to `7161824b9fcbfaca91f20d1ea492417e77003ff4`. Pending outcome of the independent Windows download workflow, a verified copy may be inspected locally, without additional installer runs. Native NARS2000, LX startup and `RunStage01Tests` remain NOT_RUN.
