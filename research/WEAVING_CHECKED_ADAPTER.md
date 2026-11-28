# Checked isolated adapter — research only
PROJECT_ID: PC-BRANCH-CHAPEL-UKRAINIAN
Base source: 31a81db88d747dc8b4fd989b07a628a9a039d164; previous run 46147805254, native job 140987586428.
Selected-rank reference artifact 15265091052, ZIP SHA-256 7178d5d68bb3dcba8bd823d675aea463b7b9816f24dc199f21301e775cf626e3.

The already validated standalone adjoint kernel and current normative sparse kernel have the same transfer/transpose structure. A wrapper alone is not a reason to repeat the checked timeouts. This candidate reuses the branch-local previously finite-tested singleton/forward-window/transpose-window routines in a scratch copy only, and initializes count/unrank state once in chooseMonthWeaving. The checked production source and previous gate remain unchanged. No --fast, no Stage 6, no main/merge.

Run from the exact clean branch checkout on Ubuntu 24.04 with Chapel 2.10.0:
```sh
python3 test/weaving_checked_adapter.py --static-only --outdir /tmp/chapel-adapter-static
python3 test/weaving_checked_adapter.py --reference-zip /path/to/chapel-native-selected-rank-research-evidence.zip --outdir /tmp/chapel-adapter-evidence
```
The reference ZIP must match the historical artifact digest exactly. The finite driver checks 137 families / 991 words / 1982 directional comparisons against exhaustive multiset enumeration and independent opening/closing order constraints. Canonical root (22470 bits), rank1 = rank0 + 1, all 45 lengths and 4244 symbols must exactly match the independent prior witness. Structure and calendarDate each require separate checked execution within 240 s and 512 MiB RSS, then six-field differential. Compilation <=150 s; runtime RSS cap is distinct from compiler budget. Retain all logs, source/binary digests, OS metrics and exit codes. First failed gate stops later dependent gates; no successful marker may be inferred from an incomplete execution.

Commit deliberately skips the generic push workflow because it would repeat the unchanged failed production gate. Targeted execution is pending, not Native PASS. Original production gate remains NOT_ACCEPTED even if this isolated adapter passes.
