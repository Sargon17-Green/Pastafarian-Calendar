SECTION "Calendar Stage1 gate gap Native394 result ABI", WRAM0
wNative394ResultCount:: ds 1
wNative394ResultCursor:: ds 2
wCalendarGateGapNativeResults:: ds 160
wNative394ExpectedIndex:: ds 2
wNative394ExpectedDirection:: ds 1

SECTION "Calendar Stage1 gate gap Native394 tests", ROMX, BANK[1]
RunCalendarGateGapBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 138
    ld [wTestCase], a
    ld hl, wCalendarGateGapNativeResults
    ld a, l
    ld [wNative394ResultCursor], a
    ld a, h
    ld [wNative394ResultCursor+1], a
    xor a
    ld [wNative394ResultCount], a

    ; Idle must fail closed without publishing.
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    xor a
    ld [wCalendarGateGapIndex+1], a
    ld a, 1
    ld [wCalendarGateGapDirection], a
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail

    ; Begin one owner/ordinal lease. The gap primitive must not mutate it.
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.clearOffsets:
    ld [hli], a
    dec b
    jr nz, .clearOffsets
    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld a, 1
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, $6e
    ld [$a000], a
    call .setPairSentinels
    call .setInputSentinels

    ; Four differential vectors: both directions at n=1 and the 512 bound.
    ld hl, .cases
    call .runGap
    jp nz, .fail
    call .runGap
    jp nz, .fail
    call .runGap
    jp nz, .fail
    call .runGap
    jp nz, .fail
    ld a, [wNative394ResultCount]
    cp 4
    jp nz, .fail

    ; Owner, lease and SRAM payload remain intact after all four computations.
    ld a, [wCalendarActive]
    cp 1
    jp nz, .fail
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

    ; Invalid index zero.
    call .setResultSentinel
    xor a
    ld [wCalendarGateGapIndex], a
    ld [wCalendarGateGapIndex+1], a
    ld a, 1
    ld [wCalendarGateGapDirection], a
    call .setExpectedFromInput
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail
    call .checkPreserved
    jp nz, .fail

    ; Index 513 is outside the explicit 512-step implementation bound.
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    ld a, 2
    ld [wCalendarGateGapIndex+1], a
    ld a, 1
    ld [wCalendarGateGapDirection], a
    call .setExpectedFromInput
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail
    call .checkPreserved
    jp nz, .fail

    ; Direction zero is invalid.
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    xor a
    ld [wCalendarGateGapIndex+1], a
    ld [wCalendarGateGapDirection], a
    call .setExpectedFromInput
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail
    call .checkPreserved
    jp nz, .fail

    ; Direction three is invalid.
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    xor a
    ld [wCalendarGateGapIndex+1], a
    ld a, 3
    ld [wCalendarGateGapDirection], a
    call .setExpectedFromInput
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail
    call .checkPreserved
    jp nz, .fail

    ; Negative-zero ordinal is rejected before pair or answer-input mutation.
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    xor a
    ld [wCalendarGateGapIndex+1], a
    ld a, 1
    ld [wCalendarGateGapDirection], a
    call .setExpectedFromInput
    xor a
    ld [wCalendarOrdinalLength], a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail
    call .checkPreserved
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld a, 1
    ld [wCalendarOrdinalLength], a

    ; Release and scrub the lease; a subsequent call is idle and atomic.
    xor a
    ld [wCalendarStatus], a
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarActive]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, [$a000]
    or a
    jp nz, .fail
    call .setResultSentinel
    ld a, 1
    ld [wCalendarGateGapIndex], a
    xor a
    ld [wCalendarGateGapIndex+1], a
    ld a, 1
    ld [wCalendarGateGapDirection], a
    call CalendarGateGap
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkResultSentinel
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret

.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.runGap:
    ld a, [hli]
    ld [wCalendarGateGapIndex], a
    ld [wNative394ExpectedIndex], a
    ld a, [hli]
    ld [wCalendarGateGapIndex+1], a
    ld [wNative394ExpectedIndex+1], a
    ld a, [hli]
    ld [wCalendarGateGapDirection], a
    ld [wNative394ExpectedDirection], a
    push hl
    call CalendarGateGap
    pop hl
    ld a, [wCalendarStatus]
    or a
    jr nz, .runGapFail
    push hl
    call .checkPreserved
    jr nz, .runGapSavedFail
    call .checkGapRange
    jr nz, .runGapSavedFail
    call .record
    pop hl
    xor a
    ret
