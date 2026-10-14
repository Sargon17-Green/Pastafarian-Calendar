; Stage 1: verify MBC5 external cartridge RAM selection on the actual SM83.
; The WRAM status markers are only written after every test completes.
SECTION "MBC5 RAM smoke tests", ROM0

RunRAMBankTests::
    ; 23. Every RAM bank must preserve a distinct signature at A000.
    ld a, 23
    ld [wTestCase], a
    call SRAMEnable
    ld b, 0
.writeSignature:
    ld a, b
    call SRAMSelectBank
    ld a, b
    xor $a5
    ld [$a000], a
    inc b
    ld a, b
    cp 16
    jr c, .writeSignature

    ld b, 0
.checkSignature:
    ld a, b
    call SRAMSelectBank
    ld a, [$a000]
    ld c, a
    ld a, b
    xor $a5
    cp c
    jp nz, .fail
    inc b
    ld a, b
    cp 16
    jr c, .checkSignature

    ; 24. Bank isolation also works at the upper SRAM address BFFF.
    ld a, 24
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $39
    ld [$bfff], a
    ld a, 15
    call SRAMSelectBank
    ld a, $c6
    ld [$bfff], a

    xor a
    call SRAMSelectBank
    ld a, [$bfff]
    cp $39
    jp nz, .fail
    ld a, 15
    call SRAMSelectBank
    ld a, [$bfff]
    cp $c6
    jp nz, .fail

    call SRAMDisable
    ld a, $a5
    ld [wTestResult], a
    ret

.fail:
    call SRAMDisable
    ld a, $e0
    ld [wTestResult], a
    ret
