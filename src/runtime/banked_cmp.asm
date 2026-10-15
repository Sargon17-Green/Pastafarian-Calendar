; Fixed-capacity 4096-byte unsigned magnitude comparison.
; Bank 0: A, bank 1: B, each 4096 bytes, little endian.
; wCmpStatus = 0 if A=B, 1 if A>B, 2 if A<B.
; Does not write into either operand or any output SRAM bank.
; Caller enables SRAM. Return with SRAM bank 1 selected.
; All working registers and flags clobbered.
SECTION "Exact 32768-bit banked magnitude comparison", ROM0

BankedCmp4096::
    ld hl, $afff
    ld bc, 4096
.byte:
    xor a
    call SRAMSelectBank
    ld a, [hl]
    ld d, a

    ld a, 1
    call SRAMSelectBank
    ld a, [hl]         ; B byte
    cp d               ; B < A iff carry
    jr z, .next
    jr c, .greater
    ld a, 2
    ld [wCmpStatus], a
    ret
.greater:
    ld a, 1
    ld [wCmpStatus], a
    ret
.next:
    dec hl
    dec bc
    ld a, b
    or c
    jr nz, .byte
    xor a
    ld [wCmpStatus], a
    ret
