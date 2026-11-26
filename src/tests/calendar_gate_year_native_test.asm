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
    jp nz, .fail1
    call .checkSentinel
    jp nz, .fail2

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
    jp nz, .fail3
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
    jp nz, .fail4
    ld hl, wCalendarGateYearResultOpen
    ld de, .expectedOpen
    ld b, 4
    call .compare
    jp nz, .fail5
    ld hl, wCalendarGateYearResultClose
    ld de, .expectedClose
    ld b, 4
    call .compare
    jp nz, .fail6
    ld hl, wCalendarGateYearResultSpan
    ld de, .expectedSpan
    ld b, 2
    call .compare
    jp nz, .fail7
    ld hl, wCalendarGateYearResultCount
    ld de, .expectedCount
    ld b, 2
    call .compare
    jp nz, .fail8
    ld hl, wCalendarGateYearResultRank
    ld de, .expectedRank
    ld b, 2
    call .compare
    jp nz, .fail9

    ; Pair and caller-owned answer inputs are restored exactly.
    ld hl, wPairCalcOffset
    ld de, .foundation32
    ld b, 4
    call .compare
    jp nz, .fail10
    ld hl, wPairTargetOffset
    ld de, .targetSentinel
    ld b, 4
    call .compare
    jp nz, .fail11
    ld a, [wCalendarAnswerInputBowl]
    cp 5
    jp nz, .fail12
    ld a, [wCalendarAnswerInputSeal]
    cp 12
    jp nz, .fail13
    ld a, [wCalendarSelectCount]
    cp 47
    jp nz, .fail14
    ld a, [wCalendarSelectCount+1]
    or a
    jp nz, .fail15
    ld a, [wCalendarSelectDirection]
    cp 2
    jp nz, .fail16
    call .checkLeaseAndSram
    jp nz, .fail17

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
    jp nz, .fail18
    call .checkSnapshot
    jp nz, .fail19
    ld hl, wPairCalcOffset
    ld de, .maxSigned32
    ld b, 4
    call .compare
    jp nz, .fail20
    ld hl, wPairTargetOffset
    ld de, .targetSentinel
    ld b, 4
    call .compare
    jp nz, .fail21
    ld a, [wCalendarAnswerInputBowl]
    cp 5
    jp nz, .fail22
    ld a, [wCalendarAnswerInputSeal]
    cp 12
    jp nz, .fail23
    ld a, [wCalendarSelectCount]
    cp 47
    jp nz, .fail24
    ld a, [wCalendarSelectCount+1]
    or a
    jp nz, .fail25
    ld a, [wCalendarSelectDirection]
    cp 2
    jp nz, .fail26
    call .checkLeaseAndSram
    jp nz, .fail27

    call CalendarGateYearLeaseAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail28
    ld a, [wCalendarActive]
    or a
    jp nz, .fail29
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail30
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail31

    ; Idle after release must also leave the successful publication untouched.
    call CalendarGateYearSelect
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail32
    call .checkSnapshot
    jp nz, .fail33

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

; On failure only, publish a distinct case number 401..433.
; Success remains A5/395/40; wait_for_completion still recognizes E0.
; Failure case 401: original check line 19.
.fail1:
    ld a, 145
    jp .failDiagnostic

; Failure case 402: original check line 21.
.fail2:
    ld a, 146
    jp .failDiagnostic

; Failure case 403: original check line 39.
.fail3:
    ld a, 147
    jp .failDiagnostic

; Failure case 404: original check line 80.
.fail4:
    ld a, 148
    jp .failDiagnostic

; Failure case 405: original check line 85.
.fail5:
    ld a, 149
    jp .failDiagnostic

; Failure case 406: original check line 90.
.fail6:
    ld a, 150
    jp .failDiagnostic

; Failure case 407: original check line 95.
.fail7:
    ld a, 151
    jp .failDiagnostic

; Failure case 408: original check line 100.
.fail8:
    ld a, 152
    jp .failDiagnostic

; Failure case 409: original check line 105.
.fail9:
    ld a, 153
    jp .failDiagnostic

; Failure case 410: original check line 112.
.fail10:
    ld a, 154
    jp .failDiagnostic

; Failure case 411: original check line 117.
.fail11:
    ld a, 155
    jp .failDiagnostic

; Failure case 412: original check line 120.
.fail12:
    ld a, 156
    jp .failDiagnostic

; Failure case 413: original check line 123.
.fail13:
    ld a, 157
    jp .failDiagnostic

; Failure case 414: original check line 126.
.fail14:
    ld a, 158
    jp .failDiagnostic

; Failure case 415: original check line 129.
.fail15:
    ld a, 159
    jp .failDiagnostic

; Failure case 416: original check line 132.
.fail16:
    ld a, 160
    jp .failDiagnostic

; Failure case 417: original check line 134.
.fail17:
    ld a, 161
    jp .failDiagnostic

; Failure case 418: original check line 149.
.fail18:
    ld a, 162
    jp .failDiagnostic

; Failure case 419: original check line 151.
.fail19:
    ld a, 163
    jp .failDiagnostic

; Failure case 420: original check line 156.
.fail20:
    ld a, 164
    jp .failDiagnostic

; Failure case 421: original check line 161.
.fail21:
    ld a, 165
    jp .failDiagnostic

; Failure case 422: original check line 164.
.fail22:
    ld a, 166
    jp .failDiagnostic

; Failure case 423: original check line 167.
.fail23:
    ld a, 167
    jp .failDiagnostic

; Failure case 424: original check line 170.
.fail24:
    ld a, 168
    jp .failDiagnostic

; Failure case 425: original check line 173.
.fail25:
    ld a, 169
    jp .failDiagnostic

; Failure case 426: original check line 176.
.fail26:
    ld a, 170
    jp .failDiagnostic

; Failure case 427: original check line 178.
.fail27:
    ld a, 171
    jp .failDiagnostic

; Failure case 428: original check line 183.
.fail28:
    ld a, 172
    jp .failDiagnostic

; Failure case 429: original check line 186.
.fail29:
    ld a, 173
    jp .failDiagnostic

; Failure case 430: original check line 189.
.fail30:
    ld a, 174
    jp .failDiagnostic

; Failure case 431: original check line 194.
.fail31:
    ld a, 175
    jp .failDiagnostic

; Failure case 432: original check line 200.
.fail32:
    ld a, 176
    jp .failDiagnostic

; Failure case 433: original check line 202.
.fail33:
    ld a, 177
    jp .failDiagnostic

.failDiagnostic:
    ld [wTestCase], a
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
