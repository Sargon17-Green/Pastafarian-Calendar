; Stage1 visible drop i=1,2,3 with three caller-supplied predecessors.
; The already accepted i=1 interface is preserved. Only a successful
; invocation publishes the 16-byte output; runtime has no fixture data.
SECTION "Calendar visible1 native", ROMX, BANK[1]
CalendarVisibleDrop1::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarVisibleIteration]
    cp 1
    jr z, .validIteration
    cp 2
    jr z, .validIteration
    cp 3
    jr z, .validIteration
    cp 4
    jp nz, .invalid
.validIteration:
    ld hl, wCalendarStoneOld
    ld b, 5
    call .validateResidues
    jp nz, .invalid
    ld hl, wCalendarVisibleInputs
    ld b, 3
    call .validateResidues
    jp nz, .invalid
    call WorkCountsFromOffsets32
    ld hl, wCalendarVisibleAccum
    call Clear16
    xor a
    ld [wCalendarVisibleIndex], a
.countProducts:
    ; 16-byte canonical stone * zero-extended work count (5-byte LE).
    ld a, [wCalendarVisibleIndex]
    call .loadStoneToMulA
    call .loadCountToMulB
    call Mul128x128
    call SaveWide256
    ld hl, wCalendarVisibleAccum
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ld hl, wValue
    ld de, wCalendarVisibleAccum
    call .copy16
    ld hl, wCalendarVisibleIndex
    inc [hl]
    ld a, [hl]
    cp 5
    jr nz, .countProducts

    ; i=1 => predecessor drops at 0,-2,-6 = hidden1,3,7.
    ld a, 0
    call .loadDrop
    ld b, 1
    call .repeatAddition
    ld a, 1
    call .loadDrop
    ld b, 3
    call .repeatAddition
    ld a, 2
    call .loadDrop
    ld b, 5
    call .repeatAddition
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarVisibleIteration]
    ld [wAddend], a
    call Add16
    call Save127
    call .saveWorking

    xor a
    ld [wCalendarVisibleRound], a
.grind:
    ; x*x + a*x + b*H1 + c*H3 + d*H7 + stone[j].
    ; Every non-square term uses the OLD x, never the updated wValue.
    ld hl, wCalendarVisibleWorking
    ld de, wMulA
    call .copy16
    ld hl, wCalendarVisibleWorking
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wCalendarVisibleWorking
    ld de, wAddend
    call .copy16
    xor a
    call .rowValue
    ld b, a
    call .repeatAddition
    ld a, 0
    call .loadDrop
    ld a, 1
    call .rowValue
    ld b, a
    call .repeatAddition
    ld a, 1
    call .loadDrop
    ld a, 2
    call .rowValue
    ld b, a
    call .repeatAddition
    ld a, 2
    call .loadDrop
    ld a, 3
    call .rowValue
    ld b, a
    call .repeatAddition
    ld a, 4
    call .rowValue
    call .loadStoneToAddend
    call Add16
    call Save127
    call .saveWorking
    ld hl, wCalendarVisibleRound
    inc [hl]
    ld a, [hl]
    cp 11
    jp nz, .grind

    ld hl, wCalendarVisibleWorking
    ld de, wCalendarVisibleOutput
    call .copy16
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.validateResidues:
    ; Z=1 for B canonical 127-bit, nonzero residues, no writes.
.nextResidue:
    ld c, 15
    ld d, 0
.low:
    ld a, [hli]
    or d
    ld d, a
    dec c
    jr nz, .low
    ld a, [hli]
    bit 7, a
    jr nz, .bad
    or d
    jr z, .bad
    dec b
    jr nz, .nextResidue
    xor a
    ret
.bad:
    ld a, 1
    or a
    ret
.copy16:
    ld b, 16
.nextByte:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .nextByte
    ret
.loadStoneToMulA:
    ; A=index 0..4, input stones in original i=1 source buffer.
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wMulA
    jp .copy16
.loadStoneToAddend:
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wAddend
    jp .copy16
.loadDrop:
    ; A=0,1,2 => k=1,3,7 respectively.
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarVisibleInputs
    add hl, de
    ld de, wAddend
    jp .copy16
.loadCountToMulB:
    ld hl, wMulB
    call Clear16
    ld a, [wCalendarVisibleIndex]
    add a, a
    ld e, a
    ld d, 0
    ld hl, .countPtrs
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld de, wMulB
    ld b, 5
    ld a, [wCalendarVisibleIndex]
    cp 4
    jr nz, .countCopy
    ld b, 1
.countCopy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .countCopy
    ret
.rowValue:
    ; A=column 0..4; row index 0..10, five literal constants per row.
    ld b, a
    ld a, [wCalendarVisibleRound]
    ld c, a
    add a, a
    add a, a
    add a, c
    add a, b
    ld e, a
    ld d, 0
    ld hl, .rows
    add hl, de
    ld a, [hl]
    ret
.repeatAddition:
    ld a, b
    or a
    ret z
    ld [wCalendarVisibleRepeat], a
.add:
    call Add16
    call Save127
    ld hl, wCalendarVisibleRepeat
    dec [hl]
    jr nz, .add
    ret
.saveWorking:
    ld hl, wValue
    ld de, wCalendarVisibleWorking
    jp .copy16
.countPtrs:
    dw wWorkCalcCount, wWorkTargetCount, wWorkDistance, wWorkSum, wWorkDirection
.rows:
    db 3,5,7,11,0
    db 5,7,11,13,1
    db 7,11,13,17,2
    db 11,13,17,19,3
    db 13,17,19,23,4
    db 17,19,23,29,0
    db 19,23,29,31,1
    db 23,29,31,37,2
    db 29,31,37,41,3
    db 31,37,41,43,4
    db 37,41,43,47,0
