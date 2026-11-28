# QA31BY — source-bound predecessor and altered-write conditional path

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified entry HEAD:** `ffbccadac4ad3d8b4ee7655cfd82727fbb7de14c`  
**Date:** 2026-11-21  
**Scope/verdict:** **LOCAL FINITE CONDITIONAL PATH QA PASS**. **NOT new Native, NOT CI, NOT differential acceptance, NOT Stage1 acceptance.** No production/main/Stage2 changes.

## Evidence pins and independent original-source verification

- Full immutable original Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, size **1,836,425 ASCII bytes**, fetched by exact GitHub blob SHA. Independent pure-JavaScript canonical Git-object SHA-1 (`"blob 1836425\0" + contents`) returned the expected SHA. Algorithm oracle `SHA1("abc") = a9993e364706816aba3e25717850c26c9cd0d89d` passed. This full blob was **not** saved in the local QA package. The local Python program validates a bounded separately documented source attestation rather than independently rehashing 1.8 MB; do not claim it did so.
- The original source-byte window at `x=1500`, `y=1860..1882` is ` v7a*9+1a*7+a*1+a*0+g.8`, with row 1860 length 1531 and following row lengths 1501. The original byte at `(1500,1860)` is **space (32)**, and at `(1500,1881)` is **dot (46)**; `x=1499,1501` at y1881 are spaces. These are static source bytes, not modified-run observations.
- Prior immutable QA31BW ZIP SHA-256 `a9e76afb498ab922fb5086254edf9b59c96ada07ead73ba5f1ee37726c847628` and QA31BX ZIP SHA-256 `b92945d86c03da42b611f2ec708813fa73f9a91099eb42f4de9ae57fb7ea3e7b` independently checked locally with ZIP CRC and all manifested member SHA-256 digests. No original Native traces were re-executed or fully re-walked in this QA.

## Concrete original physical anchor vs the counterfactual

For original signed case `pair_30_30`, the archived physical `p` witness at IP `(96,480)`, tick **17817**, stored integer **62** at `(1500,1860)`; the original fetch at tick **17845** observed executable ASCII `>` (62), hence its local next IP is `(1501,1860)`. This directly matches the separately verified source's initial *space* (32), demonstrating original self-modification. The corresponding original full-trace SHA is pinned in the attached machine-readable result.

**Distinct testable intervention hypothesis (not natural stdin):** In a future, separately gated experiment, at that one original `p` event replace only the stored *value* 62 (`>`) with 118 (`v`) while keeping the `p` target coordinates, execution and stack consumption otherwise identical. If the changed run still reaches `(1500,1860)` before any later overwrite, `v` points south to `(1500,1861)` instead of the original `>` pointing east. If the subsequent 21 original source cells are still unchanged when fetched and one IP traverses them without competing mutation, the 22-instruction bounded path reaches `.` at `(1500,1881)` and next IP `(1500,1882)`. On this path `g` reads from effective address `(79+SO_x,1710+SO_y)` and `.` emits its integer value, under an explicitly chosen input stack, storage offset, memory value and decimal I/O convention.

The intervention has not been run in Native. **The changed-run reachability from startup to the `p` event, effect of changing one stored value on later execution, actual next-IP, later writes, stack, storage offset, read value and output remain UNKNOWN.** No direct stdin byte string is asserted to cause the intervention. The conditional path is not a proof of global reachability. This is a new causally specified hypothesis, not a claim that existing original observations already establish its feasibility.

## Bounded predecessor and successor contract

- Target `(1500,1881)` has exactly four **local cardinal predecessor coordinates** for a single-cell, unit-vector move: from west `(1499,1881)` (eastward), east `(1501,1881)` (westward), north `(1500,1880)` (southward), or south `(1500,1882)` (northward). At the target, `.` leaves direction unchanged. This exhausts only the declared four adjacent cardinal predecessors, **not** paths using `j` or `x`, parallel IPs, wraparound, or code altered from other locations. Other paths are not excluded.
- Under the stated `p:62→118` intervention plus source stability, the local precursor is `(1500,1880)` with original `g`, and the target is reached after 22 executed opcodes (changed `v` plus original 21-character column). The original `>` case, by contrast, takes its first step to `(1501,1860)`; no original reachability of the dot is established.
- Oracle A: independently implemented bounded opcode-by-opcode IP/stack/`g`/`.` transition logic. Oracle B: closed-form arithmetic for relative `g` coordinates and preserved initial stack, next IP and emitted integer. A grid of **6 `g` values × 5 initial stacks × 4 storage offsets = 120/120** matches (including negative and nonzero SO cases). Every test is explicitly counterfactual, not a signed Native trace.
- Untouched signed-original controls: **12/12 cross-archive identities and step/SHA pins checked** (11 original fetch cases with `>`, plus **one genuine no-fetch control**), preserving the original distinction. This does **not** revalidate 12 complete trace payloads from their original compressed STEP bytes; that was earlier QA scope.
- Detached synthetic hostiles: **16/16 rejected**, covering source/project/size/hash attestation, four source mutations, writer IP/tick/value, fetch IP/opcode, control-type mislabel and wrong first successor. These are QA guard tests, not physically failing Native runs.

## Gates and next action

**PASS:** source Git-object integrity check outside local Python; bounded original archive SHA256/CRC/member manifest; twelve historical control cross-checks; four local cardinal predecessor cases; 120 conditional dual-oracle computations; 16 detached hostile rejections; local Python compile.

**UNKNOWN/OPEN:** any modified-run Native result; actual intervention feasibility; all changed-run route/memory/stack/SO/outputs; source-to-runtime global ownership; full functional/geometric gates; Stage1 acceptance. **New Native runs = 0. New CI runs = 0. No production change.**

**NEXT QA31BZ (QA-only):** create a *minimal changed-run Native interception contract* at original `p(96,480)` with unique exact-match case, tick, IP, pre-stack and target address preconditions. Require nonintrusive full original replay as control, one changed `p` value, exact receipts for both, source/stack/SO/p ledger, and a completely independent trace auditor rejecting at least 12 detached corruptions. Decide whether to dispatch native CI **only after** verifying the new probe can preserve all unchanged pre-state and identifying its exact testable divergence; do not duplicate previously accepted original CI or claim Stage1 acceptance. No merge/main/Stage2.