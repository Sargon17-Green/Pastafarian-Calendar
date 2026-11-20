; Stage1 isolated first hidden drop (k=1). This is NOT the seven-drop
; pipeline. Input: signed32 Foundation-relative c,t offsets in wPair*Offset.
; Output: wCalendarHiddenOutput, published only after successful completion.
; Calls the independently accepted WorkCountsFromOffsets32 and arithmetic ABI.
SECTION "Calendar first hidden drop", ROMX, BANK[1]
CalendarHiddenDrop1::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    call WorkCountsFromOffsets32
    ld hl, wValue
    call Clear16
    ; k=1: a=3,b=4,c=6,d=8; five counters (A,B,C,D,E).
    ld hl, wWorkCalcCount
    ld b, 1
    call .addFiveCount
    ld hl, wWorkTargetCount
    ld b, 3
    call .addFiveCount
    ld hl, wWorkDistance
    ld b, 4
    call .addFiveCount
    ld hl, wWorkSum
    ld b, 6
    call .addFiveCount
    ld hl, wAddend
    call Clear16
    ld a, [wWorkDirection]
    ld [wAddend], a
    ld b, 8
    call .repeatAddition
    ; Sum of first five stones: 17+29+43+71+101 = 261.
    ld hl, wAddend
    call Clear16
    ld a, 5
    ld [wAddend], a
    ld a, 1
    ld [wAddend+1], a
    ld b, 1
    call .repeatAddition
    call .saveWorking
    ld a, 1
    ld [wCalendarHiddenRound], a
.round:
    ; old x*x, exact 256-bit product, then canonical SAVE.
    ld hl, wCalendarHiddenWorking
    ld de, wMulA
    ld b, 16
.copyA:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyA
    ld hl, wMulA
    ld de, wMulB
    ld b, 16
.copyB:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyB
    call Mul128x128
    call SaveWide256
    ; Add 3*OLD x, never the recently updated wValue.
    ld hl, wAddend
    ld de, wCalendarHiddenWorking
    ld b, 16
.copyX:
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .copyX
    ld b, 3
    call .repeatAddition
    ; The seven k=1 grind stones are 17,29,43,71,101,17,29.
    ; Add stone + r, where r=1..7; no 8-bit overflow possible.
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarHiddenRound]
    dec a
    ld e, a
    ld d, 0
    ld hl, .stoneSeed
    add hl, de
    ld b, [hl]
    ld a, [wCalendarHiddenRound]
    add a, b
    ld [wAddend], a
    ld b, 1
    call .repeatAddition
    call .saveWorking
    ld hl, wCalendarHiddenRound
    inc [hl]
    ld a, [hl]
    cp 8
    jr nz, .round
    ; Atomic 16-byte publication after the entire grind succeeds.
    ld hl, wCalendarHiddenWorking
    ld de, wCalendarHiddenOutput
    ld b, 16
.publish:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .publish
    xor a
    ld [wCalendarStatus], a
    ret
.addFiveCount:
    ; HL=5-byte LE count, B=coefficient. Do not read adjacent state.
    push bc
    push hl
    ld hl, wAddend
    call Clear16
    pop hl
    ld de, wAddend
    ld c, 5
.copyCount:
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copyCount
    pop bc
    jp .repeatAddition
.repeatAddition:
    ld a, b
    ld [wCalendarHiddenRepeat], a
.addLoop:
    call Add16
    call Save127
    ld hl, wCalendarHiddenRepeat
    dec [hl]
    jr nz, .addLoop
    ret
.saveWorking:
    ld hl, wValue
    ld de, wCalendarHiddenWorking
    ld b, 16
.copyResult:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyResult
    ret
.stoneSeed:
    db 17,29,43,71,101,17,29
