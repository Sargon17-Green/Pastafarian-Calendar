; ROM-executed independently checkable 256-bit SAVE fixtures.
SECTION "Wide arithmetic smoke tests", ROM0

ClearWideInput:
    ld hl, wWideInput
    ld b, 32
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

RunWideTests:
    ; 11. SAVE(0) = M
    ld a, 11
    ld [wTestCase], a
    call ClearWideInput
    call SaveWide256
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 12. SAVE(2^127) = 1
    ld a, 12
    ld [wTestCase], a
    call ClearWideInput
    ld a, $80
    ld [wWideInput + 15], a
    call SaveWide256
    call FillExpectedOne
    call CompareValueExpected
    jp nc, .fail

    ; 13. SAVE(2^254) = 1
    ld a, 13
    ld [wTestCase], a
    call ClearWideInput
    ld a, $40
    ld [wWideInput + 31], a
    call SaveWide256
    call CompareValueExpected
    jp nc, .fail

    ; 14. SAVE(2^255) = 2
    ld a, 14
    ld [wTestCase], a
    call ClearWideInput
    ld a, $80
    ld [wWideInput + 31], a
    call SaveWide256
    call FillExpectedTwo
    call CompareValueExpected
    jp nc, .fail

    ; 15. SAVE(2^255 + 2^254 + 17) = 20
    ld a, 15
    ld [wTestCase], a
    call ClearWideInput
    ld a, $c0
    ld [wWideInput + 31], a
    ld a, 17
    ld [wWideInput], a
    call SaveWide256
    ld hl, wExpected
    call Clear16
    ld a, 20
    ld [wExpected], a
    call CompareValueExpected
    jp nc, .fail

    ; 16. SAVE(2^256 - 1) = 3
    ld a, 16
    ld [wTestCase], a
    ld hl, wWideInput
    ld b, 32
    ld a, $ff
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call SaveWide256
    ld hl, wExpected
    call Clear16
    ld a, 3
    ld [wExpected], a
    call CompareValueExpected
    jp nc, .fail

    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
