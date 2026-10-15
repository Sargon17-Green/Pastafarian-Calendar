; Normative day count for an EXACT signed 32-bit offset from Foundation.
; Input wDayOffset: 4 bytes, LE two's-complement delta d-Foundation.
; Output wDayCount: 5 bytes, LE, positive nonzero (up to 2^32).
; With d=Foundation+x:
; x<0 -> N(d)=2*(-x); x>=0 -> N(d)=2*x+1.
; Correct for the entire signed 32-bit offset range including INT32_MIN;
; does not support arbitrarily distant calendar days (future extension).
; No arithmetic helper from a host language executes on DMG.
SECTION "Native signed day-count subset", ROM0

DayCountFromOffset::
    ld hl, wDayCount
    ld b, 5
    xor a
.clear:
    ld [hli], a
    dec b
    jr nz, .clear

    ld a, [wDayOffset + 3]
    and $80
    ld [wDayNeg], a
    jr z, .copyPositive

    ; Absolute value of negative two's-complement 32-bit delta.
    ; Carry propagation is exact for -2^31, whose magnitude is 2^31.
    ld hl, wDayOffset
    ld de, wDayCount
    ld b, 4
    scf
.negate:
    ld a, [hli]
    cpl
    adc a, 0
    ld [de], a
    inc de
    dec b
    jr nz, .negate
    jr .double

.copyPositive:
    ld hl, wDayOffset
    ld de, wDayCount
    ld b, 4
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy

.double:
    ; Double exact unsigned 32-bit magnitude into 5 bytes.
    ld hl, wDayCount
    ld b, 5
    and a                   ; clear carry, no truncation after bit 31
.shift:
    ld a, [hl]
    rl a
    ld [hli], a
    dec b
    jr nz, .shift

    ld a, [wDayNeg]
    or a
    ret nz                  ; even day count for before Foundation

    ; Foundation itself -> 1, after Foundation -> odd day count.
    ld hl, wDayCount
    ld b, 5
.increment:
    inc [hl]
    ret nz
    inc hl
    dec b
    jr nz, .increment
    ret
