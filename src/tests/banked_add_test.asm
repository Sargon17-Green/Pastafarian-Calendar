; Banked addition ROM test vectors, executed by the real SM83 in PyBoy.
SECTION "Banked 32769-bit addition tests", ROM0

RunBankedAdditionTests::
    call SRAMEnable

    ; 25. Zero + zero, and full overwrite of pre-filled output.
    ld a, 25
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld d, $cc
    ld a, 2
    call SRAMFill4KiB
    call BankedAdd4096
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 26. Carry propagates across every one of 4096 bytes.
    ; (2^32768 - 1) + 1 = 2^32768 (32769-bit result).
    ld a, 26
    ld [wTestCase], a
    ld d, $ff
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld a, 1
    ld [$a000], a
    call BankedAdd4096
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    cp 1
    jp nz, .fail
    xor a
    call SRAMSelectBank
    ld a, [$afff]
    cp $ff              ; bank 0 input was not mutated
    jp nz, .fail
    ld a, 1
    call SRAMSelectBank
    ld a, [$a000]
    cp 1                ; bank 1 input was not mutated
    jp nz, .fail

    ; 27. Carry across two low bytes, followed by nonzero result.
    ; 0xFFFF + 0x0301 = 0x10300, little endian [00,03,01].
    ld a, 27
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    xor a
    call SRAMSelectBank
    ld a, $ff
    ld [$a000], a
    ld [$a001], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    ld a, 3
    ld [$a001], a
    call BankedAdd4096
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$a001]
    cp 3
    jp nz, .fail
    ld a, [$a002]
    cp 1
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 28. A new call clears carry from the previous invocation;
    ; repeat zero + zero immediately after a full-carry operation.
    ld a, 28
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    call BankedAdd4096
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
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
