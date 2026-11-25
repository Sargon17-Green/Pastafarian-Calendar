; Independent Foundation Native393 postconditions after real 46+12 rounds.
SECTION "Calendar Stage1 A0 Native393 bench", ROMX, BANK[1]
RunCalendarBowlAnswerRankBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 137
    ld [wTestCase], a    ; 393
    call .fillSentinel
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, 10
    ld [wCalendarAnswerInputSeal], a
    call CalendarBowlAnswerShortRank
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
    ld a, 1
    ld [wCalendarSelectCount], a
    ld a, 0
    ld [wCalendarSelectCount+1], a
    ld de, .a1z10
    ld c, 1
    call .checkAnswer
    jp nz, .fail
    ld a, 11
    ld [wCalendarAnswerInputSeal], a
    ld a, 2
    ld [wCalendarSelectCount], a
    ld a, 0
    ld [wCalendarSelectCount+1], a
    ld de, .a1z11
    ld c, $ff
    call .checkAnswer
    jp nz, .fail
    ld a, 6
    ld [wCalendarAnswerInputBowl], a
    ld a, 12
    ld [wCalendarAnswerInputSeal], a
    ld a, 154
    ld [wCalendarSelectCount], a
    ld a, 3
    ld [wCalendarSelectCount+1], a
    ld de, .a6z12
    ld c, $ff
    call .checkAnswer
    jp nz, .fail
    ld a, 4
    ld [wCalendarAnswerInputBowl], a
    ld a, 100
    ld [wCalendarSelectCount], a
    ld a, 74
    ld [wCalendarSelectCount+1], a
    ld de, .a4z12
    ld c, 1
    call .checkAnswer
    jp nz, .fail

    ld de, .s0
    call .synthetic
    jp nz, .fail
    ld de, .s1
    call .synthetic
    jp nz, .fail
    ld de, .s2
    call .synthetic
    jp nz, .fail
    ld de, .s3
    call .synthetic
    jp nz, .fail
    ld de, .s4
    call .synthetic
    jp nz, .fail
    ld de, .s5
    call .synthetic
    jp nz, .fail
    ld de, .s6
    call .synthetic
    jp nz, .fail
    ld de, .s7
    call .synthetic
    jp nz, .fail
    ld de, .s8
    call .synthetic
    jp nz, .fail
    ld de, .s9
    call .synthetic
    jp nz, .fail
    ld de, .s10
    call .synthetic
    jp nz, .fail
    ld de, .s11
    call .synthetic
    jp nz, .fail
    ld de, .s12
    call .synthetic
    jp nz, .fail
    ld de, .s13
    call .synthetic
    jp nz, .fail
    ld de, .s14
    call .synthetic
    jp nz, .fail
    ld de, .s15
    call .synthetic
    jp nz, .fail
    ld de, .s16
    call .synthetic
    jp nz, .fail
    ld de, .s17
    call .synthetic
    jp nz, .fail
    ld de, .s18
    call .synthetic
    jp nz, .fail
    ld de, .s19
    call .synthetic
    jp nz, .fail
    ld de, .s20
    call .synthetic
    jp nz, .fail
    ld de, .s21
    call .synthetic
    jp nz, .fail
    ld de, .s22
    call .synthetic
    jp nz, .fail
    ld de, .s23
    call .synthetic
    jp nz, .fail
    ld de, .s24
    call .synthetic
    jp nz, .fail
    ld de, .s25
    call .synthetic
    jp nz, .fail
    call .fillSentinel
    xor a
    ld [wCalendarSelectCount], a
    ld [wCalendarSelectCount+1], a
    call .expectInvalid
    jp nz, .fail
    ld a, $65
    ld [wCalendarSelectCount], a
    ld a, $4a
    ld [wCalendarSelectCount+1], a
    call .expectInvalid
    jp nz, .fail
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
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
    call CalendarBowlAnswerShortRank
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
    call CalendarBowlAnswerShortRank
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
    ret nz
    ld hl, wCalendarSelectRank
    ld b, 2
    call .compare
    ret nz
    ld hl, wCalendarAnswerAccepted
    ld b, 16
    jp .compare
