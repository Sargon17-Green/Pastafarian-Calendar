; Native cartridge tests for signed-magnitude comparison (41..52).
SECTION "Signed banked comparison tests", ROM0
RunSignedComparisonTests::
    call SRAMEnable
    ; 41: +0 == +0; clear stale result.
    ld a, 41
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    xor a
    ld [wSignedSignA], a
    ld [wSignedSignB], a
    ld a, 2
    ld [wSignedCmpStatus], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    or a
    jp nz, .fail

    ; 42: +1 > +0.
    ld a, 42
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 1
    jp nz, .fail

    ; 43: +1 < +2.
    ld a, 43
    ld [wTestCase], a
    ld a, 1
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 2
    jp nz, .fail

    ; 44: -1 < +2.
    ld a, 44
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignA], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 2
    jp nz, .fail

    ; 45: -1 > -2.
    ld a, 45
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignB], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 1
    jp nz, .fail

    ; 46: -3 < -2.
    ld a, 46
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 3
    ld [$a000], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 2
    jp nz, .fail

    ; 47: negative zero A must fail closed.
    ld a, 47
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 3
    jp nz, .fail

    ; 48: invalid sign A=2.
    ld a, 48
    ld [wTestCase], a
    ld a, 2
    ld [wSignedSignA], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 3
    jp nz, .fail

    ; 49: invalid sign B=2.
    ld a, 49
    ld [wTestCase], a
    xor a
    ld [wSignedSignA], a
    ld a, 2
    ld [wSignedSignB], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 3
    jp nz, .fail

    ; 50: recover after invalid input, +0 > -2.
    ld a, 50
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignB], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 1
    jp nz, .fail

    ; 51: negative zero B rejected too.
    ld a, 51
    ld [wTestCase], a
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 3
    jp nz, .fail

    ; 52: repair B; +1 > -1; both inputs unchanged.
    ld a, 52
    ld [wTestCase], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp 1
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
