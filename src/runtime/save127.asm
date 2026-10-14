; SAVE(x) = 1 + ((x - 1) mod M), M=2^127-1.
; This implementation handles unsigned 128-bit operands in little-endian
; WRAM wValue. It does NOT claim arbitrary precision or full calendar support.
;
; Fold bit 127: 2^127 == 1 (mod M). For 0 use the canonical SAVE value M.
; Re-fold if adding the carried one crosses bit 127 again.
SECTION "128-bit Mersenne primitives", ROM0

Clear16::
    ld b, 16
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

FillM::
    ld b, 15
    ld a, $ff
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ld a, $7f
    ld [hl], a
    ret

; Precondition: both 16-byte inputs are in 0..M; result < 2^128.
; Mutates wValue; wAddend remains unchanged. No 128-bit overflow under
; the stated precondition. Caller must run Save127 to canonicalize.
Add16::
    ld hl, wValue
    ld de, wAddend
    ld b, 16
    and a  ; clear CPU carry
.loop:
    ld a, [de]
    adc a, [hl]
    ld [hli], a
    inc de
    dec b     ; DEC does not alter carry on SM83
    jr nz, .loop
    ret

Save127::
.fold:
    ld hl, wValue + 15
    bit 7, [hl]
    jr z, .checkZero
    res 7, [hl]
    ld hl, wValue
    ld b, 16
.carry:
    inc [hl]
    jr nz, .fold
    inc hl
    dec b
    jr nz, .carry
    jr .fold
.checkZero:
    ld hl, wValue
    ld b, 16
.zeroLoop:
    ld a, [hli]
    or a
    jr nz, .done
    dec b
    jr nz, .zeroLoop
    ld hl, wValue
    call FillM
.done:
    ret
