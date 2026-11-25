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
    call .snapshotInputs
    call CalendarBowlAnswerShortRank
    call .checkInputSnapshot
    jp nz, .fail
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
    ld a, 1
    ld [wCalendarOrdinalLength], a
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

    ; Four Foundation cases above; all remaining bowl/seal pairs are source-derived.
    ld a, 14
    ld [wCalendarAnswerSavedByte], a
    ld hl, .sourceCases
.sourceCaseLoop:
    ld a, [hli]
    ld [wCalendarAnswerInputBowl], a
    ld a, [hli]
    ld [wCalendarAnswerInputSeal], a
    ld a, [hli]
    ld [wCalendarSelectCount], a
    ld a, [hli]
    ld [wCalendarSelectCount+1], a
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    push hl
    call .checkAnswer
    pop hl
    jp nz, .fail
    ; Keep HL on the next table row; do not replace it with the counter address.
    ld a, [wCalendarAnswerSavedByte]
    dec a
    ld [wCalendarAnswerSavedByte], a
    jr nz, .sourceCaseLoop

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
    ld a, 2
    ld [wCalendarOrdinalSign], a
    call .expectInvalid
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ; Negative zero is independently invalid even with an otherwise valid lease.
    xor a
    ld [wCalendarOrdinalLength], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call .expectInvalid
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld a, 1
    ld [wCalendarOrdinalLength], a

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
    call .snapshotInputs
    call CalendarBowlAnswerShortRank
    call .checkInputSnapshot
    jp nz, .fail
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
    call .snapshotInputs
    call CalendarBowlAnswerShortRank
    call .checkInputSnapshot
    jr nz, .answerError
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
    call .snapshotInputs
    call CalendarBowlAnswerShortRank
    call .checkInputSnapshot
    ret nz
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
.snapshotInputs:
    ; Preserve the complete source tuple around each answer/rank call:
    ; six Q residues, orderAt46, ordinal sign/length, and live ordinal byte.
    push bc
    push de
    push hl
    ld hl, wCalendarBowlsOld
    ld de, wCalendarPostStirSavedBowls
    ld b, 96
.copyQ:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyQ
    ld hl, wCalendarBowlOrderAt46
    ld de, wCalendarBowlOrderScratch
    ld b, 6
.copyOrder:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyOrder
    ld hl, wCalendarOrdinalSign
    ld de, wCalendarPostStirSum
    ld b, 4
.copyOrdinal:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyOrdinal
    ld a, [wCalendarActive]
    or a
    jr z, .noOrdinalByte
    ld a, [wCalendarOrdinalLength]
    ld b, a
    ld a, [wCalendarOrdinalLength+1]
    or b
    ld b, a
    ld a, [wCalendarOrdinalLength+2]
    or b
    jr z, .noOrdinalByte
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, [$a000]
    ld [wCalendarPostStirSum+4], a
    jr .snapshotDone
.noOrdinalByte:
    ld a, $ff
    ld [wCalendarPostStirSum+4], a
.snapshotDone:
    pop hl
    pop de
    pop bc
    ret

.checkInputSnapshot:
    push bc
    push de
    push hl
    ld hl, wCalendarBowlsOld
    ld de, wCalendarPostStirSavedBowls
    ld b, 96
.checkQ:
    ld a, [hli]
    ld c, a
    ld a, [de]
    cp c
    jr nz, .changed
    inc de
    dec b
    jr nz, .checkQ
    ld hl, wCalendarBowlOrderAt46
    ld de, wCalendarBowlOrderScratch
    ld b, 6
.checkOrder:
    ld a, [hli]
    ld c, a
    ld a, [de]
    cp c
    jr nz, .changed
    inc de
    dec b
    jr nz, .checkOrder
    ld hl, wCalendarOrdinalSign
    ld de, wCalendarPostStirSum
    ld b, 4
.checkOrdinal:
    ld a, [hli]
    ld c, a
    ld a, [de]
    cp c
    jr nz, .changed
    inc de
    dec b
    jr nz, .checkOrdinal
    ld a, [wCalendarActive]
    or a
    jr z, .checkNoOrdinalByte
    ld a, [wCalendarOrdinalLength]
    ld b, a
    ld a, [wCalendarOrdinalLength+1]
    or b
    ld b, a
    ld a, [wCalendarOrdinalLength+2]
    or b
    jr z, .checkNoOrdinalByte
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, [$a000]
    ld c, a
    ld a, [wCalendarPostStirSum+4]
    cp c
    jr nz, .changed
    jr .same
.checkNoOrdinalByte:
    ld a, [wCalendarPostStirSum+4]
    cp $ff
    jr nz, .changed
.same:
    xor a
    jr .snapshotCheckDone
.changed:
    ld a, 1
    or a
