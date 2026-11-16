
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
    ; 300: +1 while idle fails without SRAM mutation.
    ld a, 44
    ld [wTestCase], a
    xor a
    ld [wCalendarUnitDelta], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ; 301: canonical zero +1 -> +1, owner62.
    ld a, 45
    ld [wTestCase], a
    ld a, 62
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    xor a
    ld [wCalendarUnitDelta], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 1
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ; 302: +1 -> +2.
    ld a, 46
    ld [wTestCase], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 2
    jp nz, .fail
    ; 303: $ff +1 -> $0100.
    ld a, 47
    ld [wTestCase], a
    ld a, $ff
    ld [$a000], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 2
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail
    ; 304: +256 -1 -> +255, length shrinks.
    ld a, 48
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarUnitDelta], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$a001]
    or a
    jp nz, .fail
    ; 305: -1 -1 -> -2.
    ld a, 49
    ld [wTestCase], a
    ld a, 1
    ld [$a000], a
    ld [wCalendarOrdinalSign], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 2
    jp nz, .fail
    ld a, [wCalendarOrdinalSign]
    cp 1
    jp nz, .fail
    ; 306: -2 +1 -> -1.
    ld a, 50
    ld [wTestCase], a
    xor a
    ld [wCalendarUnitDelta], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ; 307: -1 +1 -> canonical zero.
    ld a, 51
    ld [wTestCase], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalSign]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    or a
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ; 308: invalid delta is all-or-abort.
    ld a, 52
    ld [wTestCase], a
    ld a, 2
    ld [wCalendarUnitDelta], a
    call CalendarOrdinalUnitStep
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 64
    jp nz, .fail
    ; 309: abort scrubs owner and metadata.
    ld a, 53
    ld [wTestCase], a
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
    ld a, [wCalendarOrdinalLength]
    or a
    jp nz, .fail
    ; 310: idle SAVE returns 6.
    ld a, 54
    ld [wTestCase], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ; 311: SAVE(0)=M, sign0 length16, FF..7F.
    ld a, 55
    ld [wTestCase], a
    ld a, 63
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 16
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$a00f]
    cp $7f
    jp nz, .fail
    ; 312: SAVE(M)=M.
    ld a, 56
    ld [wTestCase], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [$a00f]
    cp $7f
    jp nz, .fail
    ; 313: SAVE(+1)=1, clear previously occupied 16-byte footprint.
    ld a, 57
    ld [wTestCase], a
    ld a, 1
    ld [$a000], a
    ld [wCalendarOrdinalLength], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ld a, [$a00f]
    or a
    jp nz, .fail
    ; 314: SAVE(-1)=M-1.
    ld a, 58
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalSign]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 16
    jp nz, .fail
    ld a, [$a000]
    cp $fe
    jp nz, .fail
    ld a, [$a00f]
    cp $7f
    jp nz, .fail
    ; 315: SAVE(2^127)=1.
    ld a, 59
    ld [wTestCase], a
    ld hl, $a000
    ld b, 16
    xor a
.clearOne:
    ld [hli], a
    dec b
    jr nz, .clearOne
    ld a, $80
    ld [$a00f], a
    ld a, 16
    ld [wCalendarOrdinalLength], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ; 316: negative zero fails and preserves SRAM.
    ld a, 60
    ld [wTestCase], a
    xor a
    ld [wCalendarOrdinalLength], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ; 317: SAVE(2^128)=2 using 17-byte input.
    ld a, 61
    ld [wTestCase], a
    ld hl, $a000
    ld b, 16
    xor a
.clearTwo:
    ld [hli], a
    dec b
    jr nz, .clearTwo
    ld a, 1
    ld [$a010], a
    ld a, 17
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalSign], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 2
    jp nz, .fail
    ; 318: SAVE(-2^128)=M-2; old high input byte stays untouched.
    ld a, 62
    ld [wTestCase], a
    ld hl, $a000
    ld b, 16
    xor a
.clearThree:
    ld [hli], a
    dec b
    jr nz, .clearThree
    ld a, 17
    ld [wCalendarOrdinalLength], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarSave127InPlace
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarOrdinalLength]
    cp 16
    jp nz, .fail
    ld a, [$a000]
    cp $fd
    jp nz, .fail
    ld a, [$a00f]
    cp $7f
    jp nz, .fail
    ld a, [$a010]
    cp 1
    jp nz, .fail
    ; 319: abort scrubs output and old high input.
    ld a, 63
    ld [wTestCase], a
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
    ld a, [$a010]
    or a
    jp nz, .fail
    jp RunCalendarYearProjectionTests
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
