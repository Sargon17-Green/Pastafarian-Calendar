; Banked subtraction corner cases, executed on native SM83 ROM.
SECTION "Banked 32768-bit subtraction tests", ROM0

RunBankedSubtractionTests::
    call SRAMEnable

    ; 29. Zero - zero = zero, overwriting stale output.
    ld a, 29
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld d, $ea
    ld a, 2
    call SRAMFill4KiB
    call BankedSub4096
    ld a, [wBankStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 30. Borrow propagates through 4095 intermediate zero bytes.
    ; 2^32760 - 1 = FF...(4095 bytes)..FF 00.
    ld a, 30
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$afff], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call BankedSub4096
    ld a, [wBankStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$affe]
    cp $ff
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail
    xor a
    call SRAMSelectBank
    ld a, [$afff]
    cp 1
    jp nz, .fail

    ; 31. Explicit underflow: 0 - 1 is invalid, output is scrubbed.
    ld a, 31
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ; Bank 1 still has B=1 at byte 0.
    call BankedSub4096
    ld a, [wBankStatus]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$a123]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 32. A new successful operation resets status and borrow.
    ; 0x0102 - 0x0003 = 0x00FF.
    ld a, 32
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    ld a, 1
    ld [$a001], a
    ld a, 1
    call SRAMSelectBank
    ld a, 3
    ld [$a000], a
    call BankedSub4096
    ld a, [wBankStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$a001]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail

    ; 33. Repeated operation after borrow must remain deterministic.
    ld a, 33
    ld [wTestCase], a
    call BankedSub4096
    ld a, [wBankStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$a001]
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
