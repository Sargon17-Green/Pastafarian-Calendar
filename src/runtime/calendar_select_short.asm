; Stage1 short Equal Selection rank kernel.
; Input:
;   wCalendarSelectValue: canonical positive SAVE residue A0, 16-byte LE, 1..2^127-1
;   wCalendarSelectCount: N, 16-bit LE, 1..19044
;   wCalendarSelectDirection: 1=forward (+1), 2=backward (-1)
; Output:
;   wCalendarSelectRank: exact rank 1..N; status 0
; Invalid input: status 2, rank unchanged. Idle: status 6, rank unchanged.
; The active ordinal, owner/lease tags and SRAM payload are read-only.
;
; All Stage1 short-choice counts fit the proven 19044 bound:
; 138 possible gates per side in 5778 days at minimum 42-day spacing;
; Q has at most 138*138 pairs. Gate-gap N=922; NEXT/PREV have <=138.
;
; M=2^127-1; L=M-(M mod N). If A0>L, forward rank=1 and backward rank=N.
; Otherwise rank=1+((A0-1) mod N). The two remainders are computed bitwise:
; r <- (2*r+bit) mod N. Since r<N<=19044, one 16-bit subtraction suffices.
SECTION "Calendar short equal selection", ROMX, BANK[1]
CalendarSelectShortRank::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz

    ld a, [wCalendarSelectDirection]
    cp 1
    jr z, .directionOkay
    cp 2
    jp nz, .invalid
.directionOkay:
    ; N must be nonzero and no larger than 19044 ($4A64).
    ld a, [wCalendarSelectCount]
    ld b, a
    ld a, [wCalendarSelectCount+1]
    or b
    jp z, .invalid
    ld a, [wCalendarSelectCount+1]
    cp $4a
    jr c, .countOkay
    jr nz, .invalid
    ld a, [wCalendarSelectCount]
    cp $65
    jp nc, .invalid
.countOkay:
    ; A0 is a canonical nonzero 127-bit positive residue.
    ld a, [wCalendarSelectValue+15]
    and $80
    jp nz, .invalid
    ld hl, wCalendarSelectValue
    ld b, 16
    ld c, 0
.valueNonzero:
    ld a, [hli]
    or c
    ld c, a
    dec b
    jr nz, .valueNonzero
    ld a, c
    or a
    jp z, .invalid

    ; First compute A0 mod N from its 127 bits, MSB first.
    call .modValue
    ld a, [wCalendarSelectRem]
    ld [wCalendarSelectValueRem], a
    ld a, [wCalendarSelectRem+1]
    ld [wCalendarSelectValueRem+1], a

    ; Then compute M mod N from 127 one-bits.
    call .modM

    ; limit = M - (M mod N), with M = 7F FF ... FF.
    ld hl, wCalendarSelectLimit
    ld b, 15
    ld a, $ff
.fillLimit:
    ld [hli], a
    dec b
    jr nz, .fillLimit
    ld a, $7f
    ld [hl], a

    ld a, [wCalendarSelectLimit]
    ld b, a
    ld a, [wCalendarSelectRem]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarSelectLimit], a
    ld a, [wCalendarSelectLimit+1]
    ld b, a
    ld a, [wCalendarSelectRem+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarSelectLimit+1], a
    jr nc, .compareLimit
    ld hl, wCalendarSelectLimit+2
    ld b, 14
.borrowLimit:
    ld a, [hl]
    sub 1
    ld [hli], a
    jr nc, .compareLimit
    dec b
    jr nz, .borrowLimit

.compareLimit:
    ; Unsigned comparison A0 > L, most significant byte first.
    ld hl, wCalendarSelectValue+15
    ld de, wCalendarSelectLimit+15
    ld b, 16
.compareByte:
    ld a, [hl]
    ld c, a
    ld a, [de]
    cp c
    jr c, .aboveLimit
    jr nz, .withinLimit
    dec hl
    dec de
    dec b
    jr nz, .compareByte

.withinLimit:
    ; 1+((A0-1) mod N) is A0 mod N, except zero maps to N.
    ld a, [wCalendarSelectValueRem+1]
    or a
    jr nz, .useValueRemainder
    ld a, [wCalendarSelectValueRem]
    or a
    jr z, .useCount
