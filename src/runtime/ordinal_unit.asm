; Owner-scoped signed ordinal unit arithmetic (DI, SRAM enabled).
; wCalendarUnitDelta=0 means +1, =1 means -1.
; Status 0 success, 2 invalid/capacity, 6 inactive. Never commits metadata
; until SRAM writes succeed. Serialized lease and stable owner are required.
SECTION "Calendar signed ordinal unit arithmetic", ROMX, BANK[1]
CalendarOrdinalUnitStep::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarUnitDelta]
    cp 2
    jp nc, .invalid
    ld a, [wCalendarOrdinalSign]
    ld [wCalendarUnitNewSign], a
    ld a, [wCalendarOrdinalLength]
    ld [wCalendarUnitNewLength], a
    ld [wCalendarUnitRemaining], a
    ld a, [wCalendarOrdinalLength+1]
    ld [wCalendarUnitNewLength+1], a
    ld [wCalendarUnitRemaining+1], a
    ld a, [wCalendarOrdinalLength+2]
    ld [wCalendarUnitNewLength+2], a
    ld [wCalendarUnitRemaining+2], a
    ld a, [wCalendarActiveOwner]
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
    ld [wCalendarUnitGrow], a
    ld a, [wCalendarUnitRemaining]
    ld b, a
    ld a, [wCalendarUnitRemaining+1]
    or b
    ld b, a
    ld a, [wCalendarUnitRemaining+2]
    or b
    jp nz, .nonzero
    ; Zero +/- 1: preflight byte 0 under active owner.
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    ld a, [wCalendarUnitDelta]
    ld [wCalendarUnitNewSign], a
    ld a, 1
    ld [wCalendarUnitNewLength], a
    ld [wCalendarUnitReplacement], a
    jp .saveStop
.nonzero:
    ; If sign equals delta, move away from zero and grow magnitude.
    ld a, [wCalendarUnitDelta]
    ld b, a
    ld a, [wCalendarOrdinalSign]
    cp b
    jr nz, .scan
    ld a, 1
    ld [wCalendarUnitGrow], a
.scan:
    ld a, [wCalendarUnitRemaining]
    ld b, a
    ld a, [wCalendarUnitRemaining+1]
    or b
    ld b, a
    ld a, [wCalendarUnitRemaining+2]
    or b
    jp z, .extend
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    ld a, [wCalendarUnitGrow]
    or a
    jr z, .scanShrink
    ld a, [wOwnerByteValue]
    cp $ff
    jr nz, .foundGrow
    jr .skip
.scanShrink:
    ld a, [wOwnerByteValue]
    or a
    jr nz, .foundShrink
.skip:
    call CalendarUnitAdvanceOffset
    call CalendarUnitDecreaseRemaining
    jp .scan
.foundGrow:
    ld a, [wOwnerByteValue]
    inc a
    ld [wCalendarUnitReplacement], a
    jp .saveStop
.foundShrink:
    ld a, [wOwnerByteValue]
    dec a
    ld [wCalendarUnitReplacement], a
    ld a, [wOwnerByteValue]
    cp 1
    jp nz, .saveStop
    ld a, [wCalendarUnitRemaining]
    cp 1
    jp nz, .saveStop
    ld a, [wCalendarUnitRemaining+1]
    or a
    jp nz, .saveStop
    ld a, [wCalendarUnitRemaining+2]
    or a
    jp nz, .saveStop
    ; Decremented the top byte 1 -> 0; shrink one byte.
    call CalendarUnitDecreaseNewLength
    ld a, [wCalendarUnitNewLength]
    ld b, a
    ld a, [wCalendarUnitNewLength+1]
    or b
    ld b, a
    ld a, [wCalendarUnitNewLength+2]
    or b
    jp nz, .saveStop
    xor a
    ld [wCalendarUnitNewSign], a
    jp .saveStop