.snapshotCheckDone:
    pop hl
    pop de
    pop bc
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
    call .snapshotInputs
    call CalendarBowlAnswerShortRank.select
    pop de
    call .checkInputSnapshot
    jr nz, .syntheticError
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
; Fourteen source-derived nonfoundation vectors from the real Native393 Q/orderAt46.
.sourceCases:
    db 1, 12, 3, 0, $ff
    dw .a1z12
    db 2, 10, 7, 0, $01
    dw .a2z10
    db 2, 11, 138, 0, $01
    dw .a2z11
    db 2, 12, 154, 3, $ff
    dw .a2z12
    db 3, 10, 146, 22, $ff
    dw .a3z10
    db 3, 11, 100, 74, $ff
    dw .a3z11
    db 3, 12, 3, 0, $01
    dw .a3z12
    db 4, 10, 7, 0, $01
    dw .a4z10
    db 4, 11, 138, 0, $01
    dw .a4z11
    db 5, 10, 154, 3, $ff
    dw .a5z10
    db 5, 11, 146, 22, $ff
    dw .a5z11
    db 5, 12, 100, 74, $01
    dw .a5z12
    db 6, 10, 3, 0, $ff
    dw .a6z10
    db 6, 11, 7, 0, $01
    dw .a6z11

.a1z12:
    db $4b,$2f,$ea,$93,$22,$92,$c1,$0d,$ed,$36,$c9,$54,$94,$50,$93,$7c
    dw 2
    db $4b,$2f,$ea,$93,$22,$92,$c1,$0d,$ed,$36,$c9,$54,$94,$50,$93,$7c

.a2z10:
    db $e2,$21,$aa,$ce,$70,$80,$8f,$82,$57,$64,$6f,$a5,$26,$48,$85,$2f
    dw 3
    db $e2,$21,$aa,$ce,$70,$80,$8f,$82,$57,$64,$6f,$a5,$26,$48,$85,$2f

.a2z11:
    db $a9,$96,$2f,$20,$6e,$ab,$ee,$8e,$2b,$52,$a7,$1e,$72,$58,$b1,$6f
    dw 83
    db $a9,$96,$2f,$20,$6e,$ab,$ee,$8e,$2b,$52,$a7,$1e,$72,$58,$b1,$6f

.a2z12:
    db $73,$0b,$b5,$71,$6b,$d6,$4d,$9b,$ff,$3f,$df,$97,$bd,$68,$dd,$2f
    dw 329
    db $73,$0b,$b5,$71,$6b,$d6,$4d,$9b,$ff,$3f,$df,$97,$bd,$68,$dd,$2f

.a3z10:
    db $7d,$36,$80,$9f,$9a,$d6,$94,$46,$4d,$65,$60,$34,$b4,$91,$dd,$1c
    dw 2639
    db $7d,$36,$80,$9f,$9a,$d6,$94,$46,$4d,$65,$60,$34,$b4,$91,$dd,$1c

.a3z11:
    db $91,$31,$d1,$1b,$bc,$c3,$44,$12,$1d,$c5,$b1,$94,$d6,$d8,$a9,$6e
    dw 1709
    db $91,$31,$d1,$1b,$bc,$c3,$44,$12,$1d,$c5,$b1,$94,$d6,$d8,$a9,$6e

.a3z12:
    db $a8,$2c,$22,$98,$dd,$b0,$f4,$dd,$ec,$24,$03,$f5,$f8,$1f,$76,$40
    dw 3
    db $a8,$2c,$22,$98,$dd,$b0,$f4,$dd,$ec,$24,$03,$f5,$f8,$1f,$76,$40

.a4z10:
    db $01,$ff,$3b,$c8,$af,$4c,$6a,$50,$db,$74,$8f,$e6,$ac,$29,$7e,$21
    dw 1
    db $01,$ff,$3b,$c8,$af,$4c,$6a,$50,$db,$74,$8f,$e6,$ac,$29,$7e,$21

.a4z11:
    db $d8,$0c,$11,$9a,$98,$9d,$f5,$5e,$01,$a7,$fa,$1b,$e4,$51,$88,$2d
    dw 62
    db $d8,$0c,$11,$9a,$98,$9d,$f5,$5e,$01,$a7,$fa,$1b,$e4,$51,$88,$2d

.a5z10:
    db $f7,$16,$06,$cc,$e7,$a0,$b5,$7c,$04,$d1,$8e,$3d,$d2,$11,$2e,$09
    dw 447
    db $f7,$16,$06,$cc,$e7,$a0,$b5,$7c,$04,$d1,$8e,$3d,$d2,$11,$2e,$09

.a5z11:
    db $63,$c9,$e9,$5d,$06,$f6,$8c,$de,$a6,$1f,$de,$49,$da,$64,$bc,$5b
    dw 937
    db $63,$c9,$e9,$5d,$06,$f6,$8c,$de,$a6,$1f,$de,$49,$da,$64,$bc,$5b

.a5z12:
    db $d2,$7b,$cd,$ef,$24,$4b,$64,$40,$49,$6e,$2d,$56,$e2,$b7,$4a,$2e
    dw 3122
    db $d2,$7b,$cd,$ef,$24,$4b,$64,$40,$49,$6e,$2d,$56,$e2,$b7,$4a,$2e

.a6z10:
    db $30,$dc,$ee,$9d,$02,$c6,$51,$69,$d4,$e0,$7c,$6c,$56,$8e,$70,$1d
    dw 1
    db $30,$dc,$ee,$9d,$02,$c6,$51,$69,$d4,$e0,$7c,$6c,$56,$8e,$70,$1d

.a6z11:
    db $ff,$df,$45,$7d,$f4,$34,$b1,$56,$ca,$b7,$e4,$88,$97,$07,$c4,$44
    dw 3
    db $ff,$df,$45,$7d,$f4,$34,$b1,$56,$ca,$b7,$e4,$88,$97,$07,$c4,$44
