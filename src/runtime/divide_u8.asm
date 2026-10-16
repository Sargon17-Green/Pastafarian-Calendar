; Unsigned restoring long division on original Game Boy SM83.
; Dividend: 4096 little-endian bytes in MBC5 SRAM bank 0, preserved.
; Divisor: wDivisor, unsigned 8-bit (1..255).
; Quotient: 4096 bytes in SRAM bank 2; B000 is explicitly cleared.
; Remainder: wDivRemainderLo (0..254), wDivRemainderHi=0.
; Length: wDivQuotLength LE16 (0..4096), no truncation.
; Status: wDivStatus=0 on success; 1 on divisor zero.
; On division by zero, bank 2 is zeroized (4097 bytes), length and
; remainder are reset; dividend bank 0 is never mutated.
; Caller enables external RAM. Returns with SRAM bank 2 selected.
; Registers and flags clobbered. Fixed capacity, NOT generic BigInt.
SECTION "Exact 4096-byte division by u8", ROM0

BankedDivU8::
    xor a
    ld [wDivRemainderLo], a
    ld [wDivRemainderHi], a
    ld [wDivQuotLength], a
    ld [wDivQuotLength+1], a
    ld a, [wDivisor]
    or a
    jp z, .zeroDivisor

    ld hl, $afff
    ld bc, 4096
.nextByte:
    xor a
    call SRAMSelectBank
    ld a, [hl]
    ld d, a
    push bc
    ld b, 8
    xor a
    ld [wDivQuotByte], a
.nextBit:
    ; Append zero to the quotient, then read the next dividend bit.
    ld a, [wDivQuotByte]
    add a, a
    ld [wDivQuotByte], a
    sla d                    ; next dividend MSB goes to CPU carry
    ld a, [wDivRemainderLo]
    rla                      ; (remainder*2 + input bit), low byte
    ld [wDivRemainderLo], a
    ld a, [wDivRemainderHi]
    rla                      ; carry into bit 8, no overflow beyond bit 8
    ld [wDivRemainderHi], a

    ld a, [wDivRemainderHi]
    or a
    jr nz, .subtract
    ld a, [wDivRemainderLo]
    ld e, a
    ld a, [wDivisor]
    cp e
    jr c, .subtract
    jr z, .subtract
    jr .nextBitDone
.subtract:
    ld a, [wDivisor]
    ld e, a
    ld a, [wDivRemainderLo]
    sub e
    ld [wDivRemainderLo], a
    ld a, [wDivRemainderHi]
    sbc a, 0
    ld [wDivRemainderHi], a
    ld a, [wDivQuotByte]
    inc a                    ; quotient bit is 1 (LSB is 0 so far)
    ld [wDivQuotByte], a
.nextBitDone:
    dec b
    jr nz, .nextBit

    pop bc
    ld a, 2
    call SRAMSelectBank
    ld a, [wDivQuotByte]
    ld [hld], a
    dec bc
    ld a, b
    or c
    jr nz, .nextByte

    xor a
    ld [$b000], a            ; scrub stale overflow from prior signed sum
    ld a, 2
    ld hl, $afff
    ld bc, 4096
    call SRAMMeasureLength
    ld a, c
    ld [wDivQuotLength], a
    ld a, b
    ld [wDivQuotLength+1], a
    xor a
    ld [wDivStatus], a
    ret

.zeroDivisor:
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    ld a, 1
    ld [wDivStatus], a
    ret
