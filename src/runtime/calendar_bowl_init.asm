; Stage1 Native389: six initial canonical bowls from signed32 work counts.
; Input caller offsets and active ordinal/lease; output wCalendarBowlsOld[96].
; All bowls staged before one publication. ROMX bank1, no SRAM changes.
SECTION "Calendar Stage1 bowl initialization", ROMX, BANK[1]

CalendarBowlsInitialize::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    call WorkCountsFromOffsets32
    ld a, 1
    ld [wCalendarBowlQ], a
.nextBowl:
    ld hl, wValue
    call Clear16
    ld hl, wWorkCalcCount
    ld b, 1
    call .addCount
    ld hl, wWorkTargetCount
    ld a, [wCalendarBowlQ]
    ld b, a
    call .addCount
    ld hl, wWorkDistance
    ld b, 1
    call .addCount
    ld hl, wWorkSum
    ld b, 1
    call .addCount
    ld hl, wAddend
    call Clear16
    ld a, [wWorkDirection]
    ld [wAddend], a
    call Add16
    call Save127

    ; Seed_j squared constants, not identity squared.
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarBowlQ]
    dec a
    add a, a
    ld e, a
    ld d, 0
    ld hl, .seedSquares
    add hl, de
    ld a, [hli]
    ld [wAddend], a
    ld a, [hl]
    ld [wAddend+1], a
    call Add16
    call Save127

    ld hl, wValue
    ld de, wMulA
    call .copy16
    ld hl, wValue
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarBowlQ]
    ld [wAddend], a
    call Add16
    call Save127

    ld a, [wCalendarBowlQ]
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlNewScratch
    add hl, de
    ld d, h
    ld e, l
    ld hl, wValue
    call .copy16
    ld hl, wCalendarBowlQ
    inc [hl]
    ld a, [hl]
    cp 7
    jr nz, .nextBowl

    ; Atomic publication after six successful calculations.
    ld hl, wCalendarBowlNewScratch
    ld de, wCalendarBowlsOld
    ld b, 96
.publish:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .publish
    xor a
    ld [wCalendarStatus], a
    ret

.addCount:
    ; HL = five-byte LE count, B coefficient 1..6.
    ld a, b
    ld [wCalendarBowlRepeat], a
    push hl
    ld hl, wAddend
    call Clear16
    pop hl
    ld de, wAddend
    ld b, 5
.copyCount:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyCount
.repeat:
    call Add16
    call Save127
    ld hl, wCalendarBowlRepeat
    dec [hl]
    jr nz, .repeat
    ret

.copy16:
    ld b, 16
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret

.seedSquares:
    dw 289,361,529,841,961,1369
