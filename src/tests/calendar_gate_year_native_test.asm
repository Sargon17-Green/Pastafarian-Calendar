; Isolated Stage1 Native395: Foundation year-5000 candidate selection.
SECTION "Calendar Stage1 Native395 tests", ROMX, BANK[3]
RunCalendarGateYearBench::
    call SRAMEnable
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 139
    ld [wTestCase], a

    ; Idle is fail-closed and must not publish over the sentinel.
    call .fillSentinel
    call CalendarGateYearSelect
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkSentinel
    jp nz, .fail

    ; Start a real owner/ordinal lease; the table reader and sauce trampoline
    ; must restore ROM bank 3 after temporarily mapping banks 2 and 1.
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.clearPair:
    ld [hli], a
    dec b
    jr nz, .clearPair
    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarGateYearLeaseBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 1
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalSign], a
    ld a, 3
    call SRAMSelectBank
    ld a, $6e
    ld [$a000], a
    ld a, $c9
    ld [wPairCalcOffset], a
    ld a, $44
    ld [wPairCalcOffset+1], a
    ld a, $1a
    ld [wPairCalcOffset+2], a
    ld a, $ff
    ld [wPairCalcOffset+3], a

    ; c=Foundation as an absolute signed32 day count; preserve a different target
    ; and answer-input tuple around the complete map/histogram/answer path.
    ld hl, wPairTargetOffset
    ld a, $e9
    ld [hli], a
    ld a, $ff
    ld [hli], a
    ld [hli], a
    ld [hl], a
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

    call CalendarGateYearSelect
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarGateYearResultOpen
    ld de, .expectedOpen
    ld b, 4
    call .compare
    jp nz, .fail
    ld hl, wCalendarGateYearResultClose
    ld de, .expectedClose
    ld b, 4
    call .compare
    jp nz, .fail
    ld hl, wCalendarGateYearResultSpan
    ld de, .expectedSpan
    ld b, 2
    call .compare
    jp nz, .fail
    ld hl, wCalendarGateYearResultCount
    ld de, .expectedCount
    ld b, 2
    call .compare
    jp nz, .fail
    ld hl, wCalendarGateYearResultRank
    ld de, .expectedRank
    ld b, 2
    call .compare
    jp nz, .fail

    ; Pair and caller-owned answer inputs are restored exactly.
    ld hl, wPairCalcOffset
    ld de, .foundation32
    ld b, 4
    call .compare
    jp nz, .fail
    ld hl, wPairTargetOffset
    ld de, .targetSentinel
    ld b, 4
    call .compare
    jp nz, .fail
    ld a, [wCalendarAnswerInputBowl]
    cp 5
    jp nz, .fail
    ld a, [wCalendarAnswerInputSeal]
    cp 12
    jp nz, .fail
    ld a, [wCalendarSelectCount]
    cp 47
    jp nz, .fail
    ld a, [wCalendarSelectCount+1]
    or a
    jp nz, .fail
    ld a, [wCalendarSelectDirection]
    cp 2
    jp nz, .fail
    call .checkLeaseAndSram
    jp nz, .fail

    ; Snapshot the successful publication. Signed32 overflow at c=INT32_MAX
    ; must fail without changing any of the 18 public result bytes.
    ld hl, wCalendarGateYearResultOpen
    ld de, wCalendarGateYearResultSnapshot
    ld b, 18
    call CalendarGateYearCopyN
    ld hl, .maxSigned32
    ld de, wPairCalcOffset
    ld b, 4
    call CalendarGateYearCopyN
    call CalendarGateYearSelect
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .checkSnapshot
    jp nz, .fail
    ld hl, wPairCalcOffset
    ld de, .maxSigned32
    ld b, 4
    call .compare
    jp nz, .fail
    ld hl, wPairTargetOffset
    ld de, .targetSentinel
    ld b, 4
    call .compare
    jp nz, .fail
    ld a, [wCalendarAnswerInputBowl]
    cp 5
    jp nz, .fail
    ld a, [wCalendarAnswerInputSeal]
    cp 12
    jp nz, .fail
    ld a, [wCalendarSelectCount]
    cp 47
    jp nz, .fail
    ld a, [wCalendarSelectCount+1]
    or a
    jp nz, .fail
    ld a, [wCalendarSelectDirection]
    cp 2
    jp nz, .fail
    call .checkLeaseAndSram
    jp nz, .fail

    call CalendarGateYearLeaseAbort
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
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail

    ; Idle after release must also leave the successful publication untouched.
    call CalendarGateYearSelect
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkSnapshot
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret

.checkLeaseAndSram:
    ld a, [wCalendarActive]
    cp 1
    ret nz
    ld a, [wCalendarActiveOwner]
    cp 70
    ret nz
    ld a, [wLeaseTable+3]
    cp 72
    ret nz
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6e
    ret

.checkSnapshot:
    ld hl, wCalendarGateYearResultOpen
    ld de, wCalendarGateYearResultSnapshot
    ld b, 18
.compareSnapshot:
    ld a, [de]
    cp [hl]
    ret nz
    inc hl
    inc de
    dec b
    jr nz, .compareSnapshot
    xor a
    ret

.fillSentinel:
    ld hl, wCalendarGateYearResultOpen
    ld b, 18
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    ret

.checkSentinel:
    ld hl, wCalendarGateYearResultOpen
    ld b, 18
.check:
    ld a, [hli]
    cp $5a
    ret nz
    dec b
    jr nz, .check
    xor a
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

.foundation32:
    db $c9,$44,$1a,$ff
.targetSentinel:
    db $e9,$ff,$ff,$ff
.maxSigned32:
    db $ff,$ff,$ff,$7f
.expectedOpen:
    db $d9,$3c,$1a,$ff
.expectedClose:
    db $6d,$4d,$1a,$ff
.expectedSpan:
    dw 4244
.expectedCount:
    dw 43
.expectedRank:
    dw 15
