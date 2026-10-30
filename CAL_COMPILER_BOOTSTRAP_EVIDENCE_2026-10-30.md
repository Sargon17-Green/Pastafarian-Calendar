# CAL bootstrap provenance and security gate — 2026-10-30

Project: `PC-BRANCH-PLAIN-ENGLISH-PROGRAMMING-ENGLISH`
Branch: `Plain-English-Programming+English`
Status: **SOURCE REVIEW IN PROGRESS / NATIVE EXECUTION BLOCKED**.

## Why the previous executable cannot be accepted

The Windows host `ELIEZER-GREEN-2` quarantined the previously used
`cal-4018.exe` under Defender detection `Trojan:Win32/Zpevdo.B`.
Separately, the original `cal-4700.zip` mirror copied from
`elenderg/PAL-1000` revision
`2d44defdedf24519bba754114ee66e6d1defff1e` was downloaded with SHA-256
`A1E7B9D96373562AEE7E1CBC8EBB5FCC237C46EB6D621FCF69D532FB8DE14165`.
Its recorded EXE length and CRC32 (831,488 bytes, `065DDF49`) disagree
with independently inflated content (831,515 bytes, `7515BE6E`).
That inflated content SHA-256
`D5D15179E7A07D7A8194C72B60473F28C1610CFAAEB6CC37BE9FAF3D43288614`
exactly matches the file installed by v5; the discrepancy originates in
the archive's bytes, not an observed subsequent on-host alteration.

These are integrity and quarantine facts, **not a malware verdict** on
the CAL-4700 executable. Neither binary is approved for execution.
The CAL branch's 99 Native groups and 47-month case remain unverified.

## A source-only recovery path was located

The repository `elenderg/PAL-1000`, at the pinned revision above, has
**two distinct Plain English source sets outside the broken ZIP**:
`recursos/CAL-4700/` and
`Documentação/Passo-a-Passo para Compilação/cal-4700 passo08/`.
They do **not** share an identical source tree. Git blob SHA-1 identifiers
are object IDs for immutable source retrieval, **not malware clearance**.

| Source file | `recursos/CAL-4700/` blob | `passo08/` blob |
| --- | --- | --- |
| the compiler | `810bdc58ba41e611fc0ba0b53f467d842dcb1bb1` | `d8da5ace27c8131fa152312b4262e5792d0d4898` |
| the desktop | `15090a299ff82572f9a5e95af2c95a054edb0139` | `357091dfdbf125222e218b8e5aeb90dc19275ca5` |
| the editor | `25df723faf8e65e78b0c8a5bdd28330720907dbd` | `25df723faf8e65e78b0c8a5bdd28330720907dbd` |
| the finder | `660357bcec832f28059a950b264e20381dc997d6` | `660357bcec832f28059a950b264e20381dc997d6` |
| the noodle | `571e3624d83fe531e15b76be6e1168d64a06f71f` | `336046e46f11bb8fde696d54588071bf86e994a5` |
| the writer | `460c77888767a49ef6f73f611e82101c04ba09e1` | `460c77888767a49ef6f73f611e82101c04ba09e1` |

**Do not mix files between sets.** One alternative copied within the same
repository at `recursos/O'Mail/cal-4700/` also matches the
`recursos/CAL-4700/` compiler blob; that is an intra-repository duplicate,
not independent verification of clean compilation.

## The documented eight-stage build is not a trusted bootstrap

The text
`Documentação/Passo-a-Passo para Compilação/instruções de compilação em inglês.md`
(Git blob `c7fe98e764fe1ff4584a93645145956f1014041e`) begins its
instructions with **"Start up the CAL-4700.exe."** It explicitly assumes
a previously working executable. It documents self-hosting and stepwise
source changes; it does **not** establish a clean, independently trusted
stage-zero build or reproducible machine code.

The separate `Folds/osmosian` repository, pinned at
`062b969eaf0eb78d3a81f61f01199c79d8f716de`, contains
`the compiler` (blob `26b612b3a12a032c42a41b3652c7ed0ce4433796`)
and `cal-3040.exe` (blob `d1b18fabe1247a67d6831a258c350eefaab73a64`).
The latter is a **candidate to audit**, not a trusted stage-zero binary.
`Folds/english` has a syntax-compatible fork but its `cal-4018.exe`
is the already-quarantined seed in this project's prior history.
CAL-4700 sources bear Osmosian Order copyright; source visibility alone
does not settle permission to redistribute or relicense them.

