# Stage1 Native386 — visible V1..V46 chain

## Contract

- Source of truth: Issue #30 and the pinned README recurrence at `56bc4173aae4975ded019ef5ab5a36249f1424df`.
- Input: the active invocation's signed 32-bit calculation/target offsets, the Foundation seed state, and the seven retained hidden drops H1..H7.
- Precondition: corrected V5 and V6 predecessors are V4,V2,H3 and V5,V3,H2 respectively.
- Output: preserved H1..H7; preserved V1..V6; final V46 in `wCalendarVisibleOutput`; five-stone S46 in `wCalendarStoneOld` and `wCalendarStoneOutput`; seven-slot rolling window for the final seven visible drops.
- Iteration: for each i=7..46, advance S[i-1] to S[i], then compute V[i] from D[i-1], D[i-3], D[i-7]. The ring starts with V1..V6 in slots 0..5 and H1=D[0] in slot 6. If r holds D[i-1], the other inputs are slots r-2 mod 7 and r+1 mod 7. The consumed oldest slot is replaced only after V[i] is computed.
- Failure: return the existing status and restore the caller's previous `wCalendarVisibleOutput`; no lease, ordinal-offset, or SRAM mutation is intended.
- Oracle: `tests/test_sm83_stage1_sauce_oracle.py` independently computes all 46 visible residues. `tests/test_sm83_stage1_visible46_abi.py` checks 72 pairs including signed32 endpoints, c<t, c>t, and the ten source-derived fixture pairs.
- Native386: test case 386, result A5, dispatch status 0x40, no more than 30,000 observed frames; verify H1..H7, V1..V6, V46, final seven-slot ring, S46, offsets, owner/lease, negative zero, idle rejection and SRAM sentinel/cleanup.
- ROM0 budget: at least 10 free bytes. The default 370-case / 9,000-frame route remains unchanged.

## Foundation expected postconditions

- V46: `1a90879100b953b0aec73f9eb1b3bb6a` (little-endian).
- S46, five 16-byte residues:
  - `7ea3820d7501346b0d09384a05428537`
  - `2df5f927ee029d27d0c37681b565496f`
  - `4dad0e0a3df84f3f1b93fd142ff21747`
  - `e27e256aae03c30ec0bd3853be439b51`
  - `ea987ad76b39bb86a32fcf71c2a52a67`

## Execution state

The implementation and tests are committed, but Native386 has not been executed or accepted. Push-triggered run 44960737740 was created on exact SHA `5dae507ce8eb5c3bdae5a2cbd32d536112002e7d`; it was queued at the last readback, so it is not PASS. Do not label Native386 PASS until that exact-SHA run completes and provides the job log and ROM artifact.

## Next

After Native386 is accepted, implement the six simultaneous bowl updates using the previous six-bowl snapshot for every i, then retain the 12 post-stir S_r values for order/u, followed by A0 and direction. This document does not claim those later gates.
