; Stage1 bounded read-only known-year span membership.
; Caller provides independently computed, valid (open,close] gates and candidate
; year number. This does NOT generate gates or choose between year candidates.
; Target is the ACTIVE owner's canonical sign/magnitude ordinal; signed32 only.
; Success: status0 and year output; no match/invalid: status2, output unchanged;
; idle: status6. SRAM/lease tags/ordinal metadata never changed.
SECTION "Calendar known-year interval projection", ROMX, BANK[1]
CalendarProjectKnownYearSpan::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarOrdinalLength+1]
    ld b, a
    ld a, [wCalendarOrdinalLength+2]
    or b
    jp nz, .invalid
    ld a, [wCalendarOrdinalLength]
    cp 5
    jp nc, .invalid
    ld [wCalendarYearInputLen], a
    xor a
    ld [wCalendarYearIndex], a
    ld hl, wCalendarYearTarget
    ld b, 4
.zero:
    ld [hli], a
    dec b
    jr nz, .zero
    ld a, [wCalendarActiveOwner]
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
.read:
    ld a, [wCalendarYearInputLen]
    ld b, a
    ld a, [wCalendarYearIndex]
    cp b
    jr z, .normalized
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .invalid
    ld a, [wCalendarYearIndex]
    ld e, a
    ld d, 0
    ld hl, wCalendarYearTarget
    add hl, de
    ld a, [wOwnerByteValue]
    ld [hl], a
    ld hl, wCalendarYearIndex
    inc [hl]
    ld hl, wOwnerOffset
    inc [hl]
    jr .read
.normalized:
    ld a, [wCalendarOrdinalSign]
    or a
    jr nz, .negative
    ; Positive sign-magnitude must not overflow signed32.
    ld a, [wCalendarYearTarget+3]
    and $80
    jp nz, .invalid
    jr .compare
.negative:
    ; Two's-complement conversion; C survives CPL/LD/DEC.
    scf
    ld hl, wCalendarYearTarget
    ld b, 4
.negate:
    ld a, [hl]
    cpl
    adc a, 0
    ld [hli], a
    dec b
    jr nz, .negate
    ; Reject magnitudes beyond 2^31 (which would wrap positive).
    ld a, [wCalendarYearTarget+3]
    and $80
    jp z, .invalid
.compare:
    ld hl, wCalendarYearOpen
    call CalendarYearCompareTargetToGate
    jp c, .invalid
    jp z, .invalid
    ld hl, wCalendarYearClose
    call CalendarYearCompareTargetToGate
    jr c, .success
    jr z, .success
    jp .invalid
.success:
    ld a, [wCalendarYearCandidate]
    ld [wCalendarYearOutput], a
    ld a, [wCalendarYearCandidate+1]
    ld [wCalendarYearOutput+1], a
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

; Signed little-endian 32-bit comparison of target against [HL].
; Return flags from target - gate, with bit31 flipped on BOTH operands.
CalendarYearCompareTargetToGate:
    push hl
    ld de, 3
    add hl, de
    ld a, [hl]
    xor $80
    ld b, a
    ld a, [wCalendarYearTarget+3]
    xor $80
    cp b
    jr nz, .done
    dec hl
    ld a, [hl]
    ld b, a
    ld a, [wCalendarYearTarget+2]
    cp b
    jr nz, .done
    dec hl
    ld a, [hl]
    ld b, a
    ld a, [wCalendarYearTarget+1]
    cp b
    jr nz, .done
    dec hl
    ld a, [hl]
    ld b, a
    ld a, [wCalendarYearTarget]
    cp b
.done:
    pop hl
    ret
