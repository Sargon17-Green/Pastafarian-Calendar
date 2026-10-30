; Stage 1 native regression 191..198: signed owner-scoped comparison.
SECTION "Owner signed comparison tests", ROM0
RunOwnerSignedCmpTests::
    call SRAMEnable
    call LeaseResetAll
    ; Reserve physical bank 6, then produce a fragmented 5,7 group.
    ld a, 41
    ld [wOwnerRequest], a
    ld a, 3
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 42
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 41
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 43
    ld [wOwnerRequest], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 44
    ld [wOwnerRequest], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 45
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerBanks]
    cp 5
    jp nz, .fail
    ld a, [wOwnerBanks+1]
    cp 7
    jp nz, .fail
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail

    ld a, 45
    ld [wOwnerCmpOwnerA], a
    ld a, 46
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a

    ; 191: canonical zero, two independently owned operands.
    ld a, 191
    ld [wTestCase], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail

    ; 192: compare highest byte at logical 8192, fragmented A.
    ld a, 192
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    ld a, $20
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenB+1], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+2], a
    ld a, $20
    ld [wOwnerOffset+1], a
    ld a, 45
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerSelectedBank]
    cp 7
    jp nz, .fail
    ld a, 46
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail

    ; 193: two negatives reverse the magnitude ordering.
    ld a, 193
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail

    ; 194: negative zero is forbidden even if its owner is valid.
    ld a, 194
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld a, $20
    ld [wOwnerCmpLenA+1], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a

    ; 195: leading zero makes a noncanonical 8193-byte operand.
    ld a, 195
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+2], a
    ld a, $20
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    ld a, 46
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerByteValue], a
    call OwnerByteWrite

    ; 196: length beyond the two owned banks must fail closed.
    ld a, 196
    ld [wTestCase], a
    ld a, $40
    ld [wOwnerCmpLenB+1], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    ld a, $20
    ld [wOwnerCmpLenB+1], a

    ; 197: equal high bytes force comparison of bytes at bank boundary.
    ld a, 197
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    ld a, 45
    ld [wOwnerRequest], a
    ld a, $33
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, 46
    ld [wOwnerRequest], a
    ld a, $34
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail

    ; 198: equal operand bytes; after release, invalid ownership.
    ld a, 198
    ld [wTestCase], a
    ld a, $33
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    ld a, 45
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, 43
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, 44
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    call SRAMDisable
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    call SRAMDisable
    ld a, $e0
    ld [wTestResult], a
    ret
