; ROM-resident native SM83 signed addition cases 53..66.
; Only Stage-1 fixed-capacity arithmetic: calendar production still absent.
SECTION "Signed banked sum tests", ROM0
RunSignedAdditionTests::
    call SRAMEnable

    ; 53. +0 + +0 must clear stale bank2 and produce canonical positive zero.
    ld a, 53
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld d, $a7
    ld a, 2
    call SRAMFill4KiB
    xor a
    ld [wSignedSignA], a
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
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

    ; 54. +1 + +2 = +3; unchanged operands.
    ld a, 54
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    ld a, 1
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 3
    jp nz, .fail

    ; 55. -1 + -2 = -3.
    ld a, 55
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignA], a
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 3
    jp nz, .fail

    ; 56. -3 + +2 = -1; A-B route.
    ld a, 56
    ld [wTestCase], a
    xor a
    ld [wSignedSignB], a
    call SRAMSelectBank
    ld a, 3
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail

    ; 57. -3 + +5 = +2; reversed subtraction B-A.
    ld a, 57
    ld [wTestCase], a
    ld a, 1
    call SRAMSelectBank
    ld a, 5
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 2
    jp nz, .fail

    ; 58. -5 + +5 = +0, cancellation discards stale previous bytes.
    ld a, 58
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 5
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
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

    ; 59. Maximal 4096-byte unsigned A plus 1: 4097th byte must be 1.
    ld a, 59
    ld [wTestCase], a
    ld d, $ff
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld a, 1
    ld [$a000], a
    xor a
    ld [wSignedSignA], a
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
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
    cp $ff
    jp nz, .fail

    ; 60. Negative zero A is invalid, output must be scrubbed.
    ld a, 60
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld a, 1
    ld [wSignedSignA], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    cp 1
    jp nz, .fail
    ld a, [wSignedResultSign]
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

    ; 61. Invalid B sign=2, fail closed.
    ld a, 61
    ld [wTestCase], a
    xor a
    ld [wSignedSignA], a
    ld a, 2
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    cp 1
    jp nz, .fail

    ; 62. Valid call after invalid: +0 + +1 = +1.
    ld a, 62
    ld [wTestCase], a
    xor a
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail

    ; 63. B negative zero is invalid (bank1 scrub only for test setup).
    ld a, 63
    ld [wTestCase], a
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ld a, 1
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail

    ; 64. +1 + -2 = -1; inverted compare route.
    ld a, 64
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    ld a, 1
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail

    ; 65. +2 + -1 = +1; the ordinary A-B path.
    ld a, 65
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail

    ; 66. Deterministic repeat; both operands unchanged across both calls.
    ld a, 66
    ld [wTestCase], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp 2
    jp nz, .fail
    ld a, 1
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
