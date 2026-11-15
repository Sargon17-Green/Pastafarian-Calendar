
; Real SM83 Native284..289; independent Host oracle in tests/.
SECTION "Calendar ownership native smoke", ROMX, BANK[1]
RunCalendarInvocationTests::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ; 284: owner47 allocates bank3/tag49.
    ld a, 28
    ld [wTestCase], a
    ld a, 47
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarActiveOwner]
    cp 47
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 49
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, $6a
    ld [$a000], a
    ; 285: busy cannot steal bank3; raw payload preserved.
    ld a, 29
    ld [wTestCase], a
    ld a, 48
    ld [wCalendarRequestedOwner], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    cp 5
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 49
    jp nz, .fail
    ld a, [$a000]
    cp $6a
    jp nz, .fail
    ; 286: abort uses saved owner47, not corrupted request255.
    ld a, 30
    ld [wTestCase], a
    ld a, 255
    ld [wCalendarRequestedOwner], a
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarActive]
    or a
    jp nz, .fail
    ld a, [wCalendarActiveOwner]
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
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp $4d
    jp nz, .fail
    ; 287: double abort must fail closed.
    ld a, 31
    ld [wTestCase], a
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ; 288: invalid owner254 cannot allocate.
    ld a, 32
    ld [wTestCase], a
    ld a, 254
    ld [wCalendarRequestedOwner], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarActive]
    or a
    jp nz, .fail
    ; 289: invalid count zero cannot allocate.
    ld a, 33
    ld [wTestCase], a
    ld a, 52
    ld [wCalendarRequestedOwner], a
    xor a
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp $4d
    jp nz, .fail
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
