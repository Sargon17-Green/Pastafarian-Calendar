; Native SM83 canonical SRAM length checks: cases 109..122.
SECTION "SRAM significant length tests", ROM0
RunLengthTests::
    call SRAMEnable

    ; 109: empty full 8192-byte bank => length zero.
    ld a, 109
    ld [wTestCase], a
    ld a, 3
    call SRAMZero8KiB
    ld a, 3
    ld hl, $bfff
    ld bc, 8192
    call SRAMMeasureLength
    ld a, b
    or c
    jp nz, .fail

    ; 110: only lowest byte in 8192-byte window => length one.
    ld a, 110
    ld [wTestCase], a
    ld a, 1
    ld [$a000], a
    ld a, 3
    ld hl, $bfff
    ld bc, 8192
    call SRAMMeasureLength
    ld a, b
    or a
    jp nz, .fail
    ld a, c
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 1
    jp nz, .fail

    ; 111: topmost byte in bank => exact 8192-byte length.
    ld a, 111
    ld [wTestCase], a
    ld a, $80
    ld [$bfff], a
    ld a, 3
    ld hl, $bfff
    ld bc, 8192
    call SRAMMeasureLength
    ld a, b
    cp $20
    jp nz, .fail
    ld a, c
    or a
    jp nz, .fail

    ; 112: interior length 0x0124, preserving unexamined low bytes.
    ld a, 112
    ld [wTestCase], a
    ld a, 4
    call SRAMZero8KiB
    ld a, $11
    ld [$a123], a
    ld a, 4
    ld hl, $bfff
    ld bc, 8192
    call SRAMMeasureLength
    ld a, b
    cp 1
    jp nz, .fail
    ld a, c
    cp $24
    jp nz, .fail
    ld a, [$a123]
    cp $11
    jp nz, .fail

    ; 113: signed-sum result has capacity 4097, not 4096.
    ld a, 113
    ld [wTestCase], a
    ld d, 0
    ld a, 2
    call SRAMFill4KiB
    ld a, 1
    ld [$b000], a
    ld a, 2
    ld hl, $b000
    ld bc, 4097
    call SRAMMeasureLength
    ld a, b
    cp $10
    jp nz, .fail
    ld a, c
    cp 1
    jp nz, .fail

    ; 114: leading zero at B000, nonzero at AFFF => 4096.
    ld a, 114
    ld [wTestCase], a
    xor a
    ld [$b000], a
    ld a, $7f
    ld [$afff], a
    ld a, 2
    ld hl, $b000
    ld bc, 4097
    call SRAMMeasureLength
    ld a, b
    cp $10
    jp nz, .fail
    ld a, c
    or a
    jp nz, .fail

    ; 115: +0 + +0 => zero, no negative-zero sign or stale length.
    ld a, 115
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
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [wSignedResultLength]
    ld b, a
    ld a, [wSignedResultLength+1]
    or b
    jp nz, .fail

    ; 116: +1 + +2 => +3, one significant byte.
    ld a, 116
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
    ld a, [wSignedResultLength]
    cp 1
    jp nz, .fail
    ld a, [wSignedResultLength+1]
    or a
    jp nz, .fail

    ; 117: -1 + -2 => -3, length one, sign negative.
    ld a, 117
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
    ld a, [wSignedResultLength]
    cp 1
    jp nz, .fail

    ; 118: -2 + +2 => canonical positive zero.
    ld a, 118
    ld [wTestCase], a
    xor a
    ld [wSignedSignB], a
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
    ld a, [wSignedResultLength]
    ld b, a
    ld a, [wSignedResultLength+1]
    or b
    jp nz, .fail

    ; 119: full 4096-byte input plus one => 4097-byte exact sum.
    ld a, 119
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
    ld a, [wSignedResultLength]
    cp 1
    jp nz, .fail
    ld a, [wSignedResultLength+1]
    cp $10
    jp nz, .fail
    ld a, [$b000]
    cp 1
    jp nz, .fail

    ; 120: negative zero is rejected, stale length scrubbed.
    ld a, 120
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
    ld a, [wSignedResultLength]
    ld b, a
    ld a, [wSignedResultLength+1]
    or b
    jp nz, .fail
    ld a, [wSignedResultSign]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 121: invalid sign on B also rejects and clears length.
    ld a, 121
    ld [wTestCase], a
    xor a
    ld [wSignedSignA], a
    ld a, 3
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    cp 1
    jp nz, .fail
    ld a, [wSignedResultLength]
    ld b, a
    ld a, [wSignedResultLength+1]
    or b
    jp nz, .fail

    ; 122: recovery after invalid, +0 + +1 restores length 1.
    ld a, 122
    ld [wTestCase], a
    xor a
    ld [wSignedSignB], a
    call SignedAdd4096
    ld a, [wSignedAddStatus]
    or a
    jp nz, .fail
    ld a, [wSignedResultLength]
    cp 1
    jp nz, .fail
    ld a, [wSignedResultLength+1]
    or a
    jp nz, .fail
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