## Acceptance gate and next actions

1. Keep the quarantined CAL-4018 and unverified CAL-4700 unexecuted.
2. Preserve the exact single-source-set manifest above. Do not copy
   any executable into the project, add Defender exclusions, or silently
   treat a checksum as a security approval.
3. Obtain an independently validated compiler/bootstrapping method, or
   conduct a separate source review plus controlled *offline isolated*
   stage-zero evaluation with explicit authorization. A bootstrapping
   claim needs a verified stage-zero provenance and reproducible
   stage1/stage2 comparison, not just a source screenshot or repository.
4. Only after the security gate is lifted: minimal syntax smoke test,
   99 Native groups, 47-month differentiation, then full/soak.
5. Record measured compile logs, outputs, binary hashes, and safety
   evidence; do not invent a Native PASS.

This file is **documentation only**. No executable was downloaded,
compiled, restored, whitelisted, or run during this source inventory.

## Static comparison: why `passo08` is not a drop-in release source

A direct, **text-only** examination of both pinned `the compiler` files
yielded:

| Measurement | Standalone `recursos/CAL-4700/the compiler` | Tutorial `passo08/the compiler` |
| --- | ---: | ---: |
| Source text lines | 4,390 | 4,391 |
| Active top-level `To ...:` definitions | **441** | **224** |
| Commented-out top-level `\\To ...:` definitions | **0** | **217** |
| All comment-leading lines | 21 | 1,906 |

These counts are lexical source counts (not a successful compile).
They demonstrate that the tutorial's final `passo08` file is deliberately
partly disabled and should **not** be substituted for the full compiler
source or mixed with `recursos/CAL-4700` runtime components. No claim is
made that the standalone source is independently audited or that it can be
bootstrapped without a trustworthy seed.

## 2026-10-30: executable-free source provenance gate implemented

New project-owned, Python-standard-library-only files on this branch:

- `tools/cal_source_provenance.py`: fetches **only** the six exact text files in
  each of the `release` and `tutorial_step08` source sets from pinned
  `elenderg/PAL-1000` commit `2d44defdedf24519bba754114ee66e6d1defff1e`.
  It validates Git blob SHA-1 and file byte length against a fixed 12-file
  manifest. It rejects wrong source paths, executable/ZIP magic, oversize
  files, mismatched hashes, symlinks in offline-directory mode, and redirects.
  It generates JSON but **does not compile anything or run any executable**.
- `tools/test_cal_source_provenance.py`: seven isolated unit tests.
- `.github/workflows/cal-source-provenance.yml`: narrowly scoped
  `contents: read` CI for unit tests and the pinned-source audit. It invokes
  only Python; it never invokes or downloads any CAL binary.

Observed evidence **in this development session**: seven tests passed on
the locally authored Python implementation; GitHub's file-content API
returned all 12 pinned text files at their expected Git blob SHA-1 IDs;
the branch contains all three added files. A completed GitHub Actions
job and its exit status have **not** yet been independently observed.
The two source sets are distinct and must not be mixed.

To run the harmless offline unit tests from the branch:
`python3 -m unittest discover -s tools -p 'test_cal_source_provenance.py' -v`

To retrieve and verify only pinned text sources:
`python3 tools/cal_source_provenance.py --fetch --output cal-source-provenance.json`

Passing source provenance establishes **byte identity only**. It neither
approves an unknown compiler executable nor supplies a trusted stage-zero
bootstrap. CAL-4700 and the quarantined CAL-4018 remain blocked, the
47-month discrepancy remains unresolved, and the 99 Native QA groups
remain unverified.


## 2026-10-30: offline verifier hardening and CI visibility

