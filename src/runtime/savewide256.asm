; Unsigned 256-bit input reduction modulo M=2^127-1.
; Input: wWideInput[32], little endian, preserved.
; Output: wValue[16], little endian, in 1..M (SAVE semantics).
; No host arithmetic is linked. No allocation and no truncation.
;
; Bit streaming invariant:
;   after consuming k most significant bits, wValue is SAVE(prefix),
;   with the exceptional empty prefix represented as M after first bit.
; Since 2^127 = 1 (mod M), Save127 folds every doubling exactly.
SECTION "256-bit SAVE reducer", ROM0
SaveWide256::
    ld hl, wValue
    call Clear16
    ld de, wWideInput + 31
    ld a, 32
    ld [wWideBytesRemaining], a
.byte:
    ld a, [de]
    dec de
    ld [wWideCurrentByte], a
    ld c, 8
.bit:
    ld a, [wWideCurrentByte]
    add a, a
    ld [wWideCurrentByte], a
    ld hl, wValue
    ld b, 16
.shift:
    ld a, [hl]
    rl a
    ld [hli], a
    dec b
    jr nz, .shift
    call Save127
    dec c
    jr nz, .bit
    ld hl, wWideBytesRemaining
    dec [hl]
    jr nz, .byte
    ret
