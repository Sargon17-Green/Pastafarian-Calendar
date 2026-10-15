; Unsigned fixed-capacity wide addition on the original Game Boy.
; All production instructions are SM83. No host-language arithmetic.
;
; Requires MBC5+RAM cartridge with at least banks 0,1,2.
; The caller enables SRAM before calling. Input operands occupy the
; first 4096 bytes of banks 0 and 1, little endian; output is written
; to 4097 bytes in bank 2 (A000..B000). This output never aliases an
; input bank. Input banks remain unchanged.
;
; The result is the exact 32769-bit sum, with no truncation.
; After return RAM bank 2 is selected. Registers and flags are clobbered.
; This is a fixed-capacity building block, NOT an arbitrary-precision API.
SECTION "Exact 4096-byte banked addition", ROM0

; A: MBC5 RAM bank 0..15; D: fill byte. Overwrites only A000..AFFF.
SRAMFill4KiB::
    call SRAMSelectBank
    ld hl, $a000
    ld bc, 4096
.loop:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

BankedAdd4096::
    xor a
    ld [wBankCarry], a
    ld hl, $a000
    ld bc, 4096
.loop:
    xor a
    call SRAMSelectBank
    ld a, [hl]
    ld d, a

    ld a, 1
    call SRAMSelectBank
    ld a, [hl]
    ld e, a

    ld a, [wBankCarry]
    rrca                 ; bit 0 becomes CPU carry
    ld a, d              ; LD does not change flags
    adc a, e
    ld d, a              ; preserve sum byte while capturing carry
    ld a, 0              ; LD does not change flags
    adc a, 0
    ld [wBankCarry], a

    ld a, 2
    call SRAMSelectBank
    ld a, d
    ld [hli], a

    dec bc
    ld a, b
    or c
    jr nz, .loop

    ; HL is now B000, still within the 8-KiB SRAM bank window.
    ld a, [wBankCarry]
    ld [hl], a
    ret
