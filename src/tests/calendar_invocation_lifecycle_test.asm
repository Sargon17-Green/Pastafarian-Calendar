
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
    ; 290: no active invocation means status 6.
    ld a, 34
    ld [wTestCase], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ; 291: begin owner61, zero is sign=0 length=0.
    ld a, 35
    ld [wTestCase], a
    ld a, 61
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ; 292: negative zero is rejected without release.
    ld a, 36
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarActiveOwner]
    cp 61
    jp nz, .fail
    ; 293: canonical +1 stored in owned scratch is valid.
    ld a, 37
    ld [wTestCase], a
    xor a
    ld [wCalendarOrdinalSign], a
    ld a, 1
    ld [wCalendarOrdinalLength], a
    ld a, 3
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ; 294: canonical -1 uses the same magnitude.
    ld a, 38
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ; 295: a declared leading zero is not canonical.
    ld a, 39
    ld [wTestCase], a
    ld a, 2
    ld [wCalendarOrdinalLength], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 296: one-bank allocation rejects length 8193.
    ld a, 40
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarOrdinalLength], a
    ld a, $20
    ld [wCalendarOrdinalLength+1], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 297: invalid sign 2 fails before touching SRAM.
    ld a, 41
    ld [wTestCase], a
    xor a
    ld [wCalendarOrdinalLength+1], a
    ld a, 2
    ld [wCalendarOrdinalSign], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 298: mutated request does not replace the saved active owner.
    ld a, 42
    ld [wTestCase], a
    ld a, 255
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 63
    jp nz, .fail
    ; 299: abort scrubs the staged magnitude and its metadata.
    ld a, 43
    ld [wTestCase], a
    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalSign]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength+1]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength+2]
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
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
