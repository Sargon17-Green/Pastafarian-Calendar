# SM83 Stage 1 — case-by-case source assertion audit (Native 191–261)

**Audit date:** 2026-11-06. **Project:** PC-BRANCH-SM83-ASSEMBLY-GEEZ. **Branch:** `SM83-Assembly+ግዕዝ`.
**Starting HEAD:** `78993e7d41c331543eaa32469d33b4e43a292890`. **Scope:** 71 numbered Native cases (191–261), not 191–283.

## Verdict and evidence limits

- Static source audit: 71/71 case IDs are traced to their assertion sites; a two-result case (198) and the shared dispatch loops (252–255, 259–261) are accounted for separately. Status values below are the **expectations embedded in the ROM test harness**, not independent proof of their correctness.
- Concrete gap: cases 191–202 previously made 13 result-only assertions without checking their descriptor/tag immutability at the comparison point. The accompanying change replaces all 13 with `OwnerCmpTestExpectResultSnapshot`, which snapshots exactly ten descriptor bytes and all 16 ownership tags before calling `OwnerSignedCmp`, then checks the result and unchanged snapshot. No production routine is modified.
- The patch removes an estimated 39 bytes of ROM0 instructions in total (13 sites × 3 bytes saved). This is a static size estimate only; an actual linked ROM0 measurement is required.
- The Host Python-integer model and prior CI cover multiple comparison and owner-boundary classes, but **exact independent Host-value fixtures for each of these 71 source cases have not been established by this audit**. The Native source expectation and Native PASS on the earlier SHA are not two independent semantic oracles.
- SRAM payload evidence is not uniform: cases 191–202 now snapshot descriptors/tags but still have no per-comparison SRAM sentinel check; later cases use dedicated checks where owners remain live, while revoked-owner cases intentionally avoid invalid owner reads. Full Stage 1 exit is **NOT accepted** by this audit.

## Case-by-case source expectation inventory

Status: `0=EQ`, `1=A>B`, `2=A<B`, `3=INVALID`; case 198 has two checks (before and after release). `L` is the source line in the **patched** ASM file. The descriptions below are derived from the in-source test markers.

