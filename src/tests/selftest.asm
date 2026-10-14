; Deterministic ROM-resident arithmetic tests, executed on SM83 itself.
; Test case is kept at WRAM $C001, result at $C000.
SECTION "Stage 1 arithmetic tests", ROM0

CompareValueExpected:
    ld hl, wValue
    ld de, wExpected
    ld b, 16
.loop:
    ld a, [de]
    cp [hl]
    jr nz, .different
    inc hl
    inc de
    dec b
    jr nz, .loop
    scf
    ret
.different:
    and a
    ret

FillExpectedOne:
    ld hl, wExpected
    call Clear16
    ld a, 1
    ld [wExpected], a
    ret

FillExpectedTwo:
    ld hl, wExpected
    call Clear16
    ld a, 2
    ld [wExpected], a
    ret

; Avoid rewriting one half of the register state before reading the other.
CopyValueToExpected:
    ld hl, wValue
    ld de, wExpected
    ld b, 16
.loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    ret

RunSelfTests:
    ; 1. SAVE(0) = M
    ld a, 1
    ld [wTestCase], a
    ld hl, wValue
    call Clear16
    call Save127
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 2. SAVE(M) = M
    ld a, 2
    ld [wTestCase], a
    ld hl, wValue
    call FillM
    call Save127
    call CompareValueExpected
    jp nc, .fail

    ; 3. SAVE(M+1) = 1
    ld a, 3
    ld [wTestCase], a
    ld hl, wValue
    call Clear16
    ld a, $80
    ld [wValue + 15], a
    call Save127
    call FillExpectedOne
    call CompareValueExpected
    jp nc, .fail

    ; 4. SAVE(2*M) = M, represented as (2^128 - 2)
    ld a, 4
    ld [wTestCase], a
    ld hl, wValue
    ld b, 16
    ld a, $ff
.fill4:
    ld [hli], a
    dec b
    jr nz, .fill4
    ld a, $fe
    ld [wValue], a
    call Save127
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 5. SAVE(2^128 - 1) = 1
    ld a, 5
    ld [wTestCase], a
    ld hl, wValue
    ld b, 16
    ld a, $ff
.fill5:
    ld [hli], a
    dec b
    jr nz, .fill5
    call Save127
    call FillExpectedOne
    call CompareValueExpected
    jp nc, .fail

    ; 6. SAVE(M + 1) through the 16-byte SM83 addition
    ld a, 6
    ld [wTestCase], a
    ld hl, wValue
    call FillM
    ld hl, wAddend
    call Clear16
    ld a, 1
    ld [wAddend], a
    call Add16
    call Save127
    call CompareValueExpected
    jp nc, .fail

    ; 7. Cross-byte carry: SAVE(255+1) = 256
    ld a, 7
    ld [wTestCase], a
    ld hl, wValue
    call Clear16
    ld a, $ff
    ld [wValue], a
    call Add16
    call Save127
    ld hl, wExpected
    call Clear16
    ld a, 1
    ld [wExpected + 1], a
    call CompareValueExpected
    jp nc, .fail

    ; 8. SAVE((M-1)+1)=M
    ld a, 8
    ld [wTestCase], a
    ld hl, wValue
    call FillM
    ld a, $fe
    ld [wValue], a
    call Add16
    call Save127
    ld hl, wExpected
    call FillM
    call CompareValueExpected
    jp nc, .fail

    ; 9. SAVE(2^127 + 1) = 2
    ld a, 9
    ld [wTestCase], a
    ld hl, wValue
    call Clear16
    ld a, $80
    ld [wValue + 15], a
    ld a, 1
    ld [wValue], a
    call Save127
    call FillExpectedTwo
    call CompareValueExpected
    jp nc, .fail

    ; 10. Ordinary sub-M inputs must remain unchanged
    ld a, 10
    ld [wTestCase], a
    ld hl, wValue
    call Clear16
    ld a, $fe
    ld [wValue], a
    ld a, $5a
    ld [wValue + 1], a
    ld a, $7f
    ld [wValue + 2], a
    ld a, $1b
    ld [wValue + 15], a
    call CopyValueToExpected
    call Save127
    call CompareValueExpected
    jp nc, .fail

    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