.runGapSavedFail:
    pop hl
.runGapFail:
    ld a, 1
    or a
    ret

.checkPreserved:
    ld hl, wCalendarGateGapIndex
    ld de, wNative394ExpectedIndex
    ld b, 2
    call .compare
    ret nz
    ld a, [wCalendarGateGapDirection]
    ld b, a
    ld a, [wNative394ExpectedDirection]
    cp b
    ret nz
    ld a, [wCalendarAnswerInputBowl]
    cp 5
    ret nz
    ld a, [wCalendarAnswerInputSeal]
    cp 12
    ret nz
    ld a, [wCalendarSelectCount]
    cp 47
    ret nz
    ld a, [wCalendarSelectCount+1]
    or a
    ret nz
    ld a, [wCalendarSelectDirection]
    cp 2
    ret nz
    ld hl, wPairCalcOffset
    ld de, .calcSentinel
    ld b, 4
    call .compare
    ret nz
    ld hl, wPairTargetOffset
    ld de, .targetSentinel
    ld b, 4
    jp .compare

.checkGapRange:
    ld a, [wCalendarGateGapResult+1]
    cp 3
    jr c, .upperOkay
    jr nz, .badRange
    ld a, [wCalendarGateGapResult]
    cp $c4
    jr nc, .badRange
.upperOkay:
    ld a, [wCalendarGateGapResult+1]
    or a
    jr nz, .rangeOkay
    ld a, [wCalendarGateGapResult]
    cp 42
    jr c, .badRange
.rangeOkay:
    xor a
    ret
.badRange:
    ld a, 1
    or a
    ret

.record:
    ld a, [wNative394ResultCursor]
    ld e, a
    ld a, [wNative394ResultCursor+1]
    ld d, a
    ld hl, wCalendarGateGapIndex
    ld b, 2
    call .copyToDE
    ld a, [wCalendarGateGapDirection]
    ld [de], a
    inc de
    ld hl, wCalendarGateGapResult
    ld b, 2
    call .copyToDE
    ld hl, wCalendarAnswerA0
    ld b, 16
    call .copyToDE
    ld a, [wCalendarAnswerDirection]
    ld [de], a
    inc de
    ld hl, wCalendarSelectRank
    ld b, 2
    call .copyToDE
    ld hl, wCalendarAnswerAccepted
    ld b, 16
    call .copyToDE
    ld a, e
    ld [wNative394ResultCursor], a
    ld a, d
    ld [wNative394ResultCursor+1], a
    ld hl, wNative394ResultCount
    inc [hl]
    ret

.setExpectedFromInput:
    ld a, [wCalendarGateGapIndex]
    ld [wNative394ExpectedIndex], a
    ld a, [wCalendarGateGapIndex+1]
    ld [wNative394ExpectedIndex+1], a
    ld a, [wCalendarGateGapDirection]
    ld [wNative394ExpectedDirection], a
    ret

.setPairSentinels:
    ld hl, wPairCalcOffset
    ld a, $11
    ld [hli], a
    xor a
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ld hl, wPairTargetOffset
    ld a, $e9
    ld [hli], a
    ld a, $ff
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ret

.setInputSentinels:
    ld a, 5
    ld [wCalendarAnswerInputBowl], a
    ld a, 12
    ld [wCalendarAnswerInputSeal], a
    ld a, 47
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
    ret

.setResultSentinel:
    ld a, $5a
    ld [wCalendarGateGapResult], a
    ld [wCalendarGateGapResult+1], a
    ret

.checkResultSentinel:
    ld a, [wCalendarGateGapResult]
    cp $5a
    ret nz
    ld a, [wCalendarGateGapResult+1]
    cp $5a
    ret

.compare:
    ld a, [de]
    cp [hl]
    ret nz
    inc de
    inc hl
    dec b
    jr nz, .compare
    xor a
    ret

.copyToDE:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyToDE
    ret

.cases:
    dw 1
    db 1
    dw 1
    db 2
    dw 512
    db 1
    dw 512
    db 2

.calcSentinel:
    db $11, $00, $00, $00
.targetSentinel:
    db $e9, $ff, $ff, $ff
