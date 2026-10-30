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