Follow-up code on the same branch:
- \`tools/cal_source_provenance.py\` now checks each source-path
  component for symlinks (including the source-set directory),
  rather than checking only the final file.
- After any source audit failure, a requested JSON report is replaced
  with \`all_12_text_sources_verified: false\`; a stale previous
  successful report must not masquerade as new evidence.
- \`tools/test_cal_source_provenance.py\` now contains **ten** offline
  tests, including an actual 12-file end-to-end directory-mode
  integration test and explicit symlink/failure-report regression tests.

**Measured locally**: \`python -m unittest discover -s
/mnt/data/cal_bootstrap_tools -p 'test_cal_source_provenance.py' -v\`
finished with 10/10 tests passing, using equivalent code under review.
This is a local Python test, not proof that GitHub Actions ran.

**GitHub Actions visibility**: the GitHub API reported zero workflow
runs for this feature branch and zero combined commit statuses for
\`618cac5e5190042c9c37089e9a109b8ef8c0a6dc\` at time of
inspection. The source-only CI workflow exists but **must not be marked
PASS** without a job/run log. The reason the push did not yield a
visible run is not verified. The workflow is explicitly restricted
to fetching Plain English **text**, not downloading/executing CAL.

No change to the project's 82 source files. Security gates remain:
CAL-4018 quarantined, CAL-4700 ZIP-integrity mismatch unresolved,
no Native QA PASS and no compiler execution authorization.


## 2026-10-30: source HTTP guard tests and unresolved Actions triggering

This follow-up added three further **offline** tests to
`tools/test_cal_source_provenance.py`:

1. Verify `urlopen` is called with the exact commit-pinned text-source URL
   and a bounded read.
2. Reject a redirect to a different URL before reading its payload.
3. Reject an oversized source response.

The local Python test suite finished **13/13 PASS** in this session
(`python -m unittest discover -s . -p test_cal_source_provenance.py -v`).
The branch version contains 13 tests; GitHub CI has **not** provided a PASS.

GitHub repository metadata confirms the default branch is `main`, and
`.github/workflows/cal-source-provenance.yml` is **absent** there (404).
Per GitHub's official workflow dispatch rules, the branch-only workflow
is not eligible for manual `workflow_dispatch`; this explains why no
manual dispatch control can be assumed, but does not by itself explain
why the configured `push` event produced no visible run.
The API still reports **zero** Actions runs for this feature branch,
including after the test-file change. Root cause of the absent push run
is **UNCONFIRMED** (possible repository/token/event/permissions issue).

No workflow or compiler code was merged into `main`; no untrusted CAL
binary was executed. Git provenance does not constitute malware
clearance. The stage-zero compiler and Native 99-group QA gates remain
blocked.


## 2026-10-30: dual-hash verification of actual GitHub source bytes

A separate byte-oriented inspection of all twelve source files from
`elenderg/PAL-1000` at pinned commit
`2d44defdedf24519bba754114ee66e6d1defff1e`
recomputed Git's `blob <length>\\0<content>` SHA-1 over the original
byte values. **12/12 matched the expected Git blob IDs.**

The same inspection independently computed source-byte SHA-256 for each
file; those twelve digest constants are now explicitly pinned in
`tools/cal_source_provenance.py` under `EXPECTED_SHA256`.
For a source to be accepted the verifier now requires all three checks:
**exact byte length + Git blob SHA-1 + source SHA-256**. Its lexical
analysis uses a reversible ISO-8859-1 mapping, avoiding replacement of
legacy 8-bit characters during text inspection. Hashes always operate
on the original bytes, not a newly UTF-8-encoded string.

`tools/test_cal_source_provenance.py` now has **14 offline unit
tests**, including a test in which byte length and Git blob hash agree
but the pinned SHA-256 is deliberately wrong. The local Python suite
completed **14/14 PASS** using the updated implementation. The source
retrieval/hash comparison was performed through the GitHub connector
and an independent JavaScript SHA-1/SHA-256 implementation with
known-answer self-tests; this **does not constitute a GitHub Actions
job result**.

Actions API still reported **zero** runs for the feature branch at
`4299ceb952b0011c03afcdce68cac90a86e3d0be`.
GitHub's documentation confirms that `push` workflows may trigger on
branches even before merge to the default branch, whereas manual
`workflow_dispatch` requires presence of the workflow file on the
default branch. Therefore the branch-only workflow location is **not**
a sufficient explanation of zero `push` runs. The actual reason has
not been verified and no CI PASS is claimed.

No CAL executables were run, and the 82 existing calendar source
files were not modified. Neither the CAL-4700 binary that mismatches
its ZIP manifest nor the quarantined CAL-4018 is approved to run.
The 99 Native QA groups remain unexecuted.
