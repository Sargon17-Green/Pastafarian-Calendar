; Independent Foundation Native392 postconditions after real 46+12 rounds.
SECTION "Calendar Stage1 A0 Native392 bench", ROMX, BANK[1]
RunCalendarBowlAnswerBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 136
    ld [wTestCase], a    ; 392
    call .fillSentinel
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, 10
    ld [wCalendarAnswerInputSeal], a
    call CalendarBowlAnswerA0Direction
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkSentinel
    jp nz, .fail
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.zero:
    ld [hli], a
    dec b
    jr nz, .zero
    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, $6e
    ld [$a000], a
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail

    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, 10
    ld [wCalendarAnswerInputSeal], a
    ld de, .a1z10
    ld c, 1
    call .checkAnswer
    jp nz, .fail
    ld a, 11
    ld [wCalendarAnswerInputSeal], a
    ld de, .a1z11
    ld c, $ff
    call .checkAnswer
    jp nz, .fail
    ld a, 6
    ld [wCalendarAnswerInputBowl], a
    ld a, 12
    ld [wCalendarAnswerInputSeal], a
    ld de, .a6z12
    ld c, $ff
    call .checkAnswer
    jp nz, .fail
    ld a, 4
    ld [wCalendarAnswerInputBowl], a
    ld de, .a4z12
    ld c, 1
    call .checkAnswer
    jp nz, .fail

    call .fillSentinel
    xor a
    ld [wCalendarAnswerInputBowl], a
    call .expectInvalid
    jp nz, .fail
    ld a, 7
    ld [wCalendarAnswerInputBowl], a
    call .expectInvalid
    jp nz, .fail
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, 9
    ld [wCalendarAnswerInputSeal], a
    call .expectInvalid
    jp nz, .fail
    ld a, 13
    ld [wCalendarAnswerInputSeal], a
    call .expectInvalid
    jp nz, .fail
    ld a, 10
    ld [wCalendarAnswerInputSeal], a

    ld a, [wCalendarBowlOrderAt46]
    ld [wCalendarAnswerSavedByte], a
    ld a, 6
    ld [wCalendarBowlOrderAt46], a
    call .expectInvalid
    jp nz, .fail
    ld a, [wCalendarAnswerSavedByte]
    ld [wCalendarBowlOrderAt46], a
    ld a, [wCalendarBowlsOld+15]
    ld [wCalendarAnswerSavedByte], a
    ld a, $ff
    ld [wCalendarBowlsOld+15], a
    call .expectInvalid
    jp nz, .fail
    ld a, [wCalendarAnswerSavedByte]
    ld [wCalendarBowlsOld+15], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call .expectInvalid
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a

    ld a, [wCalendarActiveOwner]
    cp 70
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 72
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, [$a000]
    cp $6e
    jp nz, .fail
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarBowlAnswerA0Direction
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkSentinel
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, $a5
    ld [wTestResult], a
    ret

.checkAnswer:
    push bc
    push de
    call CalendarBowlAnswerA0Direction
    ld a, [wCalendarStatus]
    or a
    jr nz, .answerError
    pop de
    pop bc
    ld hl, wCalendarAnswerA0
    ld b, 16
    call .compare
    ret nz
    ld a, [wCalendarAnswerDirection]
    cp c
    ret
.answerError:
    pop de
    pop bc
    ld a, 1
    or a
    ret
.expectInvalid:
    call CalendarBowlAnswerA0Direction
    ld a, [wCalendarStatus]
    cp 2
    ret nz
    jp .checkSentinel
.fillSentinel:
    ld hl, wCalendarAnswerA0
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    ld [wCalendarAnswerDirection], a
    ret
.checkSentinel:
    ld hl, wCalendarAnswerA0
    ld b, 16
.check:
    ld a, [hli]
    cp $5a
    ret nz
    dec b
    jr nz, .check
    ld a, [wCalendarAnswerDirection]
    cp $5a
    ret
.compare:
    ld a, [de]
    cp [hl]
    ret nz
    inc hl
    inc de
    dec b
    jr nz, .compare
    xor a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.a1z10:
    db $0c,$6c,$81,$21,$da,$30,$89,$25,$a2,$da,$40,$5d,$4a,$49,$1c,$38
.a1z11:
    db $ab,$cd,$b5,$5a,$7e,$61,$a5,$99,$c7,$08,$05,$59,$ef,$cc,$57,$1a
.a6z12:
    db $d0,$e3,$9c,$5c,$e6,$a3,$10,$44,$c0,$8e,$4c,$a5,$d8,$80,$17,$6c
.a4z12:
    db $b1,$1a,$e6,$6b,$81,$ee,$80,$6d,$27,$d9,$65,$51,$1b,$7a,$92,$39
