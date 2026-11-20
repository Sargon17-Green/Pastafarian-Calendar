; Isolated Native372 acceptance candidate for k=1 hidden drop only.
; Default 370-case and isolated i46 (371) flows remain unchanged.
SECTION "Calendar hidden1 Native benchmark", ROMX, BANK[1]
RunCalendarHidden1Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 116
    ld [wTestCase], a
    ; Fail-closed idle: no output publication.
    ld hl, wCalendarHiddenOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenDrop1
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld b, 16
.idleCheck:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .idleCheck
    ; Foundation c=t=0 offsets, signed32 little-endian.
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.clearOffsets:
    ld [hli], a
    dec b
    jr nz, .clearOffsets
    ld a, 69
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $6d
    ld [$a000], a
    call CalendarHiddenDrop1
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld de, .expected1
    ld hl, wCalendarHiddenOutput
    ld b, 16
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .compare
    ; Verify five work counters; direction must be same-day (2).
    ld a, [wWorkCalcCount]
    cp 1
    jp nz, .fail
    ld a, [wWorkTargetCount]
    cp 1
    jp nz, .fail
    ld a, [wWorkDistance]
    cp 1
    jp nz, .fail
    ld a, [wWorkSum]
    cp 2
    jp nz, .fail
    ld a, [wWorkDirection]
    cp 2
    jp nz, .fail
    ; Inputs and leased SRAM source remain unchanged.
    ld hl, wPairCalcOffset
    ld b, 8
.checkOffsets:
    ld a, [hli]
    or a
    jp nz, .fail
    dec b
    jr nz, .checkOffsets
    ld a, [wLeaseTable+3]
    cp 71
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6d
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
    call CalendarHiddenDrop1
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld de, .expected1
    ld hl, wCalendarHiddenOutput
    ld b, 16
.checkIdleOutput:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkIdleOutput
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.expected1:
    db $58,$0c,$f9,$0c,$e6,$70,$09,$e4,$25,$3c,$27,$5a,$6a,$d6,$d1,$59
