; Signed comparison of two nonnegative-magnitude 4096-byte SRAM integers.
; SRAM bank0=A, bank1=B (little-endian); wSignedSignA/B: 0=plus, 1=minus.
; Return wSignedCmpStatus: 0 equal, 1 A>B, 2 A<B, 3 invalid.
; Reject negative zero and sign values other than 0/1. Neither operand
; is modified. Input SRAM must be enabled; on return SRAM bank1 selected.
SECTION "Signed 32768-bit magnitude comparison", ROM0

; Selected SRAM bank is scanned; returns A=1 for nonzero, A=0 for zero.
SRAMAnyNonzero4096::
    ld hl, $a000
    ld bc, 4096
.loop:
    ld a, [hli]
    or a
    jr nz, .nonzero
    dec bc
    ld a, b
    or c
    jr nz, .loop
    xor a
    ret
.nonzero:
    ld a, 1
    ret

SignedCmp4096::
    ld a, 3
    ld [wSignedCmpStatus], a
    ld a, [wSignedSignA]
    cp 2
    jp nc, .invalid
    ld a, [wSignedSignB]
    cp 2
    jp nc, .invalid

    ld a, [wSignedSignA]
    or a
    jr z, .checkB
    xor a
    call SRAMSelectBank
    call SRAMAnyNonzero4096
    or a
    jp z, .invalid
.checkB:
    ld a, [wSignedSignB]
    or a
    jr z, .validated
    ld a, 1
    call SRAMSelectBank
    call SRAMAnyNonzero4096
    or a
    jp z, .invalid

.validated:
    ld a, [wSignedSignB]
    ld b, a
    ld a, [wSignedSignA]
    cp b
    jr z, .sameSign
    or a
    jr z, .greater
    ld a, 2
    jr .store
.greater:
    ld a, 1
    jr .store

.sameSign:
    call BankedCmp4096
    ld a, [wCmpStatus]
    ld b, a
    ld a, [wSignedSignA]
    or a
    ld a, b
    jr z, .store
    cp 1
    jr nz, .maybeSmaller
    ld a, 2
    jr .store
.maybeSmaller:
    cp 2
    jr nz, .store
    ld a, 1
.store:
    ld [wSignedCmpStatus], a
    ld a, 1
    call SRAMSelectBank
    ret
.invalid:
    ld a, 1
    call SRAMSelectBank
    ret
