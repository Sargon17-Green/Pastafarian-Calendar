; Exact unsigned variable-length addition within one MBC5 SRAM bank.
; Native SM83; no host arithmetic and no reliance on Game Boy Color banking.
; Input: bank 0 and bank 1, unsigned little-endian magnitudes with
; wVarALength/wVarBLength in 0..8192; the high declared byte must be nonzero.
; Bytes beyond each declared length are ignored (and need not be initialized).
; Output: bank 2, canonical wVarResultLength in 0..8192.
; status=0 exact success; 1 invalid length/leading zero; 2 capacity overflow.
; All rejected results scrub the complete bank 2 and zero result metadata.
; Inputs untouched, output bank 2 selected on return.
; Requires enabled SRAM, serialized caller and initialized declared bytes.
; This is a bounded variable-length primitive, NOT unrestricted BigInt,
; a leased output object, or a complete normative calendar implementation.
SECTION "Variable length unsigned SRAM addition", ROM0
VarAdd8192::
    xor a
    ld [wVarStatus], a
    ld [wVarResultLength], a
    ld [wVarResultLength+1], a
    ld [wVarCarry], a
    ld [wVarIndex], a
    ld [wVarIndex+1], a

    ; 0 <= length <= 0x2000.
    ld a, [wVarALength+1]
    cp $20
    jr c, .boundA
    jp nz, .invalid
    ld a, [wVarALength]
    or a
    jp nz, .invalid
.boundA:
    ld a, [wVarBLength+1]
    cp $20
    jr c, .boundB
    jp nz, .invalid
    ld a, [wVarBLength]
    or a
    jp nz, .invalid
.boundB:
    ; Canonical representation: a nonempty operand has a nonzero top byte.
    ld a, [wVarALength]
    ld b, a
    ld a, [wVarALength+1]
    or b
    jr z, .checkB
    ld a, [wVarALength]
    sub 1
    ld c, a
    ld a, [wVarALength+1]
    sbc a, 0
    ld b, a
    ld hl, $a000
    add hl, bc
    xor a
    call SRAMSelectBank
    ld a, [hl]
    or a
    jp z, .invalid
.checkB:
    ld a, [wVarBLength]
    ld b, a
    ld a, [wVarBLength+1]
    or b
    jr z, .maxLength
    ld a, [wVarBLength]
    sub 1
    ld c, a
    ld a, [wVarBLength+1]
    sbc a, 0
    ld b, a
    ld hl, $a000
    add hl, bc
    ld a, 1
    call SRAMSelectBank
    ld a, [hl]
    or a
    jp z, .invalid

.maxLength:
    ld a, [wVarALength]
    ld [wVarMaxLength], a
    ld a, [wVarALength+1]
    ld [wVarMaxLength+1], a
    ld a, [wVarBLength+1]
    ld b, a
    ld a, [wVarMaxLength+1]
    cp b
    jr c, .takeB
    jr nz, .maxReady
    ld a, [wVarBLength]
    ld b, a
    ld a, [wVarMaxLength]
    cp b
    jr nc, .maxReady
.takeB:
    ld a, [wVarBLength]
    ld [wVarMaxLength], a
    ld a, [wVarBLength+1]
    ld [wVarMaxLength+1], a
.maxReady:
    ld a, 2
    call SRAMZero8KiB
.loop:
    ld a, [wVarIndex]
    ld b, a
    ld a, [wVarMaxLength]
    cp b
    jr nz, .step
    ld a, [wVarIndex+1]
    ld b, a
    ld a, [wVarMaxLength+1]
    cp b
    jp z, .finish
.step:
    xor a
    ld [wVarByteA], a
    ld [wVarByteB], a
    ; Read A only if index < its declared length.
    ld a, [wVarIndex+1]
    ld b, a
    ld a, [wVarALength+1]
    cp b
    jr c, .zeroA
    jr nz, .readA
    ld a, [wVarIndex]
    ld b, a
    ld a, [wVarALength]
    cp b
    jr z, .zeroA
    jr c, .zeroA
.readA:
    ld a, [wVarIndex]
    ld c, a
    ld a, [wVarIndex+1]
    ld b, a
    ld hl, $a000
    add hl, bc
    xor a
    call SRAMSelectBank
    ld a, [hl]
    ld [wVarByteA], a
.zeroA:
    ld a, [wVarIndex+1]
    ld b, a
    ld a, [wVarBLength+1]
    cp b
    jr c, .zeroB
    jr nz, .readB
    ld a, [wVarIndex]
    ld b, a
    ld a, [wVarBLength]
    cp b
    jr z, .zeroB
    jr c, .zeroB
.readB:
    ld a, [wVarIndex]
    ld c, a
    ld a, [wVarIndex+1]
    ld b, a
    ld hl, $a000
    add hl, bc
    ld a, 1
    call SRAMSelectBank
    ld a, [hl]
    ld [wVarByteB], a
.zeroB:
    ld a, [wVarCarry]
    rrca
    ld a, [wVarByteA]
    ld d, a
    ld a, [wVarByteB]
    adc a, d
    ld d, a
    ld a, 0
    adc a, 0
    ld [wVarCarry], a
    ld a, [wVarIndex]
    ld c, a
    ld a, [wVarIndex+1]
    ld b, a
    ld hl, $a000
    add hl, bc
    ld a, 2
    call SRAMSelectBank
    ld a, d
    ld [hl], a
    ld a, [wVarIndex]
    inc a
    ld [wVarIndex], a
    jp nz, .loop
    ld a, [wVarIndex+1]
    inc a
    ld [wVarIndex+1], a
    jp .loop

.finish:
    ld a, [wVarCarry]
    or a
    jr z, .noCarry
    ld a, [wVarMaxLength+1]
    cp $20
    jr z, .overflow
    ld a, [wVarMaxLength]
    ld c, a
    ld a, [wVarMaxLength+1]
    ld b, a
    ld hl, $a000
    add hl, bc
    ld a, 2
    call SRAMSelectBank
    ld a, 1
    ld [hl], a
    ld a, [wVarMaxLength]
    add a, 1
    ld [wVarResultLength], a
    ld a, [wVarMaxLength+1]
    adc a, 0
    ld [wVarResultLength+1], a
    ret
.noCarry:
    ld a, [wVarMaxLength]
    ld [wVarResultLength], a
    ld a, [wVarMaxLength+1]
    ld [wVarResultLength+1], a
    ld a, 2
    call SRAMSelectBank
    ret
.invalid:
    ld a, 1
    jr .reject
.overflow:
    ld a, 2
.reject:
    push af
    ld a, 2
    call SRAMZero8KiB
    xor a
    ld [wVarResultLength], a
    ld [wVarResultLength+1], a
    pop af
    ld [wVarStatus], a
    ret