.useValueRemainder:
    ld a, [wCalendarSelectValueRem]
    ld [wCalendarSelectRank], a
    ld a, [wCalendarSelectValueRem+1]
    ld [wCalendarSelectRank+1], a
    jr .success

.aboveLimit:
    ld a, [wCalendarSelectDirection]
    cp 1
    jr nz, .useCount
    ld a, 1
    ld [wCalendarSelectRank], a
    xor a
    ld [wCalendarSelectRank+1], a
    jr .success

.useCount:
    ld a, [wCalendarSelectCount]
    ld [wCalendarSelectRank], a
    ld a, [wCalendarSelectCount+1]
    ld [wCalendarSelectRank+1], a

.success:
    xor a
    ld [wCalendarStatus], a
    ret

.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

; Compute A0 mod N. The fixed-width input is scanned as 7 high bits then
; fifteen complete bytes, exactly 127 bits.
.modValue:
    xor a
    ld [wCalendarSelectRem], a
    ld [wCalendarSelectRem+1], a
    ld a, 15
    ld [wCalendarSelectByteIndex], a
    ld a, [wCalendarSelectValue+15]
    ld [wCalendarSelectInputByte], a
    ld a, $40
    ld [wCalendarSelectMask], a
    ld a, 7
    ld [wCalendarSelectBitsRemaining], a
.valueBitLoop:
    call .modValueBit
    ld hl, wCalendarSelectBitsRemaining
    dec [hl]
    jr nz, .valueBitLoop
    ld a, [wCalendarSelectByteIndex]
    or a
    ret z
    dec a
    ld [wCalendarSelectByteIndex], a
    ld e, a
    ld d, 0
    ld hl, wCalendarSelectValue
    add hl, de
    ld a, [hl]
    ld [wCalendarSelectInputByte], a
    ld a, $80
    ld [wCalendarSelectMask], a
    ld a, 8
    ld [wCalendarSelectBitsRemaining], a
    jr .valueBitLoop

.modValueBit:
    ld a, [wCalendarSelectInputByte]
    ld b, a
    ld a, [wCalendarSelectMask]
    and b
    ld c, 0
    jr z, .valueBitReady
    inc c
.valueBitReady:
    ld a, [wCalendarSelectRem]
    add a, a
    ld [wCalendarSelectRem], a
    ld a, [wCalendarSelectRem+1]
    adc a, a
    ld [wCalendarSelectRem+1], a
    ld a, c
    or a
    jr z, .reduceRem
    ld hl, wCalendarSelectRem
    inc [hl]
.reduceRem:
    call .reduceRemainder
    ld a, [wCalendarSelectMask]
    srl a
    ld [wCalendarSelectMask], a
    ret

; Compute M mod N by applying r <- (2*r+1) mod N exactly 127 times.
.modM:
    xor a
    ld [wCalendarSelectRem], a
    ld [wCalendarSelectRem+1], a
    ld a, 127
    ld [wCalendarSelectBitsRemaining], a
.mersenneBitLoop:
    ld a, [wCalendarSelectRem]
    add a, a
    ld [wCalendarSelectRem], a
    ld a, [wCalendarSelectRem+1]
    adc a, a
    ld [wCalendarSelectRem+1], a
    ld hl, wCalendarSelectRem
    inc [hl]
    call .reduceRemainder
    ld hl, wCalendarSelectBitsRemaining
    dec [hl]
    jr nz, .mersenneBitLoop
    ret

; rem is below 2*N before reduction; compare and subtract N at most once.
.reduceRemainder:
    ld a, [wCalendarSelectRem+1]
    ld b, a
    ld a, [wCalendarSelectCount+1]
    cp b
    jr c, .subtractRemainder
    jr nz, .remainderDone
    ld a, [wCalendarSelectRem]
    ld b, a
    ld a, [wCalendarSelectCount]
    cp b
    jr c, .subtractRemainder
    jr nz, .remainderDone
.subtractRemainder:
    ld a, [wCalendarSelectRem]
    ld b, a
    ld a, [wCalendarSelectCount]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarSelectRem], a
    ld a, [wCalendarSelectRem+1]
    ld b, a
    ld a, [wCalendarSelectCount+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarSelectRem+1], a
.remainderDone:
    ret
