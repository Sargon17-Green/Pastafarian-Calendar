; Stage 1 native regression 191..202: signed owner-scoped comparison.
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
    ; The previous invalid-length case leaves wOwnerOffset at $4000.
    ; Select the valid high byte (logical offset $2000) explicitly,
    ; rather than relying on stale scratch state across test cases.
    ld a, 197
    ld [wTestCase], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+2], a
    ld a, $20
    ld [wOwnerOffset+1], a
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
    ; 199: canonical +0 is smaller than a nonzero positive magnitude.
    ; Owner 42 is a live, zero-initialized bank; owner 46 has 8193 bytes.
    ld a, 199
    ld [wTestCase], a
    ld a, 42
    ld [wOwnerCmpOwnerA], a
    ld a, 46
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    ld a, $20
    ld [wOwnerCmpLenB+1], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail

    ; 200: a nonzero negative magnitude is smaller than canonical +0.
    ld a, 200
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld a, 42
    ld [wOwnerCmpOwnerB], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    ld a, $20
    ld [wOwnerCmpLenA+1], a
    xor a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail

    ; 201: sign outside {0,1} must fail closed, even for a valid owner.
    ld a, 201
    ld [wTestCase], a
    ld a, 2
    ld [wOwnerCmpSignA], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail

    ; 202: owner ID zero must fail closed even when length is zero.
    ld a, 202
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail


    ; 203-206: compare must never modify operand metadata, bank ownership
    ; tags, or bytes, including validation failures. Scratch and MBC5
    ; mapping changes are intentionally not part of this invariant.
    ; Establish two canonical one-byte operands in live, separate owners.
    ld a, 203
    ld [wTestCase], a
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    ld a, $7f
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 42
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail

    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld a, 42
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 204: invalid sign must fail without changing any input/state.
    ld a, 204
    ld [wTestCase], a
    ld a, 2
    ld [wOwnerCmpSignA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 205: invalid owner must fail without changing any input/state.
    ld a, 205
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpSignA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 206: length 16385 exceeds owner 46's two 8-KiB banks.
    ; Validation may change its offset scratch, never operand length.
    ld a, 206
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld a, $40
    ld [wOwnerCmpLenA+1], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail


    ; 207-210: malformed SECOND operand must not mutate either operand,
    ; any of the 16 lease tags, or SRAM payload. A stays canonical 0x7f.
    ; Re-establish A after case 206's intentionally invalid length.
    ld a, 207
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld a, 42
    ld [wOwnerCmpOwnerB], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 2
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 208: B owner 45 was released in case 198; A remains live.
    ld a, 208
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignB], a
    ld a, 45
    ld [wOwnerCmpOwnerB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 209: B owner 42 has one 8192-byte bank, not 8193 bytes.
    ld a, 209
    ld [wTestCase], a
    ld a, 42
    ld [wOwnerCmpOwnerB], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    ld a, $20
    ld [wOwnerCmpLenB+1], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 210: B length=2 with zero high byte is noncanonical.
    ; B[0]=1 and B[1]=0; readback checks both bytes.
    ld a, 210
    ld [wTestCase], a
    ld a, 2
    ld [wOwnerCmpLenB], a
    xor a
    ld [wOwnerCmpLenB+1], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

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


; Snapshot exactly the 10 immutable operand bytes and all 16 lease tags.
; The shared test buffers are not used by OwnerSignedCmp or its callees.
OwnerCmpTestSnapshot:
    ld hl, wOwnerCmpOwnerA
    ld de, wExpected
    ld b, 10
.copyOperands:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyOperands
    ld hl, wLeaseTable
    ld de, wValue
    ld b, 16
.copyTags:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyTags
    ret

; Carry set = unchanged, carry clear = mutation detected.
OwnerCmpTestCheckSnapshot:
    ld hl, wOwnerCmpOwnerA
    ld de, wExpected
    ld b, 10
.checkOperands:
    ld a, [de]
    cp [hl]
    jr nz, .bad
    inc hl
    inc de
    dec b
    jr nz, .checkOperands
    ld hl, wLeaseTable
    ld de, wValue
    ld b, 16
.checkTags:
    ld a, [de]
    cp [hl]
    jr nz, .bad
    inc hl
    inc de
    dec b
    jr nz, .checkTags
    scf
    ret
.bad:
    and a
    ret

; Independently read both payload bytes after each valid/invalid compare.
OwnerCmpTestCheckBytes:
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp $7f
    jr nz, .bad
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp 1
    jr nz, .bad
    ; Check the next payload byte in BOTH live operands too:
    ; this catches mutation of B's zero high byte in case 210.
    ld a, 1
    ld [wOwnerOffset], a
    xor a
    ld [wOwnerOffset+1], a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    or a
    jr nz, .bad
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    or a
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret
