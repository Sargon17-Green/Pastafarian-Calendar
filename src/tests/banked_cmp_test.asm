; ROM-native, independent magnitude-comparison scenarios.
SECTION "Banked 32768-bit comparison tests", ROM0
RunBankedComparisonTests::
    call SRAMEnable

    ; 34. Zero == zero, despite stale status from an earlier comparison.
    ld a, 34
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld a, 2
    ld [wCmpStatus], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    or a
    jp nz, .fail

    ; 35. Highest byte dominates opposite order in least-significant byte.
    ld a, 35
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 2
    ld [$afff], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$afff], a
    ld a, $ff
    ld [$a000], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    cp 1
    jp nz, .fail

    ; 36. Invert the highest byte: must report A<B.
    ld a, 36
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 0
    ld [$afff], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    cp 2
    jp nz, .fail

    ; 37. Equal upper bytes, then the low byte decides.
    ld a, 37
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$afff], a
    ld [$a000], a
    ld a, 1
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    cp 2
    jp nz, .fail

    ; 38. All 4096 bytes equal FF on both sides; overwrite status.
    ld a, 38
    ld [wTestCase], a
    ld d, $ff
    xor a
    call SRAMFill4KiB
    ld d, $ff
    ld a, 1
    call SRAMFill4KiB
    call BankedCmp4096
    ld a, [wCmpStatus]
    or a
    jp nz, .fail

    ; 39. Equal 4095 low bytes; A>B by the final high byte.
    ld a, 39
    ld [wTestCase], a
    ld a, 1
    call SRAMSelectBank
    ld a, $fe
    ld [$afff], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    cp 1
    jp nz, .fail
    ; Compare must not mutate either bank's top byte.
    ld a, [$afff]      ; bank 1 is specified as the return bank
    cp $fe
    jp nz, .fail
    xor a
    call SRAMSelectBank
    ld a, [$afff]
    cp $ff
    jp nz, .fail

    ; 40. Reverse high byte; reset previous status, preserved operands.
    ld a, 40
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $fd
    ld [$afff], a
    call BankedCmp4096
    ld a, [wCmpStatus]
    cp 2
    jp nz, .fail
    ld a, [$afff]      ; still bank 1
    cp $fe
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
