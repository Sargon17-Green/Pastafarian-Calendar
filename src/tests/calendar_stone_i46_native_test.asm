; Separate sampled endpoint i=46 harness. Only in STAGE1_I46_NATIVE_BENCH.
; The ordinary Native1..370 build and 9000-frame contract never call this.
; The five expected 127-bit residues were computed by independent Python ints.
SECTION "Stage1 i46 endpoint Native test", ROMX, BANK[1]
RunCalendarStoneI46Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 115
    ld [wTestCase], a  ; 371: endpoint 46, 80 output bytes, source/lease/SRAM
    ld hl, RunCalendarStoneTransitionTests.initial
    ld de, wCalendarStoneOld
    ld b, 80
.load:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .load
    ld a, 68
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $6c
    ld [$a000], a
    ld a, 46
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld de, .expected46
    ld hl, wCalendarStoneOutput
    ld b, 80
.compareOutput:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .compareOutput
    ld de, RunCalendarStoneTransitionTests.initial
    ld hl, wCalendarStoneOld
    ld b, 80
.compareSource:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .compareSource
    ld a, [wLeaseTable+3]
    cp 70
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6c
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
    ; All output bytes must survive the invalid (idle) retry.
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld de, .expected46
    ld hl, wCalendarStoneOutput
    ld b, 80
.compareIdle:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .compareIdle
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.expected46:
    db $7e, $a3, $82, $0d, $75, $01, $34, $6b, $0d, $09, $38, $4a, $05, $42, $85, $37
    db $2d, $f5, $f9, $27, $ee, $02, $9d, $27, $d0, $c3, $76, $81, $b5, $65, $49, $6f
    db $4d, $ad, $0e, $0a, $3d, $f8, $4f, $3f, $1b, $93, $fd, $14, $2f, $f2, $17, $47
    db $e2, $7e, $25, $6a, $ae, $03, $c3, $0e, $c0, $bd, $38, $53, $be, $43, $9b, $51
    db $ea, $98, $7a, $d7, $6b, $39, $bb, $86, $a3, $2f, $cf, $71, $c2, $a5, $2a, $67