.answerError:
    pop de
    pop bc
    ld a, 1
    or a
    ret
.expectInvalid:
    call CalendarBowlAnswerShortRank
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
    ld [wCalendarSelectRank], a
    ld [wCalendarSelectRank+1], a
    ld hl, wCalendarAnswerAccepted
    ld b, 16
.fillAccepted:
    ld [hli], a
    dec b
    jr nz, .fillAccepted
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
    ret nz
    ld a, [wCalendarSelectRank]
    cp $5a
    ret nz
    ld a, [wCalendarSelectRank+1]
    cp $5a
    ret nz
    ld hl, wCalendarAnswerAccepted
    ld b, 16
.checkAccepted:
    ld a, [hli]
    cp $5a
    ret nz
    dec b
    jr nz, .checkAccepted
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
    dw 1
    db $0c,$6c,$81,$21,$da,$30,$89,$25,$a2,$da,$40,$5d,$4a,$49,$1c,$38
.a1z11:
    db $ab,$cd,$b5,$5a,$7e,$61,$a5,$99,$c7,$08,$05,$59,$ef,$cc,$57,$1a
    dw 1
    db $ab,$cd,$b5,$5a,$7e,$61,$a5,$99,$c7,$08,$05,$59,$ef,$cc,$57,$1a
.a6z12:
    db $d0,$e3,$9c,$5c,$e6,$a3,$10,$44,$c0,$8e,$4c,$a5,$d8,$80,$17,$6c
    dw 810
    db $d0,$e3,$9c,$5c,$e6,$a3,$10,$44,$c0,$8e,$4c,$a5,$d8,$80,$17,$6c
.a4z12:
    db $b1,$1a,$e6,$6b,$81,$ee,$80,$6d,$27,$d9,$65,$51,$1b,$7a,$92,$39
    dw 11525
    db $b1,$1a,$e6,$6b,$81,$ee,$80,$6d,$27,$d9,$65,$51,$1b,$7a,$92,$39

; Synthetic full-width boundary rows use literal independent ring traversal.
.synthetic:
    push de
    ld hl, wCalendarSelectValue
    ld b, 16
.copyInput:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .copyInput
    ld a, [de]
    inc de
    ld [wCalendarSelectCount], a
    ld a, [de]
    inc de
    ld [wCalendarSelectCount+1], a
    ld a, [de]
    inc de
    ld [wCalendarSelectDirection], a
    push de
    call CalendarBowlAnswerShortRank.select
    pop de
    ld a, [wCalendarStatus]
    or a
    jr nz, .syntheticError
    ld hl, wCalendarSelectRank
    ld b, 2
    call .compare
    jr nz, .syntheticError
    ld hl, wCalendarAnswerAccepted
    ld b, 16
    call .compare
    jr nz, .syntheticError
    pop de
    ld hl, wCalendarSelectValue
    ld b, 16
    jp .compare
.syntheticError:
    pop de
    ld a, 1
    or a
    ret
.s0:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 1
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s1:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 1
    db 2
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s2:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 1
    db 1
    dw 1
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s3:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 1
    db 2
    dw 1
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s4:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 2
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s5:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 2
    db 2
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s6:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 2
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s7:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 2
    db 2
    dw 2
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s8:
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 2
    db 1
    dw 2
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s9:
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 2
    db 2
    dw 2
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s10:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 922
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s11:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 922
    db 2
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s12:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s13:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 2
    dw 922
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s14:
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 1
    dw 922
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s15:
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 2
    dw 922
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s16:
    db $23,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s17:
    db $23,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 922
    db 2
    dw 922
    db $22,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s18:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 19044
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s19:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    dw 19044
    db 2
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s20:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s21:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 2
    dw 19044
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s22:
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 1
    dw 19044
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s23:
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 2
    dw 19044
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
.s24:
    db $45,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 1
    dw 1
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.s25:
    db $45,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    dw 19044
    db 2
    dw 19044
    db $44,$bd,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
