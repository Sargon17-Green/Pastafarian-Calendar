; Native341..357: exact 127-bit short Equal Selection rank.
; Synthetic A0/direction inputs exercise the same short mechanism used by
; gate-gap 922 and the year-5000/NEXT11/PREVIOUS12 candidate counts.
SECTION "Calendar short equal selection Native tests", ROMX, BANK[1]
RunCalendarAnswerSelectTests::
    ld a, 1
    ld [wTestCaseHi], a

    ; 341: idle returns 6 and preserves the previous rank.
    ld a, 85
    ld [wTestCase], a
    call .setSentinelRank
    call .fillOne
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    call CalendarSelectShortRank
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .expectSentinelRank

    ; 342: acquire a one-bank active owner and preserve a physical SRAM sentinel.
    ld a, 86
    ld [wTestCase], a
    ld a, 65
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $6a
    ld [$a000], a

    ; 343: N=0 is invalid; output rank is immutable.
    ld a, 87
    ld [wTestCase], a
    call .setSentinelRank
    call .fillOne
    xor a
    ld [wCalendarSelectCount], a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    call .expectInvalid

    ; 344: N=19045 exceeds the proven candidate-count bound.
    ld a, 88
    ld [wTestCase], a
    call .setSentinelRank
    call .fillOne
    ld a, $65
    ld [wCalendarSelectCount], a
    ld a, $4a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    call .expectInvalid

    ; 345: direction must be NEXT (+1) or PREVIOUS (-1).
    ld a, 89
    ld [wTestCase], a
    call .setSentinelRank
    call .fillOne
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 3
    ld [wCalendarSelectDirection], a
    call .expectInvalid

    ; 346: A0=0 is not a canonical SAVE residue.
    ld a, 90
    ld [wTestCase], a
    call .setSentinelRank
    call .clearValue
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    call .expectInvalid

    ; 347: bit 127 set is outside the 127-bit residue domain.
    ld a, 91
    ld [wTestCase], a
    call .setSentinelRank
    call .clearValue
    ld a, $80
    ld [wCalendarSelectValue+15], a
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    call .expectInvalid

    ; 348: N=1, A0=M, forward -> rank 1.
    ld a, 92
    ld [wTestCase], a
    call .fillM
    ld a, 1
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    ld a, 1
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 349: N=2, A0=M, forward rejected tail -> rank 1.
    ld a, 93
    ld [wTestCase], a
    call .fillM
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    ld a, 1
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 350: N=2, A0=M, backward rejected tail -> rank N=2.
    ld a, 94
    ld [wTestCase], a
    call .fillM
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
    ld a, 2
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 351: N=2, A0=L=M-1 exactly -> rank 2.
    ld a, 95
    ld [wTestCase], a
    call .fillMMinus1
    ld a, 2
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    ld a, 2
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 352: N=3, A0=L=M-1 exactly -> rank 3.
    ld a, 96
    ld [wTestCase], a
    call .fillMMinus1
    ld a, 3
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    ld a, 3
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 353: N=5, A0=L-1=M-3 -> rank 4.
    ld a, 97
    ld [wTestCase], a
    call .fillMMinus3
    ld a, 5
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
    ld a, 4
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 354: N=922 (gate-gap selection), A0=M, backward -> rank 922.
    ld a, 98
    ld [wTestCase], a
    call .fillM
    ld a, $9a
    ld [wCalendarSelectCount], a
    ld a, $03
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
    ld a, $9a
    ld [wCalendarSelectExpected], a
    ld a, $03
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 355: N=19044 (Q upper bound), A0=M, backward -> rank N.
    ld a, 99
    ld [wTestCase], a
    call .fillM
    ld a, $64
    ld [wCalendarSelectCount], a
    ld a, $4a
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
    ld a, $64
    ld [wCalendarSelectExpected], a
    ld a, $4a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 356: A0=1 with maximum N always selects rank 1.
    ld a, 100
    ld [wTestCase], a
    call .fillOne
    ld a, $64
    ld [wCalendarSelectCount], a
    ld a, $4a
    ld [wCalendarSelectCount+1], a
    ld a, 1
    ld [wCalendarSelectDirection], a
    ld a, 1
    ld [wCalendarSelectExpected], a
    xor a
    ld [wCalendarSelectExpected+1], a
    call .runExpected

    ; 357: inputs, owner tag and payload are unchanged; abort still scrubs.
    ld a, 101
    ld [wTestCase], a
    ld a, [wCalendarSelectValue]
    cp 1
    jp nz, .fail
    ld hl, wCalendarSelectValue+1
    ld b, 15
.checkValueTail:
    ld a, [hli]
    or a
    jp nz, .fail
    dec b
    jr nz, .checkValueTail
    ld a, [wCalendarSelectCount]
    cp $64
    jp nz, .fail
    ld a, [wCalendarSelectCount+1]
    cp $4a
    jp nz, .fail
    ld a, [wCalendarSelectDirection]
    cp 1
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 67
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6a
    jp nz, .fail
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
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
    jp RunCalendarStoneTransitionTests

.setSentinelRank:
    ld a, $ef
    ld [wCalendarSelectRank], a
    ld a, $be
    ld [wCalendarSelectRank+1], a
    ret

.expectSentinelRank:
    ld a, [wCalendarSelectRank]
    cp $ef
    jp nz, .fail
    ld a, [wCalendarSelectRank+1]
    cp $be
    jp nz, .fail
    ret

.expectInvalid:
    call CalendarSelectShortRank
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .expectSentinelRank
    ret

.runExpected:
    call CalendarSelectShortRank
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarSelectRank]
    ld b, a
    ld a, [wCalendarSelectExpected]
    cp b
    jp nz, .fail
    ld a, [wCalendarSelectRank+1]
    ld b, a
    ld a, [wCalendarSelectExpected+1]
    cp b
    jp nz, .fail
    ret

.clearValue:
    ld hl, wCalendarSelectValue
    ld b, 16
    xor a
.clearValueLoop:
    ld [hli], a
    dec b
    jr nz, .clearValueLoop
    ret

.fillOne:
    call .clearValue
    ld a, 1
    ld [wCalendarSelectValue], a
    ret

.fillM:
    ld hl, wCalendarSelectValue
    ld b, 15
    ld a, $ff
.fillMLoop:
    ld [hli], a
    dec b
    jr nz, .fillMLoop
    ld a, $7f
    ld [hl], a
    ret

.fillMMinus1:
    call .fillM
    ld a, $fe
    ld [wCalendarSelectValue], a
    ret

.fillMMinus3:
    call .fillM
    ld a, $fc
    ld [wCalendarSelectValue], a
    ret

.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
