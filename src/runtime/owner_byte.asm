; Stage 1 — owner-scoped byte access across fragmented 8-KiB SRAM banks.
; The 24-bit little-endian wOwnerOffset addresses logical bytes 0..106495
; in at most 13 owned banks. No physical bank is derived from the offset:
; OwnerLeaseSelectBank checks the owner tag and resolves each logical index.
; OwnerByteRead: input wOwnerRequest, wOwnerOffset; output wOwnerByteValue;
;   on failure output zero; wOwnerStatus=0 success, 2 invalid offset/owner,
;   3 logical bank not owned. The selected handle is revoked on failure.
; OwnerByteWrite: additionally input wOwnerByteValue, unchanged on failure;
;   never writes if ownership or offset validation fails.
; On success the physical bank remains mapped. On failure the prior mapping
; remains untouched, but the owner-selected handle is invalidated.
; Requires SRAM enabled, serialized caller, no interrupts. Not reentrant.
; These are semantic addressing primitives, not signed arithmetic yet.
SECTION "Owner-scoped logical SRAM byte access", ROM0

OwnerByteResolve:
    ; Whole 24-bit offset bound: high byte must be 0 or 1.
    ld a, [wOwnerOffset+2]
    cp 2
    jr nc, .invalid
    ; index = (offset >> 13) = high_byte*8 + (middle_byte >> 5).
    ld a, [wOwnerOffset+1]
    srl a
    srl a
    srl a
    srl a
    srl a
    ld b, a
    ld a, [wOwnerOffset+2]
    or a
    jr z, .checkIndex
    ld a, b
    add a, 8
    ld b, a
.checkIndex:
    ld a, b
    cp 13
    jr nc, .invalid
    ld [wOwnerSelectIndex], a
    call OwnerLeaseSelectBank
    ld a, [wOwnerStatus]
    or a
    ret nz
    ; SRAM window address = A000 + (offset & 1FFF).
    ld a, [wOwnerOffset+1]
    and $1f
    add a, $a0
    ld h, a
    ld a, [wOwnerOffset]
    ld l, a
    ret
.invalid:
    ld a, $ff
    ld [wOwnerSelectedBank], a
    ld a, 2
    ld [wOwnerStatus], a
    ret

OwnerByteRead::
    call OwnerByteResolve
    ld a, [wOwnerStatus]
    or a
    jr nz, .invalid
    ld a, [hl]
    ld [wOwnerByteValue], a
    ret
.invalid:
    xor a
    ld [wOwnerByteValue], a
    ret

OwnerByteWrite::
    call OwnerByteResolve
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerByteValue]
    ld [hl], a
    ret
