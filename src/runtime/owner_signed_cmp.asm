; Stage 1: owner-scoped, canonical signed-magnitude comparison.
; Inputs: wOwnerCmpOwnerA/B (owner IDs), wOwnerCmpSignA/B (0=+,1=-),
;         wOwnerCmpLenA/B (24-bit LE lengths in bytes, zero=empty +0).
; Magnitudes live in each owner's logical 8-KiB banks, little-endian.
; All nonzero magnitudes must have a nonzero highest byte; -0 is invalid.
; Output: wOwnerCmpResult 0=equal,1=A>B,2=A<B,3=invalid/unowned.
; Operands and lease table are never written. OwnerByteRead/SelectBank change
; mapping, selected-handle and scratch wOwnerRequest/Offset/ByteValue.
; Requires enabled SRAM, DI/serialized caller; not reentrant.
SECTION "Owned canonical signed-magnitude comparison", ROM0

OwnerCmpDec24:
    ld a, [hl]
    or a
    jr nz, .low
    ld [hl], $ff
    inc hl
    ld a, [hl]
    or a
    jr nz, .middle
    ld [hl], $ff
    inc hl
    dec [hl]
    ret
.middle:
    dec [hl]
    ret
.low:
    dec [hl]
    ret

; Input wOwnerRequest, wOwnerCmpActiveSign, wOwnerOffset=length.
; Output wOwnerStatus=0 if canonical, else 2/3.
OwnerCmpValidate:
    ld a, [wOwnerCmpActiveSign]
    cp 2
    jr nc, .bad
    xor a
    ld [wOwnerSelectIndex], a
    call OwnerLeaseSelectBank
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerOffset]
    ld b, a
    ld a, [wOwnerOffset+1]
    or b
    ld b, a
    ld a, [wOwnerOffset+2]
    or b
    jr nz, .nonzero
    ld a, [wOwnerCmpActiveSign]
    or a
    jr nz, .bad
    ret
.nonzero:
    ld hl, wOwnerOffset
    call OwnerCmpDec24
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerByteValue]
    or a
    ret nz
.bad:
    ld a, 2
    ld [wOwnerStatus], a
    ret

OwnerSignedCmp::
    ld a, 3
    ld [wOwnerCmpResult], a
    ld a, [wOwnerCmpOwnerA]
    ld [wOwnerRequest], a
    ld a, [wOwnerCmpSignA]
    ld [wOwnerCmpActiveSign], a
    ld a, [wOwnerCmpLenA]
    ld [wOwnerOffset], a
    ld a, [wOwnerCmpLenA+1]
    ld [wOwnerOffset+1], a
    ld a, [wOwnerCmpLenA+2]
    ld [wOwnerOffset+2], a
    call OwnerCmpValidate
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerCmpOwnerB]
    ld [wOwnerRequest], a
    ld a, [wOwnerCmpSignB]
    ld [wOwnerCmpActiveSign], a
    ld a, [wOwnerCmpLenB]
    ld [wOwnerOffset], a
    ld a, [wOwnerCmpLenB+1]
    ld [wOwnerOffset+1], a
    ld a, [wOwnerCmpLenB+2]
    ld [wOwnerOffset+2], a
    call OwnerCmpValidate
    ld a, [wOwnerStatus]
    or a
    ret nz

    ld a, [wOwnerCmpSignA]
    ld b, a
    ld a, [wOwnerCmpSignB]
    cp b
    jr z, .sameSign
    ld a, b
    or a
    jr z, .greaterDirect
    ld a, 2
    jr .store
.greaterDirect:
    ld a, 1
    jr .store

.sameSign:
    ld a, [wOwnerCmpLenA+2]
    ld b, a
    ld a, [wOwnerCmpLenB+2]
    cp b
    jr c, .greater
    jr nz, .less
    ld a, [wOwnerCmpLenA+1]
    ld b, a
    ld a, [wOwnerCmpLenB+1]
    cp b
    jr c, .greater
    jr nz, .less
    ld a, [wOwnerCmpLenA]
    ld b, a
    ld a, [wOwnerCmpLenB]
    cp b
    jr c, .greater
    jr nz, .less

    ld a, [wOwnerCmpLenA]
    ld [wOwnerCmpCursor], a
    ld a, [wOwnerCmpLenA+1]
    ld [wOwnerCmpCursor+1], a
    ld a, [wOwnerCmpLenA+2]
    ld [wOwnerCmpCursor+2], a
.loop:
    ld a, [wOwnerCmpCursor]
    ld b, a
    ld a, [wOwnerCmpCursor+1]
    or b
    ld b, a
    ld a, [wOwnerCmpCursor+2]
    or b
    jr z, .equal
    ld hl, wOwnerCmpCursor
    call OwnerCmpDec24
    ld a, [wOwnerCmpCursor]
    ld [wOwnerOffset], a
    ld a, [wOwnerCmpCursor+1]
    ld [wOwnerOffset+1], a
    ld a, [wOwnerCmpCursor+2]
    ld [wOwnerOffset+2], a
    ld a, [wOwnerCmpOwnerA]
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerByteValue]
    ld [wOwnerCmpByteA], a
    ld a, [wOwnerCmpOwnerB]
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    ret nz
    ld a, [wOwnerCmpByteA]
    ld b, a
    ld a, [wOwnerByteValue]
    cp b
    jr c, .greater
    jr nz, .less
    jr .loop
.equal:
    xor a
    jr .store
.greater:
    ld a, 1
    jr .rank
.less:
    ld a, 2
.rank:
    ld b, a
    ld a, [wOwnerCmpSignA]
    or a
    ld a, b
    jr z, .store
    cp 1
    jr nz, .invertLess
    ld a, 2
    jr .store
.invertLess:
    ld a, 1
.store:
    ld [wOwnerCmpResult], a
    ret
