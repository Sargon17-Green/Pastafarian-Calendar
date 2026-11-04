# Stage02 DISCOVERY01 — independent WAT differential QA (2026-11-04)

**Project:** `PC-BRANCH-WAT-SPANISH`; **branch:** `WAT+Español`. This is a continuation of the same investigation and not a new Stage. Input HEAD verified as `062552cabc9bcca8465108b1f55b269a8b68c1d9`; no edit to WAT, no main/merge.

## Source identity

- Git blob of the actual executed WAT: `2b67a790162f9e0e08644d501a90344e2d3b1c0d`.
- SHA-256: `2a8ff56939bd25986a8ef7c062d9c99dc18ea11f5a860b1e22d1df956e42cc42`.
- A temporary Google Docs text export had introduced a BOM and extra blank lines. These were reversed and the recovered bytes were **verified by both the Git blob SHA and SHA-256** against the committed source before execution. The exported text was not taken as an independent source.

## Differential design (independent production big-integer oracle)

For `M=2^127−1` and `S=M³`, take input `first∈[1,M]`, `step∈{-1,+1}` and `M²<N≤S`. The independent Python oracle computes the three base-`M` response digits, `x=1+Σ(d_j M^j)`, `q=⌊S/N⌋`, `L=qN`, then returns the first accepted circular value: `x` for `x≤L`, `1` when `x>L,step=+1`, or `L` when `x>L,step=-1`. Expected rank is `1+((accepted−1) mod N)`. Values are calculated from Python integers and embedded literally as base-`2^30` limbs into fresh exported WAT functions. The WAT under test does **not** calculate its own expected answers.

A temporary copy of the original WAT was extended with 35 ephemeral exports, each calling the original `$choose` end-to-end and comparing the exact multi-limb result to the independent literal oracle. The committed WAT remained unchanged. Six windows, for `q=1,2,3` and both step signs, varied `first∈{1,⌊M/2⌋,M−2,M}`; this produced 24 cases. Eleven further legal boundary cases used `x=L` (5) and `x=L+1` (6). The exact `q=3, step=+1, x=L` boundary could not be constructed in the searched admissible candidate family and was **not counted** as tested.

For a negative-control export the expected literal rank was deliberately increased by 1. It must produce `i32(0)` to confirm that a wrong answer does not appear as a PASS.

## Fresh Native evidence

- Runtime: `wasmkit 0.1.6`; one independent process per export, **30-second timeout per process**.
- **35/35** positive differential cases PASSED: stdout exactly `[WasmTypes.Value.i32(1)]\n`, exit 0, empty stderr, zero timeouts/traps.
- **1/1** deliberate negative control PASSED: stdout exactly `[WasmTypes.Value.i32(0)]\n`, exit 0, empty stderr.
- Positive breakdown: `q=1: 12`, `q=2: 12`, `q=3: 11`; `step=-1:18`, `step=+1:17`; **19 rejection paths** and **16 initially accepted paths**. All ranks were within `[1,N]`.
- 36 processes in total; accumulated process elapsed time 1.8531s; longest process 0.092117s; no process exceeded its 30s limit.
- The QA runner compiled with `python3 -m py_compile`; its SHA-256 is `500dca61c22131374834df7feeb3dfccfdc67a4cce8b6d5a2388f9b59358c426`. The complete 35+1-run JSON's SHA-256 is `51461964a87829a7a1f4976b4236b312761d7421184af7db2f6e847b978f8e4e`. Local reproducible artifacts are preserved in the task conversation; these hashes permit verification of any later copies. The generated (temporary) WAT SHA-256 is recorded inside the full JSON.
- The 28/28 original Native gate was already verified on the same WAT blob in the preceding task and was **not unnecessarily re-run**.

## CI and stage status

The linked GitHub Actions commit-workflow query returned no PR-triggered runs for this HEAD, and combined commit statuses were empty. **This does not prove that no push-triggered CI exists.** No `completed` run/job log on this exact HEAD was verified in this session, so **no GitHub CI PASS is asserted**.

The branch remains **OPEN / READY**. No `EXPECTED_RED`, no historical defect reproduction, no `Stage02 PASS` declaration. This report is a Native/differential QA acceptance for the 35 new cases only.

**NEXT:** inspect a completed GitHub Actions run/job log for the current HEAD through a channel that enumerates push runs, verify checkout SHA and scope; then assess remaining DISCOVERY01 contract criteria and source/provenance coverage, decide whether additional boundary cases or a separate full-semantic CI workflow are needed, without merging to main.