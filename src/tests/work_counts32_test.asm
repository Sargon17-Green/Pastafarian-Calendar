; Bounded work counters: 16 native ROM fixtures, each 29 bytes:
; calc offset 4, target offset 4, four numeric outputs 5 each, direction 1.
SECTION "Native bounded work count tests", ROM0
RunWorkCountTests::
    ld a, 93
    ld [wTestCase], a
    ld hl, WorkCounterCases
.next:
    ld de, wPairCalcOffset
    ld b, 8
.copyInputs:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyInputs
    ld de, wWorkExpectedCalc
    ld b, 21
.copyExpected:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyExpected
    push hl
    call WorkCountsFromOffsets32
    ld hl, wWorkCalcCount
    ld de, wWorkExpectedCalc
    ld b, 21
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .badStack
    inc de
    inc hl
    dec b
    jr nz, .compare
    pop hl
    ld a, [wTestCase]
    cp 108
    jr z, .good
    inc a
    ld [wTestCase], a
    jr .next
.badStack:
    pop hl
.bad:
    ld a, $e0
    ld [wTestResult], a
    ret
.good:
    ld a, $a5
    ld [wTestResult], a
    ret
WorkCounterCases:
    ; Case 93
    db $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $02, $00, $00, $00, $00, $02
    ; Case 94
    db $00, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $03, $00, $00, $00, $00, $02, $00, $00, $00, $00, $04, $00, $00, $00, $00, $03
    ; Case 95
    db $01, $00, $00, $00, $00, $00, $00, $00, $03, $00, $00, $00, $00, $01, $00, $00, $00, $00, $02, $00, $00, $00, $00, $04, $00, $00, $00, $00, $01
    ; Case 96
    db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $02, $00, $00, $00, $00, $01, $00, $00, $00, $00, $02, $00, $00, $00, $00, $03, $00, $00, $00, $00, $03
    ; Case 97
    db $00, $00, $00, $00, $ff, $ff, $ff, $ff, $01, $00, $00, $00, $00, $02, $00, $00, $00, $00, $02, $00, $00, $00, $00, $03, $00, $00, $00, $00, $01
    ; Case 98
    db $ff, $ff, $ff, $ff, $01, $00, $00, $00, $02, $00, $00, $00, $00, $03, $00, $00, $00, $00, $03, $00, $00, $00, $00, $05, $00, $00, $00, $00, $03
    ; Case 99
    db $01, $00, $00, $00, $ff, $ff, $ff, $ff, $03, $00, $00, $00, $00, $02, $00, $00, $00, $00, $03, $00, $00, $00, $00, $05, $00, $00, $00, $00, $01
    ; Case 100
    db $00, $00, $00, $80, $ff, $ff, $ff, $7f, $00, $00, $00, $00, $01, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $01, $ff, $ff, $ff, $ff, $01, $03
    ; Case 101
    db $ff, $ff, $ff, $7f, $00, $00, $00, $80, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $ff, $ff, $ff, $ff, $01, $01
    ; Case 102
    db $00, $00, $00, $80, $00, $00, $00, $80, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02
    ; Case 103
    db $ff, $ff, $ff, $7f, $ff, $ff, $ff, $7f, $ff, $ff, $ff, $ff, $00, $ff, $ff, $ff, $ff, $00, $01, $00, $00, $00, $00, $fe, $ff, $ff, $ff, $01, $02
    ; Case 104
    db $00, $00, $00, $80, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $80, $00, $02, $00, $00, $00, $01, $03
    ; Case 105
    db $00, $00, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $02, $00, $00, $01, $00, $01, $00, $00, $02, $00, $02, $00, $00, $03
    ; Case 106
    db $00, $00, $ff, $ff, $00, $00, $01, $00, $00, $00, $02, $00, $00, $01, $00, $02, $00, $00, $01, $00, $02, $00, $00, $01, $00, $04, $00, $00, $03
    ; Case 107
    db $00, $00, $01, $00, $00, $00, $ff, $ff, $01, $00, $02, $00, $00, $00, $00, $02, $00, $00, $01, $00, $02, $00, $00, $01, $00, $04, $00, $00, $01
    ; Case 108
    db $ff, $ff, $ff, $ff, $fe, $ff, $ff, $ff, $02, $00, $00, $00, $00, $04, $00, $00, $00, $00, $02, $00, $00, $00, $00, $06, $00, $00, $00, $00, $01
