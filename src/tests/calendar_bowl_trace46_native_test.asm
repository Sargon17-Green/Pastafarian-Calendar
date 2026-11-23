; Stage1 isolated Native390 46-round integration, final pre-post-stir bowls.
SECTION "Calendar bowl trace46 Native390 test", ROMX, BANK[1]
RunCalendarBowlTrace46Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 134                 ; 0x186 = 390
    ld [wTestCase], a

    ; Idle failure must not replace either public result.
    ld hl, wCalendarBowlsOld
    ld b, 96
    ld a, $5a
.fillOld:
    ld [hli], a
    dec b
    jp nz, .fillOld
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fillVisible:
    ld [hli], a
    dec b
    jp nz, .fillVisible
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld b, 96
    call .checkSentinel
    ld hl, wCalendarVisibleOutput
    ld b, 16
    call .checkSentinel

    ; Foundation c=t=0 offsets, live owner/lease, independent SRAM sentinel.
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.zeroOffsets:
    ld [hli], a
    dec b
    jp nz, .zeroOffsets
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

    ld hl, wCalendarBowlsOld
    ld de, .bowls46Expected
    ld b, 96
    call .checkBytes
    ld hl, wCalendarBowlOrderAt46
    ld de, .order46Expected
    ld b, 6
    call .checkBytes
    ld hl, wCalendarVisibleOutput
    ld de, .visible46Expected
    ld b, 16
    call .checkBytes
    ld a, [wCalendarVisibleIteration]
    cp 47
    jp nz, .fail
    ld a, [wCalendarStoneIteration]
    cp 46
    jp nz, .fail
    ld hl, wPairCalcOffset
    ld b, 8
.checkOffsets:
    ld a, [hli]
    or a
    jp nz, .fail
    dec b
    jp nz, .checkOffsets
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

    ; Negative-zero rejection must not republish bowls or V46.
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, wCalendarBowlsOld
    ld de, .bowls46Expected
    ld b, 96
    call .checkBytes
    ld hl, wCalendarVisibleOutput
    ld de, .visible46Expected
    ld b, 16
    call .checkBytes

    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
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
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .bowls46Expected
    ld b, 96
    call .checkBytes

    ld a, $a5
    ld [wTestResult], a
    ret

.checkBytes:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jp nz, .checkBytes
    ret

.checkSentinel:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jp nz, .checkSentinel
    ret

.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.bowls46Expected:
    db $32,$b1,$a5,$ef,$3e,$07,$5a,$f1,$23,$4c,$1e,$56,$f4,$6b,$5a,$77
    db $5f,$21,$e9,$8b,$3a,$bd,$71,$2c,$e2,$af,$0a,$46,$02,$75,$6d,$28
    db $87,$91,$a7,$8d,$24,$20,$54,$0f,$51,$ff,$41,$65,$37,$c7,$66,$04
    db $c0,$09,$7e,$e6,$e2,$00,$03,$dd,$3d,$0a,$25,$c9,$d5,$1e,$12,$5b
    db $f4,$a5,$14,$f9,$d9,$81,$70,$90,$af,$9c,$8c,$d7,$53,$bd,$4b,$3a
    db $c8,$a7,$f8,$e3,$5b,$8c,$bb,$f4,$94,$a3,$4e,$b4,$96,$30,$37,$12
.order46Expected:
    db 4,5,2,3,6,1
.visible46Expected:
    db $1a,$90,$87,$91,$00,$b9,$53,$b0,$ae,$c7,$3f,$9e,$b1,$b3,$bb,$6a