.extend:
    ; All lower bytes $FF: verify capacity for the NEW high byte.
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    call CalendarUnitIncreaseNewLength
    ld a, 1
    ld [wCalendarUnitReplacement], a
.saveStop:
    ld a, [wOwnerOffset]
    ld [wCalendarUnitStop], a
    ld a, [wOwnerOffset+1]
    ld [wCalendarUnitStop+1], a
    ld a, [wOwnerOffset+2]
    ld [wCalendarUnitStop+2], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
.writeLoop:
    ld a, [wOwnerOffset]
    ld b, a
    ld a, [wCalendarUnitStop]
    cp b
    jr nz, .writePrefix
    ld a, [wOwnerOffset+1]
    ld b, a
    ld a, [wCalendarUnitStop+1]
    cp b
    jr nz, .writePrefix
    ld a, [wOwnerOffset+2]
    ld b, a
    ld a, [wCalendarUnitStop+2]
    cp b
    jr nz, .writePrefix
    ld a, [wCalendarUnitReplacement]
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .rollback
    jp .commit
.writePrefix:
    ld a, [wCalendarUnitGrow]
    or a
    jr z, .writeFF
    xor a
    jr .doWrite
.writeFF:
    ld a, $ff
.doWrite:
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .rollback
    call CalendarUnitAdvanceOffset
    jp .writeLoop
.rollback:
    ; Failure byte itself not written; restore earlier uniform carry prefix.
    ld a, [wOwnerOffset]
    ld [wCalendarUnitRollbackStop], a
    ld a, [wOwnerOffset+1]
    ld [wCalendarUnitRollbackStop+1], a
    ld a, [wOwnerOffset+2]
    ld [wCalendarUnitRollbackStop+2], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
.restoreLoop:
    ld a, [wOwnerOffset]
    ld b, a
    ld a, [wCalendarUnitRollbackStop]
    cp b
    jr nz, .restoreByte
    ld a, [wOwnerOffset+1]
    ld b, a
    ld a, [wCalendarUnitRollbackStop+1]
    cp b
    jr nz, .restoreByte
    ld a, [wOwnerOffset+2]
    ld b, a
    ld a, [wCalendarUnitRollbackStop+2]
    cp b
    jr nz, .restoreByte
    jp .invalid
.restoreByte:
    ld a, [wCalendarUnitGrow]
    or a
    jr z, .restoreZero
    ld a, $ff
    jr .restoreWrite
.restoreZero:
    xor a
.restoreWrite:
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    call CalendarUnitAdvanceOffset
    jp .restoreLoop
.commit:
    ld a, [wCalendarUnitNewLength]
    ld [wCalendarOrdinalLength], a
    ld a, [wCalendarUnitNewLength+1]
    ld [wCalendarOrdinalLength+1], a
    ld a, [wCalendarUnitNewLength+2]
    ld [wCalendarOrdinalLength+2], a
    ld a, [wCalendarUnitNewSign]
    ld [wCalendarOrdinalSign], a
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarUnitAdvanceOffset:
    ld hl, wOwnerOffset
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret

CalendarUnitDecreaseRemaining:
    ld hl, wCalendarUnitRemaining
    ld a, [hl]
    sub 1
    ld [hl+], a
    ret nc
    ld a, [hl]
    sbc a, 0
    ld [hl+], a
    ret nc
    ld a, [hl]
    sbc a, 0
    ld [hl], a
    ret

CalendarUnitIncreaseNewLength:
    ld hl, wCalendarUnitNewLength
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret nz
    inc hl
    inc [hl]
    ret

CalendarUnitDecreaseNewLength:
    ld hl, wCalendarUnitNewLength
    ld a, [hl]
    sub 1
    ld [hl+], a
    ret nc
    ld a, [hl]
    sbc a, 0
    ld [hl+], a
    ret nc
    ld a, [hl]
    sbc a, 0
    ld [hl], a
    ret