| Case | Expected result(s) | Source line | Source scenario marker | Native assertion scope |
|---:|:---:|:---:|---|---|
| 191 | 0 | L69 | canonical zero, two independently owned operands. | result + 10B descriptors + 16 tags (new) |
| 192 | 2 | L76 | compare highest byte at logical 8192, fragmented A. | result + 10B descriptors + 16 tags (new) |
| 193 | 1 | L111 | two negatives reverse the magnitude ordering. | result + 10B descriptors + 16 tags (new) |
| 194 | 3 | L121 | negative zero is forbidden even if its owner is valid. | result + 10B descriptors + 16 tags (new) |
| 195 | 3 | L138 | leading zero makes a noncanonical 8193-byte operand. | result + 10B descriptors + 16 tags (new) |
| 196 | 3 | L160 | length beyond the two owned banks must fail closed. | result + 10B descriptors + 16 tags (new) |
| 197 | 2 | L171 | equal high bytes force comparison of bytes at bank boundary. | result + 10B descriptors + 16 tags (new) |
| 198 | 0→3 | L207 | equal operand bytes; after release, invalid ownership. | result + 10B descriptors + 16 tags (new) |
| 199 | 2 | L222 | canonical +0 is smaller than a nonzero positive magnitude. | result + 10B descriptors + 16 tags (new) |
| 200 | 2 | L245 | a nonzero negative magnitude is smaller than canonical +0. | result + 10B descriptors + 16 tags (new) |
| 201 | 3 | L267 | sign outside {0,1} must fail closed, even for a valid owner. | result + 10B descriptors + 16 tags (new) |
| 202 | 3 | L276 | owner ID zero must fail closed even when length is zero. | result + 10B descriptors + 16 tags (new) |
| 203 | 1 | L290 | compare must never modify operand metadata, bank ownership | result + snapshot/byte assertions |
| 204 | 3 | L290 | compare must never modify operand metadata, bank ownership | result + snapshot/byte assertions |
| 205 | 3 | L290 | compare must never modify operand metadata, bank ownership | result + snapshot/byte assertions |
| 206 | 3 | L290 | compare must never modify operand metadata, bank ownership | result + snapshot/byte assertions |
| 207 | 3 | L377 | malformed SECOND operand must not mutate either operand, | result + snapshot/byte assertions |
| 208 | 3 | L377 | malformed SECOND operand must not mutate either operand, | result + snapshot/byte assertions |
| 209 | 3 | L377 | malformed SECOND operand must not mutate either operand, | result + snapshot/byte assertions |
| 210 | 3 | L377 | malformed SECOND operand must not mutate either operand, | result + snapshot/byte assertions |
| 211 | 2 | L446 | negative nonzero A is below positive nonzero B. | result + snapshot/byte assertions |
| 212 | 1 | L463 | positive nonzero A is above negative nonzero B. | result + snapshot/byte assertions |
| 213 | 3 | L478 | B has length zero with a negative sign (negative zero). | result + snapshot/byte assertions |
| 214 | 3 | L492 | B owner zero is invalid even when B is canonical +0. | result + snapshot/byte assertions |
| 215 | 1 | L504 | positive 0x7f > canonical +0 in B. B[0] is still 1: | result + snapshot/byte assertions |
| 216 | 1 | L530 | canonical +0 in A > negative 0x7f in B. | result + snapshot/byte assertions |
| 217 | 0 | L556 | two canonical zeros compare equal even though both owners retain | result + snapshot/byte assertions |
| 218 | 1 | L578 | positive and negative descriptors may alias the same live owner. | result + snapshot/byte assertions |
| 219 | 2 | L604 | reverse the opposite signs under the SAME live SRAM owner. | result + snapshot/byte assertions |
| 220 | 0 | L620 | two negative descriptors aliasing the same live owner and length | result + snapshot/byte assertions |
| 221 | 2 | L634 | two descriptors share owner 46 (SRAM[0]=$7f), yet A's canonical | result + snapshot/byte assertions |
| 222 | 2 | L650 | reverse the same-owner zero/nonzero positions and negate A: | result + snapshot/byte assertions |
| 223 | 0 | L667 | two canonical +0 descriptors alias the SAME live owner. | result + snapshot/byte assertions |
| 224 | 3 | L684 | A is invalid negative zero; B is +127 on that same owner. | result + snapshot/byte assertions |
| 225 | 3 | L699 | reverse invalid negative zero into B, with +127 in A. | result + snapshot/byte assertions |
| 226 | 3 | L717 | same owner 46 has only two 8-KiB banks (capacity 16384). | result + snapshot/byte assertions |
| 227 | 3 | L741 | reverse the same-owner over-capacity condition into A. | result + snapshot/byte assertions |
| 228 | 3 | L757 | both operands alias live owner 46; B length=2 is noncanonical. | result + snapshot/byte assertions |
| 229 | 3 | L780 | malformed same-owner descriptor in A, canonical +127 in B. | result + snapshot/byte assertions |
| 230 | 2 | L795 | same owner 46, lengths 8192 versus 8193 across an 8-KiB bank. | result + snapshot/byte assertions |
| 231 | 1 | L822 | reverse the aliasing descriptors; positive longer A > shorter B. | result + snapshot/byte assertions |
| 232 | 1 | L838 | same owner 46, both negative. The shorter magnitude is greater. | result + snapshot/byte assertions |
| 233 | 2 | L857 | reverse the negative descriptors. Longer magnitude is smaller. | result + snapshot/byte assertions |
| 234 | 0 | L873 | same live owner 46, two negative 8192-byte descriptors. | result + snapshot/byte assertions |
| 235 | 0 | L887 | same negative descriptors at length 8193 across the bank edge. | result + snapshot/byte assertions |
| 236 | 1 | L902 | same live owner, positive 8192-byte A versus negative 8193-byte B. | result + snapshot/byte assertions |
| 237 | 2 | L917 | reverse polarity and lengths: negative 8193-byte A < positive 8192-byte B. | result + snapshot/byte assertions |
| 238 | 1 | L935 | equal 8192-byte magnitude on owner 46, positive A > negative B. | result + snapshot/byte assertions |
| 239 | 2 | L951 | equal 8193-byte magnitude on owner 46, negative A < positive B. | result + snapshot/byte assertions |
| 240 | 1 | L969 | owner 46 owns exactly two 8192-byte banks. Store a nonzero | result + snapshot/byte assertions |
| 241 | 2 | L1008 | reverse signs without changing the full-capacity shared payload. | result + snapshot/byte assertions |
| 242 | 0 | L1026 | two positive descriptors alias the same 16384-byte live owner. | result + snapshot/byte assertions |
| 243 | 0 | L1043 | the same full-capacity payload aliased by two negative operands. | result + snapshot/byte assertions |
| 244 | 2 | L1060 | same owner 46, canonical +16383-byte A against +16384-byte B. | result + snapshot/byte assertions |
| 245 | 1 | L1102 | the exact same two owner aliases, both negative. | result + snapshot/byte assertions |
| 246 | 3 | L1120 | same owner 46, A is canonical 16383 bytes; B is noncanonical 16384. | invalid + snapshot/full-capacity sentinels |
| 247 | 3 | L1156 | reverse A/B. The full-capacity noncanonical descriptor is now A. | invalid + snapshot/full-capacity sentinels |
| 248 | 2 | L1216 | same fragmented owner, canonical 8192-byte A < 8193-byte B. | result + snapshot/fragmented sentinels |
| 249 | 1 | L1237 | reverse the lengths on the same fragmented owner. | result + snapshot/fragmented sentinels |
| 250 | 1 | L1245 | negative 8192-byte A is greater than negative 8193-byte B. | result + snapshot/fragmented sentinels |
| 251 | 2 | L1256 | reverse negative descriptors; the longer magnitude is now A < B. | result + snapshot/fragmented sentinels |
| 252 | 3 | L1279 | all opposite-sign orientations with one noncanonical | result + snapshot/fragmented sentinels |
| 253 | 3 | L1279 | all opposite-sign orientations with one noncanonical | result + snapshot/fragmented sentinels |
| 254 | 3 | L1279 | all opposite-sign orientations with one noncanonical | result + snapshot/fragmented sentinels |
| 255 | 3 | L1279 | all opposite-sign orientations with one noncanonical | result + snapshot/fragmented sentinels |
| 256 | 3 | L1312 | same owner, canonical +8192 A and noncanonical +8193 B. | result + snapshot/fragmented sentinels |
| 257 | 0 | L1333 | both canonical +8192 descriptors alias owner 45. | result + snapshot/fragmented sentinels |
| 258 | 3 | L1358 | after releasing the fragmented owner, both descriptors | invalid + snapshot; revoked SRAM |
| 259 | 3 | L1378 | revoked fragmented A / live canonical owner 46 B. | invalid + snapshot/live sentinel |
| 260 | 3 | L1378 | revoked fragmented A / live canonical owner 46 B. | invalid + snapshot/live sentinel |
| 261 | 3 | L1378 | revoked fragmented A / live canonical owner 46 B. | invalid + snapshot; both revoked |

