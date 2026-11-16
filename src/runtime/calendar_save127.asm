; SAVE(x)=1+((x-1) mod (2^127-1)), signed Euclidean semantics.
; Owner-scoped, serialized DI invocation; SRAM enabled and stable owner.
; 0=success, 2=invalid/capacity, 6=inactive; no date is computed.
SECTION "Calendar signed SAVE127", ROMX, BANK[1]
CalendarSave127InPlace::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarActiveOwner]
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
    ld a, 15
    ld [wOwnerOffset], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    ; Capture the output's 16-byte footprint before any write.
    xor a
    ld [wOwnerOffset], a
.capture:
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    ld a, [wOwnerOffset]
    ld e, a
    ld d, 0
    ld hl, wCalendarSaveOld
    add hl, de
    ld a, [wOwnerByteValue]
    ld [hl], a
    ld a, [wOwnerOffset]
    inc a
    ld [wOwnerOffset], a
    cp 16
    jr nz, .capture
    call CalendarSaveClearRemainder
    ld a, [wCalendarOrdinalLength]
    ld b, a
    ld a, [wCalendarOrdinalLength+1]
    or b
    ld b, a
    ld a, [wCalendarOrdinalLength+2]
    or b
    jp z, .finish
    ; Read highest input magnitude byte first; 24-bit logical offset.
    ld a, [wCalendarOrdinalLength]
    sub 1
    ld [wOwnerOffset], a
    ld a, [wCalendarOrdinalLength+1]
    sbc a, 0
    ld [wOwnerOffset+1], a
    ld a, [wCalendarOrdinalLength+2]
    sbc a, 0
    ld [wOwnerOffset+2], a
.read:
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    call CalendarSavePushByte
    ld a, [wOwnerOffset]
    ld b, a
    ld a, [wOwnerOffset+1]
    or b
    ld b, a
    ld a, [wOwnerOffset+2]
    or b
    jp z, .finish
    call CalendarSaveDecreaseOffset
    jp .read
.finish:
    call CalendarSaveIsZero
    jr z, .zeroResidue
    ld a, [wCalendarOrdinalSign]
    or a
    jr z, .findLength
    ; M-r = 127-bit complement of nonzero residue r.
    ld hl, wCalendarSaveRem
    ld b, 15
.complement:
    ld a, [hl]
    cpl
    ld [hli], a
    dec b
    jr nz, .complement
    ld a, [hl]
    xor $7f
    ld [hl], a
    jr .findLength
.zeroResidue:
    ld hl, wCalendarSaveRem
    call FillM
.findLength:
    ld hl, wCalendarSaveRem+15
    ld b, 16
.length:
    ld a, [hld]
    or a
    jr nz, .lengthFound
    dec b
    jr nz, .length
    jp .invalid
.lengthFound:
    ld a, b
    ld [wCalendarSaveNewLen], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
.write:
    ld a, [wOwnerOffset]
    ld e, a
    ld d, 0
    ld hl, wCalendarSaveRem
    add hl, de
    ld a, [hl]
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .rollback
    ld a, [wOwnerOffset]
    inc a
    ld [wOwnerOffset], a
    cp 16
    jr nz, .write
    ; Commit metadata last: positive and length in [1,16].
    xor a
    ld [wCalendarOrdinalSign], a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ld [wCalendarStatus], a
    ld a, [wCalendarSaveNewLen]
    ld [wCalendarOrdinalLength], a
    ret
.rollback:
    ld a, [wOwnerOffset]
    ld [wCalendarSaveRollbackStop], a
    xor a
    ld [wOwnerOffset], a
.restore:
    ld a, [wOwnerOffset]
    ld b, a
    ld a, [wCalendarSaveRollbackStop]
    cp b
    jr z, .invalid
    ld e, b
    ld d, 0
    ld hl, wCalendarSaveOld
    add hl, de
    ld a, [hl]
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jr nz, .invalid
    ld hl, wOwnerOffset
    inc [hl]
    jr .restore
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarSaveClearRemainder:
    ld hl, wCalendarSaveRem
    ld b, 16
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

CalendarSaveIsZero:
    ld hl, wCalendarSaveRem
    ld b, 16
.loop:
    ld a, [hli]
    or a
    ret nz
    dec b
    jr nz, .loop
    xor a
    ret

CalendarSaveDecreaseOffset:
    ld hl, wOwnerOffset
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

; Horner r <- (256*r+byte) mod M, 16-byte 127-bit residue.
; Above-bit127 coefficient is two*old_byte15 + highbit(old_byte14).
CalendarSavePushByte:
    ld a, [wCalendarSaveRem+15]
    add a, a
    ld [wCalendarSaveFold], a
    ld a, [wCalendarSaveRem+14]
    and $80
    jr z, .shift
    ld hl, wCalendarSaveFold
    inc [hl]
.shift:
    ld hl, wCalendarSaveRem+15
    ld de, wCalendarSaveRem+14
    ld b, 15
.shiftLoop:
    ld a, [de]
    ld [hld], a
    dec de
    dec b
    jr nz, .shiftLoop
    ld a, [wOwnerByteValue]
    ld [wCalendarSaveRem], a
    ld hl, wCalendarSaveRem+15
    res 7, [hl]
    ld a, [wCalendarSaveFold]
    ld b, a
    ld a, [wCalendarSaveRem]
    add a, b
    ld [wCalendarSaveRem], a
    jr nc, .foldBit
    ld hl, wCalendarSaveRem+1
    ld b, 15
.carry:
    ld a, [hl]
    adc a, 0
    ld [hli], a
    jr nc, .foldBit
    dec b
    jr nz, .carry
.foldBit:
    ld hl, wCalendarSaveRem+15
    bit 7, [hl]
    jr z, .checkM
    res 7, [hl]
    ld hl, wCalendarSaveRem
    ld b, 16
.addOne:
    inc [hl]
    jr nz, .foldBit
    inc hl
    dec b
    jr nz, .addOne
    jr .foldBit
.checkM:
    ; M is the zero residue, not an admissible nonzero remainder.
    ld hl, wCalendarSaveRem
    ld b, 15
    ld a, $ff
.match:
    cp [hl]
    jr nz, .done
    inc hl
    dec b
    jr nz, .match
    ld a, [hl]
    cp $7f
    jr nz, .done
    call CalendarSaveClearRemainder
.done:
    ret
