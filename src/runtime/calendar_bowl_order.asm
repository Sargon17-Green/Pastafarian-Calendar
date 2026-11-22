; Stage1 bowl-order primitive: lexicographic unranking of canonical SAVE residue.
; Input: wCalendarBowlOrderInput[16], LE residue in 1..(2^127-1), read-only.
; Output: wCalendarBowlOrder[6] contains a permutation of bowl IDs 1..6.
; Status: 0 success, 2 invalid input, 6 idle (from CalendarOrdinalValidate).
; Source and public output are not mutated on failure. All working data is WRAM0.
; No 128-bit division: 128 serial bits reduce modulo 720, then 6! unranking.
SECTION "Calendar Stage1 bowl order", ROMX, BANK[1]

CalendarBowlOrderFromResidue::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz

    ; Validate canonical SAVE residue without touching output.
    ld hl, wCalendarBowlOrderInput
    ld b, 15
    ld d, 0
.validateLow:
    ld a, [hli]
    or d
    ld d, a
    dec b
    jr nz, .validateLow
    ld a, [hl]
    bit 7, a
    jp nz, .invalid
    or d
    jp z, .invalid

    ; Long division by 720: at each step R <- 2*R + input_bit.
    ; R<720 prior to the step, so only one subtraction is necessary.
    xor a
    ld [wCalendarBowlRankLo], a
    ld [wCalendarBowlRankHi], a
    ld hl, wCalendarBowlOrderInput+15
    ld b, 16
.byte:
    ld a, [hld]
    ld [wCalendarBowlBitByte], a
    ld c, 8
.bit:
    ld a, [wCalendarBowlBitByte]
    add a, a
    ld [wCalendarBowlBitByte], a
    ld a, 0
    adc a, 0
    ld [wCalendarBowlBitFlag], a

    ld a, [wCalendarBowlRankLo]
    add a, a
    ld [wCalendarBowlRankLo], a
    ld a, [wCalendarBowlRankHi]
    rla
    ld [wCalendarBowlRankHi], a
    ld a, [wCalendarBowlBitFlag]
    ld d, a
    ld a, [wCalendarBowlRankLo]
    add a, d
    ld [wCalendarBowlRankLo], a

    ld a, [wCalendarBowlRankHi]
    cp 2
    jr c, .keep
    jr nz, .subtract720
    ld a, [wCalendarBowlRankLo]
    cp $d0
    jr c, .keep
.subtract720:
    ld a, [wCalendarBowlRankLo]
    sub $d0
    ld [wCalendarBowlRankLo], a
    ld a, [wCalendarBowlRankHi]
    sbc a, 2
    ld [wCalendarBowlRankHi], a
.keep:
    dec c
    jr nz, .bit
    dec b
    jr nz, .byte

    ; The normative rank is 1-based: index=(residue-1) modulo 720.
    ld a, [wCalendarBowlRankLo]
    ld d, a
    ld a, [wCalendarBowlRankHi]
    or d
    jr nz, .decrementRank
    ld a, $cf                ; 719 (0x02cf), not index zero.
    ld [wCalendarBowlRankLo], a
    ld a, 2
    ld [wCalendarBowlRankHi], a
    jr .initialize
.decrementRank:
    ld a, [wCalendarBowlRankLo]
    sub 1
    ld [wCalendarBowlRankLo], a
    ld a, [wCalendarBowlRankHi]
    sbc a, 0
    ld [wCalendarBowlRankHi], a

.initialize:
    ld hl, wCalendarBowlAvailable
    ld b, 6
    ld a, 1
.seed:
    ld [hli], a
    inc a
    dec b
    jr nz, .seed
    xor a
    ld [wCalendarBowlPosition], a

.nextPosition:
    ld a, [wCalendarBowlPosition]
    ld e, a
    ld d, 0
    ld hl, .factorials
    add hl, de
    ld a, [hl]
    ld [wCalendarBowlDivisor], a
    xor a
    ld [wCalendarBowlDigit], a
.divide:
    ld a, [wCalendarBowlRankHi]
    or a
    jr nz, .subtractFactor
    ld a, [wCalendarBowlRankLo]
    ld d, a
    ld a, [wCalendarBowlDivisor]
    cp d
    jr c, .subtractFactor
    jr z, .subtractFactor
    jr .select
.subtractFactor:
    ld a, [wCalendarBowlDivisor]
    ld d, a
    ld a, [wCalendarBowlRankLo]
    sub d
    ld [wCalendarBowlRankLo], a
    ld a, [wCalendarBowlRankHi]
    sbc a, 0
    ld [wCalendarBowlRankHi], a
    ld hl, wCalendarBowlDigit
    inc [hl]
    jr .divide

.select:
    ld hl, wCalendarBowlAvailable
    ld a, [wCalendarBowlDigit]
    ld c, a
    ld b, 6
.scan:
    ld a, [hl]
    or a
    jr z, .advance
    ld a, c
    or a
    jr z, .found
    dec c
.advance:
    inc hl
    dec b
    jr nz, .scan
    jp .invalid
.found:
    ld b, [hl]
    xor a
    ld [hl], a
    ld a, [wCalendarBowlPosition]
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlOrderScratch
    add hl, de
    ld a, b
    ld [hl], a
    ld hl, wCalendarBowlPosition
    inc [hl]
    ld a, [hl]
    cp 6
    jr nz, .nextPosition

    ; Publish all six identities only after successful construction.
    ld hl, wCalendarBowlOrderScratch
    ld de, wCalendarBowlOrder
    ld b, 6
.commit:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .commit
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.factorials:
    db 120, 24, 6, 2, 1, 1
