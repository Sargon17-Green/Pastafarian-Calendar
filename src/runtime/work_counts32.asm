; Five normative work counters for a BOUNDED signed-32 pair of offsets.
; c,t are offsets from Foundation; outputs remain five-byte unsigned LE.
; Distance uses chronological offsets |t-c|+1, NOT |N(t)-N(c)|+1.
; Direction: 1 backward, 2 same day, 3 forward.
; Inputs unchanged; CPU is the original SM83. No host code linked.
SECTION "Native bounded five work counters", ROM0
WorkCountsFromOffsets32::
    ld hl, wPairCalcOffset
    ld de, wDayOffset
    ld b, 4
.copyC:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyC
    call DayCountFromOffset
    ld hl, wDayCount
    ld de, wWorkCalcCount
    ld b, 5
.keepC:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .keepC

    ld hl, wPairTargetOffset
    ld de, wDayOffset
    ld b, 4
.copyT:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyT
    call DayCountFromOffset
    ld hl, wDayCount
    ld de, wWorkTargetCount
    ld b, 5
.keepT:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .keepT

    ; Signed comparison via sign-bit bias of the highest byte.
    ld a, [wPairCalcOffset + 3]
    xor $80
    ld b, a
    ld a, [wPairTargetOffset + 3]
    xor $80
    cp b
    jr c, .earlier
    jr nz, .later
    ld a, [wPairCalcOffset + 2]
    ld b, a
    ld a, [wPairTargetOffset + 2]
    cp b
    jr c, .earlier
    jr nz, .later
    ld a, [wPairCalcOffset + 1]
    ld b, a
    ld a, [wPairTargetOffset + 1]
    cp b
    jr c, .earlier
    jr nz, .later
    ld a, [wPairCalcOffset]
    ld b, a
    ld a, [wPairTargetOffset]
    cp b
    jr c, .earlier
    jr nz, .later
    ld a, 2
    jr .setDirection
.earlier:
    ld a, 1
    jr .setDirection
.later:
    ld a, 3
.setDirection:
    ld [wWorkDirection], a

    ; Signed order selects larger-minus-smaller. The unsigned 32-bit
    ; residue of the two's-complement subtraction is exact in [0,2^32-1].
    ld a, [wWorkDirection]
    cp 1
    jr z, .calcLarger
    ld de, wPairTargetOffset
    ld hl, wPairCalcOffset
    jr .subtract
.calcLarger:
    ld de, wPairCalcOffset
    ld hl, wPairTargetOffset
.subtract:
    ld bc, wWorkDistance
    ld a, 4
    ld [wWorkLeft], a
    and a
.subLoop:
    ld a, [de]
    sbc a, [hl]
    ld [bc], a
    inc de
    inc hl
    inc bc
    ld a, [wWorkLeft]
    dec a                 ; does not change CPU carry
    ld [wWorkLeft], a
    jr nz, .subLoop
    xor a
    ld [wWorkDistance + 4], a
    ; Inclusive distance; propagate past bit 31 when difference is 2^32-1.
    ld hl, wWorkDistance
    ld b, 5
.plusOne:
    inc [hl]
    jr nz, .sum
    inc hl
    dec b
    jr nz, .plusOne

.sum:
    ; Exact sum of day counts (maximum 2^33), five bytes are sufficient.
    ld hl, wWorkCalcCount
    ld de, wWorkTargetCount
    ld bc, wWorkSum
    ld a, 5
    ld [wWorkLeft], a
    and a
.sumLoop:
    ld a, [de]
    adc a, [hl]
    ld [bc], a
    inc de
    inc hl
    inc bc
    ld a, [wWorkLeft]
    dec a                 ; preserves carry
    ld [wWorkLeft], a
    jr nz, .sumLoop
    ret
