; Stage 1 — deterministic scratch-SRAM bank leases on original DMG MBC5.
; Banks 0..2 are permanently reserved for fixed-width arithmetic operands
; and its result. Banks 3..15 form 13 independent 8192-byte scratch slots.
; All operations need SRAMEnable, and must be called with interrupts disabled
; (or with a caller-provided serialization guarantee). No host CPU involved.
;
; LeaseResetAll: DESTRUCTIVE reset: scrubs all 13 scratch banks, reserves
; 0..2, clears all outstanding leases. Do not call during a live invocation.
; LeaseAlloc: returns the lowest free bank in wLeaseBank, or FF on exhaustion;
; clears all 8192 bytes before returning a successful lease. Status 0/1.
; LeaseFree: input A=bank; validates 3..15 and active lease, wipes all 8192
; bytes before making it reusable. Status 0=success,2=invalid bank,
; 3=unleased/double free. Invalid requests do not change mapped SRAM.
; No released bank is ever exposed by LeaseAlloc without zeroization.
; These are bank leases, NOT variable-length BigInt ownership yet.
SECTION "MBC5 scratch SRAM leases", ROM0

; A = SRAM bank (3..15 for allocator use); selected bank on return.
; Clobbers A/BC/HL; also suitable for explicit reset of free banks.
SRAMZero8KiB::
    call SRAMSelectBank
    ld hl, $a000
    ld bc, 8192
.loop:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

LeaseResetAll::
    ld hl, wLeaseTable
    ld b, 3
    ld a, 2
.reserve:
    ld [hli], a
    dec b
    jr nz, .reserve
    ld b, 13
    xor a
.free:
    ld [hli], a
    dec b
    jr nz, .free
    ld a, 3
    ld [wLeaseIter], a
.wipe:
    ld a, [wLeaseIter]
    call SRAMZero8KiB
    ld a, [wLeaseIter]
    inc a
    ld [wLeaseIter], a
    cp 16
    jr c, .wipe
    xor a
    ld [wLeaseStatus], a
    ld a, $ff
    ld [wLeaseBank], a
    ; A destructive reset invalidates every previously selected owner handle.
    ld [wOwnerSelectedBank], a
    ret

LeaseAlloc::
    ld hl, wLeaseTable + 3
    ld c, 3
    ld b, 13
.find:
    ld a, [hli]
    or a
    jr z, .claim
    inc c
    dec b
    jr nz, .find
    ld a, 1
    ld [wLeaseStatus], a
    ld a, $ff
    ld [wLeaseBank], a
    ret
.claim:
    dec hl
    ld a, 1
    ld [hl], a
    ld a, c
    ld [wLeaseBank], a
    call SRAMZero8KiB
    xor a
    ld [wLeaseStatus], a
    ret

LeaseFree::
    ld [wLeaseIter], a
    cp 3
    jr c, .invalid
    cp 16
    jr nc, .invalid
    ld c, a
    ld b, 0
    ld hl, wLeaseTable
    add hl, bc
    ld a, [hl]
    cp 1
    jr nz, .notLeased
    ld a, [wLeaseIter]
    call SRAMZero8KiB
    ld a, [wLeaseIter]
    ld c, a
    ld b, 0
    ld hl, wLeaseTable
    add hl, bc
    xor a
    ld [hl], a
    ld [wLeaseStatus], a
    ld a, $ff
    ld [wLeaseBank], a
    ret
.invalid:
    ld a, 2
    ld [wLeaseStatus], a
    ld a, $ff
    ld [wLeaseBank], a
    ret
.notLeased:
    ld a, 3
    ld [wLeaseStatus], a
    ld a, $ff
    ld [wLeaseBank], a
    ret
