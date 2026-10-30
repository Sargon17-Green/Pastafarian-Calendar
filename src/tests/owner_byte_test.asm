; Stage 1, cases 185..190: owner-scoped 24-bit semantic byte addressing.
SECTION "Owner-scoped logical SRAM byte tests", ROM0
RunOwnerByteTests::
    call SRAMEnable
    call LeaseResetAll
    xor a
    call SRAMSelectBank
    ld a, $4d
    ld [$a000], a

    ; 185: create fragmented group for owner 35: physical banks 5 and 7.
    ld a, 185
    ld [wTestCase], a
    ld a, 31
    ld [wOwnerRequest], a
    ld a, 3
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 32
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 31
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 33
    ld [wOwnerRequest], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 34
    ld [wOwnerRequest], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 35
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

    ; 186: logical byte 8191 maps to the end of physical bank 5.
    ld a, 186
    ld [wTestCase], a
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, $5a
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerSelectedBank]
    cp 5
    jp nz, .fail
    ld a, [$bfff]
    cp $5a
    jp nz, .fail

    ; 187: logical byte 8192 maps to physical 7 (not physical 6).
    ld a, 187
    ld [wTestCase], a
    xor a
    ld [wOwnerOffset], a
    ld a, $20
    ld [wOwnerOffset+1], a
    ld a, $a7
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerSelectedBank]
    cp 7
    jp nz, .fail
    call OwnerByteRead
    ld a, [wOwnerByteValue]
    cp $a7
    jp nz, .fail
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerByteValue]
    cp $5a
    jp nz, .fail

    ; 188: a different owner cannot overwrite logical bank 1.
    ; Failed access must leave the previous physical mapping untouched.
    ld a, 188
    ld [wTestCase], a
    ld a, 34
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerOffset], a
    ld a, $20
    ld [wOwnerOffset+1], a
    ld a, $66
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    cp 3
    jp nz, .fail
    ld a, [wOwnerSelectedBank]
    cp $ff
    jp nz, .fail
    ld a, [$bfff]                ; bank 5 still mapped
    cp $5a
    jp nz, .fail
    ld a, 35
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerByteValue]
    cp $a7
    jp nz, .fail

    ; 189: 13*8192 is out of range; high byte >=2 also invalid.
    ld a, 189
    ld [wTestCase], a
    xor a
    ld [wOwnerOffset], a
    ld a, $a0
    ld [wOwnerOffset+1], a
    ld a, 1
    ld [wOwnerOffset+2], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    cp 2
    jp nz, .fail
    ld a, [wOwnerByteValue]
    or a
    jp nz, .fail
    ld a, [wOwnerSelectedBank]
    cp $ff
    jp nz, .fail
    ld a, [$a000]                ; mapping remains at bank 7
    cp $a7
    jp nz, .fail
    ld a, 2
    ld [wOwnerOffset+2], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    cp 2
    jp nz, .fail

    ; 190: release scrubs both fragmented banks and revokes access.
    ld a, 190
    ld [wTestCase], a
    ld a, 35
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [$a000]                ; successful release remapped bank 0
    cp $4d
    jp nz, .fail
    ld a, 5
    call SRAMSelectBank
    ld a, [$bfff]
    or a
    jp nz, .fail
    ld a, 7
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+2], a
    ld a, $20
    ld [wOwnerOffset+1], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    cp 3
    jp nz, .fail
    ld a, [wOwnerByteValue]
    or a
    jp nz, .fail
    ld a, 32
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 33
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 34
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+7]
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
