# ዜና ዘመን — stage ledger

| Stage | Kind | Status | Note |
|---|---|---|---|
| 1 | BOOTSTRAP | IN_PROGRESS | SM83 exact primitives, 122 native ROM smoke cases, scratch leases, bounded work counters and length normalization; full calendar absent |
| 2 | DISCOVERY_01 | NOT_STARTED | Must preserve intentional historical wrong behavior |
| 3 | PATCH_01 | NOT_STARTED | Must retain Stage 2 scar as diagnostic copy |
| 4..53 | DISCOVERY/PATCH | NOT_STARTED | 25 further discovery/patch pairs |
| 54 | FINAL_INTEGRATION | NOT_STARTED | Historical live routes, no shortcuts |
| 55 | FINAL_AUDIT | NOT_STARTED | Native hardware/emulator and independent differential verification |

No code from another programming-language branch has been copied into the
SM83 production runtime. No future stage is marked complete or bypassed.

## Candidate extension — 4096-byte magnitude comparison

The unsigned, fixed-capacity SRAM compare subroutine was added alongside
seven new native tests (cases 34..40). No calendar semantic stage has been
marked complete, and the 40-case smoke subset passed native CI (run 38686711132).

## Signed comparison candidate

Stage 1 extension adds canonical signed-magnitude comparison plus ROM
tests 41..52. The historical 55-stage route is unchanged. Native QA passed in
GitHub Actions run 38691700266 (52/52 ROM cases); Stage 1 remains open.

## Candidate: exact signed SRAM sum

Added a fixed-capacity `SignedAdd4096` primitive, using existing unsigned
addition/subtraction/compare and a reversed subtraction path for cases in
which |B|>|A|. Invalid signed encodings fail closed. Native ROM cases
53..66 passed native CI in run 38781963706 and remain a bootstrap subset only. Stage 1 remains IN_PROGRESS until
the normative calendar and full source-language catalog are independently
verified.

## Stage 1 scratch SRAM bank leases — candidate

A separate MBC5-native scratch allocator leases 13 SRAM banks after
reserving banks 0..2 for existing arithmetic. The 14 ROM cases 67..80 passed natively in Actions run 38788682300. This is not the final semantic-state owner or
unrestricted BigInt allocator; no historical discovery/patch work starts.

## Stage 1 bounded day-count implementation — candidate

The first normative numeric calendar operation now has native SM83 code
for signed 32-bit offsets from Foundation, preserving exact even/odd
mapping in a 5-byte output. Cases 81..92 subsequently passed native verification in run 38789386350.
The narrow input is explicit, so the historical stages and full oracle
remain unclaimed.

## Verified bounded Day Count subset

Native cases 81..92 passed under PyBoy in run 38789386350. This numerical subset is not Stage 1 completion.

## Five bounded numeric counters — Stage 1 candidate

Paired signed-32 Foundation offsets now flow through native SM83 counters. Full arbitrary-precision counters, sauce, gates, selection, weaving and calendar date construction remain unimplemented. Native tests 93..108 subsequently passed in run 38790223535.

## Verified 108-case numeric bootstrap

Bounded day-pair counters passed DMG-native run 38790223535. Stage 1 remains IN_PROGRESS pending unrestricted arithmetic, full normative oracle and Classical Ge'ez catalog. Historical DISCOVERY/PATCH sequence remains untouched.

## Candidate: explicit canonical length metadata

Stage 1 adds a non-mutating MBC5 SRAM magnitude-length scanner and a
two-byte canonical length field on successful signed addition, including
carry into byte 4097. Invalid encodings zeroize the length metadata
before returning failure. ROM cases 109..122 passed native CI in run 38794654298.
No historical DISCOVERY/PATCH stage is started.
