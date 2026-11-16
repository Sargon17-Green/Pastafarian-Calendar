; Stage1 bounded arbitrary-length signed ordinal preflight.
; Magnitude: little-endian bytes at logical owner offsets 0..length-1.
; Length: 24-bit unsigned (0..106496 subject to allocated bank capacity).
; Sign: 0 nonnegative, 1 negative; zero is length=0, sign=0 only.
; On success status 0. Invalid sign/noncanonical magnitude/unowned top byte:
; status 2. No active invocation: status 6. No SRAM bytes or lease tags
; are mutated. Current SRAM bank selection and temporary owner lookup
; scratch may change. No SAVE, year/date arithmetic, or commit semantics.
; Requires DI, enabled SRAM, ROM bank1, owner lease initialized.
SECTION "Calendar ordinal representation preflight", ROMX, BANK[1]
CalendarOrdinalValidate::
    ld a, [wCalendarActive]
    cp 1
    jr z, .active
    ld a, 6
    jr .result
.active:
    ld a, [wCalendarOrdinalSign]
    cp 2
    jr nc, .invalid
    ld a, [wCalendarOrdinalLength]
    ld b, a
    ld a, [wCalendarOrdinalLength+1]
    or b
    ld b, a
    ld a, [wCalendarOrdinalLength+2]
    or b
    jr nz, .nonzero
    ld a, [wCalendarOrdinalSign]
    or a
    jr nz, .invalid
    xor a
    jr .result
.nonzero:
    ; Last byte must exist inside the active owner's logical leased range.
    ; 24-bit subtract-one cannot underflow because length != 0.
    ld a, [wCalendarActiveOwner]
    ld [wOwnerRequest], a
    ld a, [wCalendarOrdinalLength]
    sub 1
    ld [wOwnerOffset], a
    ld a, [wCalendarOrdinalLength+1]
    sbc a, 0
    ld [wOwnerOffset+1], a
    ld a, [wCalendarOrdinalLength+2]
    sbc a, 0
    ld [wOwnerOffset+2], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .invalid
    ld a, [wOwnerByteValue]
    or a
    jr z, .invalid
    xor a
    jr .result
.invalid:
    ld a, 2
.result:
    ld [wCalendarStatus], a
    ret
