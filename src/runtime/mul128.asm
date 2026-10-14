; Exact unsigned 128-by-128 multiplication on SM83.
; Inputs: wMulA and wMulB, 16 little-endian bytes each, preserved.
; Output: wWideInput, 32 little-endian bytes; no modular truncation.
; Bit recurrence: after each input bit, output <- 2*output + (bit ? B : 0).
; No host runtime or external code runs on the Game Boy.
SECTION "Unsigned 128x128 multiplication", ROM0

ClearWideOutput::
    ld hl, wWideInput
    ld b, 32
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

Mul128x128::
    call ClearWideOutput
    ld de, wMulA + 15
    ld a, 16
    ld [wMulBytesRemaining], a
.byte:
    ld a, [de]
    dec de
    ld [wMulCurrentByte], a
    ld c, 8
.bit:
    ld a, [wMulCurrentByte]
    add a, a
    ld [wMulCurrentByte], a
    ld a, 0            ; LD does not modify carry.
    adc a, 0           ; capture source MSB before shifting accumulator
    ld [wMulBitFlag], a

    ld hl, wWideInput
    ld b, 32
    xor a              ; carry=0 for 256-bit logical shift
.shift:
    ld a, [hl]
    rl a
    ld [hli], a
    dec b
    jr nz, .shift

    ld a, [wMulBitFlag]
    or a
    jr z, .nextBit
    push de            ; preserve current pointer into A
    ld de, wMulB
    ld hl, wWideInput
    ld b, 16
    and a              ; carry=0 before extended 256-bit addition
.addLow:
    ld a, [de]
    adc a, [hl]
    ld [hli], a
    inc de
    dec b
    jr nz, .addLow
    ld b, 16
.addHigh:
    jr nc, .addDone
    ld a, [hl]
    adc a, 0
    ld [hli], a
    dec b
    jr nz, .addHigh
.addDone:
    pop de
.nextBit:
    dec c
    jr nz, .bit
    ld hl, wMulBytesRemaining
    dec [hl]
    jr nz, .byte
    ret
