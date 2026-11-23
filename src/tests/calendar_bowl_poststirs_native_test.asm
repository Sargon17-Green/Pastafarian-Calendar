; Stage1 Native391 end-to-end ROM: V1..V46 followed by 12 post-stirs.
SECTION "Calendar 12 post-stirs Native391 test", ROMX, BANK[1]
RunCalendarBowlPostStirsBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 135               ; 0x187 = 391
    ld [wTestCase], a

    ; Idle leaves both published bowls and 12 retained sums untouched.
    ld hl, wCalendarBowlsOld
    ld b, 96
    ld a, $5a
.fillOld:
    ld [hli], a
    dec b
    jr nz, .fillOld
    ld hl, wCalendarPostStirSums
    ld b, 192
    ld a, $5a
.fillSums:
    ld [hli], a
    dec b
    jr nz, .fillSums
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld b, 96
    call .checkSentinel
    jp nz, .fail
    ld hl, wCalendarPostStirSums
    ld b, 192
    call .checkSentinel
    jp nz, .fail

    ; Foundation c=t=0 and live lease; independent non-owner SRAM sentinel.
    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.zeroOffsets:
    ld [hli], a
    dec b
    jr nz, .zeroOffsets
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
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .bowlsExpected
    ld b, 96
    call .checkBytes
    jp nz, .fail
    ld hl, wCalendarPostStirSums
    ld de, .sumsExpected
    ld b, 192
    call .checkBytes
    jp nz, .fail
    ld hl, wCalendarBowlOrderAt46
    ld de, .order46Expected
    ld b, 6
    call .checkBytes
    jp nz, .fail
    ld a, [wCalendarPostStirRound]
    cp 13
    jp nz, .fail
    ld a, [wCalendarVisibleIteration]
    cp 47
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

    ; Illegal round 13, isolated step, must never write public Next.
    ld hl, wCalendarBowlsNext
    ld b, 96
    ld a, $5a
.fillNext:
    ld [hli], a
    dec b
    jr nz, .fillNext
    call CalendarBowlPostStirStep
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld hl, wCalendarBowlsNext
    ld b, 96
    call .checkSentinel
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .bowlsExpected
    ld b, 96
    call .checkBytes
    jp nz, .fail

    ; Negative zero violates the existing ordinal ABI; no partial output.
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, wCalendarBowlsOld
    ld de, .bowlsExpected
    ld b, 96
    call .checkBytes
    jp nz, .fail
    ld hl, wCalendarPostStirSums
    ld de, .sumsExpected
    ld b, 192
    call .checkBytes
    jp nz, .fail

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
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .bowlsExpected
    ld b, 96
    call .checkBytes
    jp nz, .fail
    ld hl, wCalendarPostStirSums
    ld de, .sumsExpected
    ld b, 192
    call .checkBytes
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret
.checkBytes:
    ld a, [de]
    cp [hl]
    ret nz
    inc de
    inc hl
    dec b
    jr nz, .checkBytes
    xor a
    ret
.checkSentinel:
    ld a, [hli]
    cp $5a
    ret nz
    dec b
    jr nz, .checkSentinel
    xor a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.bowlsExpected:
    db $0f,$30,$9a,$1c,$52,$18,$0e,$ba,$12,$17,$e2,$7d,$d2,$c1,$1d,$31
    db $a3,$b9,$c2,$a8,$7e,$95,$2f,$06,$ea,$f6,$9b,$bc,$25,$08,$16,$60
    db $ca,$7c,$28,$be,$90,$f6,$d7,$e5,$e7,$af,$28,$30,$91,$23,$e6,$28
    db $2b,$86,$ea,$68,$74,$a8,$45,$07,$13,$99,$b5,$9a,$1b,$14,$05,$46
    db $76,$d8,$f1,$48,$8f,$aa,$eb,$30,$51,$a7,$27,$06,$84,$29,$47,$29
    db $27,$81,$ab,$ef,$78,$b7,$af,$f6,$7a,$eb,$33,$8e,$a0,$bc,$a9,$53
.sumsExpected:
    db $2b,$bc,$c1,$cc,$b6,$f3,$4e,$8f,$d9,$45,$6b,$56,$ee,$b4,$c3,$4b
    db $6f,$6c,$07,$63,$bd,$40,$72,$8c,$08,$46,$bf,$a6,$bf,$5a,$24,$3e
    db $d6,$a0,$d0,$ea,$6d,$a5,$c3,$5d,$c8,$7d,$9f,$a7,$cf,$ae,$f6,$7a
    db $d4,$fa,$20,$00,$d8,$4e,$6e,$67,$45,$5f,$00,$a0,$ff,$10,$40,$6a
    db $c8,$59,$1a,$2b,$05,$39,$33,$23,$75,$c9,$8e,$29,$62,$ab,$f9,$46
    db $a5,$1a,$52,$e0,$b8,$0c,$7e,$52,$5a,$2a,$e5,$0b,$d5,$6f,$1c,$22
    db $47,$d2,$28,$e1,$dc,$2b,$00,$61,$ae,$66,$fd,$9c,$ac,$2e,$2b,$68
    db $5f,$b8,$a0,$25,$bf,$03,$ad,$1e,$3f,$24,$87,$44,$3b,$c4,$28,$34
    db $80,$b0,$c3,$70,$45,$63,$9e,$63,$70,$b4,$2c,$11,$60,$59,$af,$69
    db $6e,$cd,$88,$32,$9c,$8b,$86,$9b,$c7,$db,$22,$47,$3a,$58,$7b,$59
    db $a4,$3f,$f0,$1a,$cc,$1a,$eb,$6a,$84,$10,$03,$02,$38,$48,$3f,$52
    db $14,$0d,$13,$cd,$01,$39,$33,$a0,$c0,$02,$a8,$54,$27,$b9,$ac,$62
.order46Expected:
    db 4,5,2,3,6,1
