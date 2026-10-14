; Native SM83 multiplication test vectors; independent expected products.
SECTION "Multiply arithmetic smoke tests", ROM0

ClearMulOperands:
    ld hl, wMulA
    ld b, 32
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

CompareWideToROM:
    ld hl, wWideInput
    ld b, 32
.loop:
    ld a, [de]
    cp [hl]
    jr nz, .difference
    inc de
    inc hl
    dec b
    jr nz, .loop
    scf
    ret
.difference:
    and a
    ret

RunMultiplyTests:
    ; 17. 0*0=0; SAVE(0)=M.
    ld a, 17
    ld [wTestCase], a
    call ClearMulOperands
    call Mul128x128
    ld de, .zeroProduct
    call CompareWideToROM
    jp nc, .fail
    call SaveWide256
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 18. 1*1=1; SAVE(1)=1.
    ld a, 18
    ld [wTestCase], a
    call ClearMulOperands
    ld a, 1
    ld [wMulA], a
    ld [wMulB], a
    call Mul128x128
    ld de, .oneProduct
    call CompareWideToROM
    jp nc, .fail
    call SaveWide256
    call FillExpectedOne
    call CompareValueExpected
    jp nc, .fail

    ; 19. 2^64 * 2^64 = 2^128; SAVE=2.
    ld a, 19
    ld [wTestCase], a
    call ClearMulOperands
    ld a, 1
    ld [wMulA + 8], a
    ld [wMulB + 8], a
    call Mul128x128
    ld de, .crossProduct
    call CompareWideToROM
    jp nc, .fail
    call SaveWide256
    call FillExpectedTwo
    call CompareValueExpected
    jp nc, .fail

    ; 20. M*M must be exact as a 254-bit integer; SAVE=M.
    ld a, 20
    ld [wTestCase], a
    ld hl, wMulA
    call FillM
    ld hl, wMulB
    call FillM
    call Mul128x128
    ld de, .mersenneProduct
    call CompareWideToROM
    jp nc, .fail
    call SaveWide256
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 21. (2^128-1)^2; every input bit set; SAVE=1.
    ld a, 21
    ld [wTestCase], a
    ld hl, wMulA
    ld b, 32
    ld a, $ff
.maxFill:
    ld [hli], a
    dec b
    jr nz, .maxFill
    call Mul128x128
    ld de, .maxProduct
    call CompareWideToROM
    jp nc, .fail
    call SaveWide256
    call FillExpectedOne
    call CompareValueExpected
    jp nc, .fail

    ; 22. Nontrivial operands with an exact 64-bit product.
    ld a, 22
    ld [wTestCase], a
    call ClearMulOperands
    ld a, $78
    ld [wMulA], a
    ld a, $56
    ld [wMulA + 1], a
    ld a, $34
    ld [wMulA + 2], a
    ld a, $12
    ld [wMulA + 3], a
    ld a, $f0
    ld [wMulB], a
    ld a, $de
    ld [wMulB + 1], a
    ld a, $bc
    ld [wMulB + 2], a
    ld a, $9a
    ld [wMulB + 3], a
    call Mul128x128
    ld de, .mixedProduct
    call CompareWideToROM
    jp nc, .fail

    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.zeroProduct:
    REPT 32
        db 0
    ENDR
.oneProduct:
    db 1
    REPT 31
        db 0
    ENDR
.crossProduct:
    REPT 16
        db 0
    ENDR
    db 1
    REPT 15
        db 0
    ENDR
.mersenneProduct:
    db 1
    REPT 15
        db 0
    ENDR
    REPT 15
        db $ff
    ENDR
    db $3f
.maxProduct:
    db 1
    REPT 15
        db 0
    ENDR
    db $fe
    REPT 15
        db $ff
    ENDR
.mixedProduct:
    db $80, $20, $2d, $24, $4e, $ea, $00, $0b
    REPT 24
        db 0
    ENDR
