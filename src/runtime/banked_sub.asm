; Exact 4096-byte unsigned subtraction on original DMG + MBC5 SRAM.
; Operand A: bank 0, 4096 little-endian bytes.
; Operand B: bank 1, 4096 little-endian bytes.
; Result A-B: bank 2, 4097 bytes (highest byte 0) if A >= B.
;
; If A < B, output bank 2 is cleared (4097 bytes) and
; wBankStatus=1 records underflow. Otherwise wBankStatus=0.
; The input SRAM banks are never modified. SRAM must be enabled.
; At return bank 2 is selected. All registers and flags clobbered.
SECTION "Exact banked unsigned subtraction", ROM0

BankedSub4096::
    xor a
    ld [wBankBorrow], a
    ld [wBankStatus], a
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

    ld a, [wBankBorrow]
    rrca                 ; CPU carry = previous borrow
    ld a, d
    sbc a, e
    ld d, a
    ld a, 0              ; LD preserves subtract carry/borrow
    adc a, 0
    ld [wBankBorrow], a

    ld a, 2
    call SRAMSelectBank
    ld a, d
    ld [hli], a

    dec bc
    ld a, b
    or c
    jr nz, .loop

    ld a, [wBankBorrow]
    or a
    jr nz, .underflow

    xor a
    ld [hl], a           ; ensure high result byte at B000 is zero
    ret

.underflow:
    ; Fail closed: no invalid modular result may escape in bank 2.
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    ld a, 1
    ld [wBankStatus], a
    ret