## Source guards checked in pre-commit review

- Exactly 13 direct comparisons in 191–202 were replaced; original expected result values are unchanged (`0`, `1`, `2`, `3` as applicable).
- All 71 cases map to numbered source markers; shared loop 252–255 asserts INVALID=3 with sign and length permutations, and 259–261 asserts INVALID=3 through revoked-owner permutations.
- Snapshot helper uses `wOwnerCmpOwnerA` for 10 descriptor bytes and `wLeaseTable` for 16 tags; snapshot comparison is carried out after result evaluation.
- Source content from case 203 onward is byte-for-byte unchanged by the patch.

## Remaining Stage 1 acceptance work

1. Record a completed native build/emulator run **on the new patch SHA**, including DMG header, 283/283 dispatch markers, <=9000 frames and actual linked ROM0 budget; do not reuse accepted CI for its parent SHA.
2. Build independent, case-specific Python integer/lease/SRAM fixtures for Native191–261, checking A/B owner, sign, logical length, canonical magnitude, expected result, descriptor/tag preservation, valid-bank payload sentinels, and revocation semantics.
3. Inspect whether the missing SRAM sentinel assertions for 191–202 require focused additional Native instrumentation; do not infer an actual runtime bug without a reproducible failure.
4. Do not modify `main`, merge, or begin Stage 2 before the full Stage 1 exit contract is proved.
