; Native387 isolates the 127-bit bowl-order/factoradic primitive (NOT bowl arithmetic).
SECTION "Stage1 bowl order Native387 test", ROMX, BANK[1]

RunCalendarBowlOrderBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 131                 ; 256 + 131 = Native387
    ld [wTestCase], a

    ; Idle must not publish an output, even with canonical input 1.
    ld hl, wCalendarBowlOrderInput
    ld b, 16
    xor a
.clearInput:
    ld [hli], a
    dec b
    jr nz, .clearInput
    ld a, 1
    ld [wCalendarBowlOrderInput], a
    ld hl, wCalendarBowlOrder
    ld b, 6
    ld a, $5a
.seedOutput:
    ld [hli], a
    dec b
    jr nz, .seedOutput
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlOrder
    ld b, 6
.idleUnchanged:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .idleUnchanged

    ; The same ownership contract as Native386, no extra SRAM writes.
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

    ld hl, .case1
    call .runCase
    jp nz, .fail
    ld hl, .case2
    call .runCase
    jp nz, .fail
    ld hl, .case720
    call .runCase
    jp nz, .fail
    ld hl, .case721
    call .runCase
    jp nz, .fail
    ld hl, .caseM
    call .runCase
    jp nz, .fail
    ld hl, .caseV46
    call .runCase
    jp nz, .fail

    ; Zero and high-bit-127 invalid inputs must preserve the previous order.
    ld hl, wCalendarBowlOrderInput
    ld b, 16
    xor a
.clearInvalid:
    ld [hli], a
    dec b
    jr nz, .clearInvalid
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld hl, wCalendarBowlOrder
    ld de, .expectedV46
    ld b, 6
    call .match
    jp nz, .fail
    ld a, $80
    ld [wCalendarBowlOrderInput+15], a
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld hl, wCalendarBowlOrder
    ld de, .expectedV46
    ld b, 6
    call .match
    jp nz, .fail

    ; Active-owner and sentinel invariants. Negative zero is illegal.
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
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, wCalendarBowlOrder
    ld de, .expectedV46
    ld b, 6
    call .match
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
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlOrder
    ld de, .expectedV46
    ld b, 6
    call .match
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret

; HL points to 16-byte source followed by six expected order bytes.
; Return Z on success, NZ on mismatch; no fixture is used by the runtime.
.runCase:
    ld de, wCalendarBowlOrderInput
    ld b, 16
.copyCase:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyCase
    push hl
    call CalendarBowlOrderFromResidue
    pop hl
    ld a, [wCalendarStatus]
    or a
    jr nz, .caseBad
    push hl
    ld de, $fff0            ; return to source's first byte
    add hl, de
    ld de, wCalendarBowlOrderInput
    ld b, 16
.checkSource:
    ld a, [de]
    cp [hl]
    jr nz, .sourceBad
    inc de
    inc hl
    dec b
    jr nz, .checkSource
    pop hl
    ld de, wCalendarBowlOrder
    ld b, 6
.checkOrder:
    ld a, [de]
    cp [hl]
    jr nz, .caseBad
    inc de
    inc hl
    dec b
    jr nz, .checkOrder
    xor a
    ret
.sourceBad:
    pop hl
.caseBad:
    ld a, 1
    or a
    ret

; HL is WRAM and DE is ROM data. Return Z if B bytes match.
.match:
    ld a, [de]
    cp [hl]
    jr nz, .caseBad
    inc de
    inc hl
    dec b
    jr nz, .match
    xor a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.case1:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db 1,2,3,4,5,6
.case2:
    db $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db 1,2,3,4,6,5
.case720:
    db $d0,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db 6,5,4,3,2,1
.case721:
    db $d1,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db 1,2,3,4,5,6
.caseM:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    db 2,1,4,3,5,6
.caseV46:
    db $1a,$90,$87,$91,$00,$b9,$53,$b0,$ae,$c7,$3f,$9e,$b1,$b3,$bb,$6a
.expectedV46:
    db 4,5,2,3,6,1
