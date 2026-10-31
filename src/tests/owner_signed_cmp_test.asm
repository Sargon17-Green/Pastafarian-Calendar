; Stage 1 native regression 191..253: signed owner-scoped comparison.
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


    ; 211: negative nonzero A is below positive nonzero B.
    ; Preserve both operand descriptors, all lease tags and edge sentinels.
    ld a, 211
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpSignA], a
    xor a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 212: positive nonzero A is above negative nonzero B.
    ld a, 212
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld a, 1
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 213: B has length zero with a negative sign (negative zero).
    ; Reject invalid B metadata without modifying descriptors, tags or payload.
    ld a, 213
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenB], a
    ld a, 1
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

    ; 214: B owner zero is invalid even when B is canonical +0.
    ld a, 214
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignB], a
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

    ; 215: positive 0x7f > canonical +0 in B. B[0] is still 1:
    ; a zero-length descriptor ignores residual owned SRAM payload.
    ld a, 215
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld a, 42
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 216: canonical +0 in A > negative 0x7f in B.
    ; A[0] is still 1, confirming zero-length semantics.
    ld a, 216
    ld [wTestCase], a
    ld a, 42
    ld [wOwnerCmpOwnerA], a
    ld a, 46
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpSignB], a
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

    ; 217: two canonical zeros compare equal even though both owners retain
    ; nonzero payload at offset 0 (owner 42: 1, owner 46: $7f).
    ; Zero-length descriptors must ignore residual SRAM and remain read-only.
    ld a, 217
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 218: positive and negative descriptors may alias the same live owner.
    ; Signed ordering must use each descriptor's sign independently, without
    ; mutating shared SRAM, either descriptor, or the 16 lease tags.
    ld a, 218
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpSignB], a
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

    ; 219: reverse the opposite signs under the SAME live SRAM owner.
    ; Negative A must compare less than positive B despite shared payload.
    ld a, 219
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignB], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 220: two negative descriptors aliasing the same live owner and length
    ; must compare equal, with both operands and all SRAM tags unchanged.
    ld a, 220
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 221: two descriptors share owner 46 (SRAM[0]=$7f), yet A's canonical
    ; zero length must ignore that nonzero byte. 0 < +127, read-only.
    ld a, 221
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 222: reverse the same-owner zero/nonzero positions and negate A:
    ; -127 < 0, while zero B must ignore the shared nonzero SRAM byte.
    ld a, 222
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    xor a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 223: two canonical +0 descriptors alias the SAME live owner.
    ; Nonzero SRAM[0]=$7f is stale for both zero-length descriptors.
    ld a, 223
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 224: A is invalid negative zero; B is +127 on that same owner.
    ; Identical owner must never bypass canonical sign/length validation.
    ld a, 224
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 225: reverse invalid negative zero into B, with +127 in A.
    ; Preserve both descriptors, all 16 lease tags and edge payload.
    ld a, 225
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenB], a
    ld a, 1
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 226: same owner 46 has only two 8-KiB banks (capacity 16384).
    ; A is valid +127, B length 16385 is invalid despite owner alias.
    ; Reject without writing descriptors, lease tags, or payload.
    ld a, 226
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    ld a, $40
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

    ; 227: reverse the same-owner over-capacity condition into A.
    ; B remains a canonical valid +127 in its own descriptor.
    ld a, 227
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenB+1], a
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

    ; 228: both operands alias live owner 46; B length=2 is noncanonical.
    ; SRAM[0]=$7f but SRAM[1]=0, so high-zero validation must still run.
    ld a, 228
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+1], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld a, 2
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 229: malformed same-owner descriptor in A, canonical +127 in B.
    ld a, 229
    ld [wTestCase], a
    ld a, 2
    ld [wOwnerCmpLenA], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 230: same owner 46, lengths 8192 versus 8193 across an 8-KiB bank.
    ; SRAM[8191]=$33 and SRAM[8192]=$01: both lengths are canonical.
    ; The extra nonzero high byte makes positive B greater than positive A.
    ld a, 230
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, $20
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenB+1], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 231: reverse the aliasing descriptors; positive longer A > shorter B.
    ld a, 231
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenB], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail


    ; 232: same owner 46, both negative. The shorter magnitude is greater.
    ; Lengths remain 8192 vs 8193 with canonical SRAM high bytes $33/$01.
    ld a, 232
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    xor a
    ld [wOwnerCmpLenA], a
    ld a, 1
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

    ; 233: reverse the negative descriptors. Longer magnitude is smaller.
    ld a, 233
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenB], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail


    ; 234: same live owner 46, two negative 8192-byte descriptors.
    ; Both have the same canonical SRAM high byte $33: equality is read-only.
    ld a, 234
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 235: same negative descriptors at length 8193 across the bank edge.
    ; Shared high byte $01 remains canonical; result must still be equality.
    ld a, 235
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 236: same live owner, positive 8192-byte A versus negative 8193-byte B.
    ; Opposite signs override magnitude length at the bank boundary: A > B.
    ld a, 236
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 237: reverse polarity and lengths: negative 8193-byte A < positive 8192-byte B.
    ; Both canonical descriptors alias owner 46; compare cannot mutate metadata or SRAM.
    ld a, 237
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    xor a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 238: equal 8192-byte magnitude on owner 46, positive A > negative B.
    ; The aliases share SRAM but not independent descriptor signs.
    ld a, 238
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld a, 1
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 239: equal 8193-byte magnitude on owner 46, negative A < positive B.
    ; Cross the SRAM bank edge while keeping descriptors, tags and bytes immutable.
    ld a, 239
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    xor a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail

    ; 240: owner 46 owns exactly two 8192-byte banks. Store a nonzero
    ; most-significant byte at logical offset 16383, the final valid byte.
    ; Canonical +16384-byte A must exceed -16384-byte B on the SAME owner.
    ld a, 240
    ld [wTestCase], a
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    ld a, $5a
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, $40
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenB+1], a
    ld a, 1
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail

    ; 241: reverse signs without changing the full-capacity shared payload.
    ; Canonical -16384-byte A must be less than +16384-byte B, read-only.
    ld a, 241
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    xor a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail

    ; 242: two positive descriptors alias the same 16384-byte live owner.
    ; Full-capacity canonical equality must be read-only, including the top byte.
    ld a, 242
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail

    ; 243: the same full-capacity payload aliased by two negative operands.
    ; Equal negative magnitudes compare EQ, with lease tags/payload unchanged.
    ld a, 243
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    or a
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail

    ; 244: same owner 46, canonical +16383-byte A against +16384-byte B.
    ; Write nonzero offset 16382 so both lengths are canonical; offset
    ; 16383 retains $5a. Positive shorter < positive full capacity.
    ld a, 244
    ld [wTestCase], a
    ld a, $fe
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    ld a, $3c
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, $ff
    ld [wOwnerCmpLenA], a
    ld a, $3f
    ld [wOwnerCmpLenA+1], a
    ld a, $40
    ld [wOwnerCmpLenB+1], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail
    call OwnerCmpTestCheckPreCapacityByte
    jp nc, .fail

    ; 245: the exact same two owner aliases, both negative.
    ; Sign reversal makes the shorter magnitude greater than full capacity.
    ld a, 245
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckBytes
    jp nc, .fail
    call OwnerCmpTestCheckCapacityByte
    jp nc, .fail
    call OwnerCmpTestCheckPreCapacityByte
    jp nc, .fail
    ; 246: same owner 46, A is canonical 16383 bytes; B is noncanonical 16384.
    ; SRAM[16382]=$3c is A's nonzero high byte; SRAM[16383]=0 makes B invalid.
    ; A-first validates the short descriptor before rejecting B's high zero.
    ld a, 246
    ld [wTestCase], a
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB], a
    ld [wOwnerCmpLenB+2], a
    ld a, $ff
    ld [wOwnerCmpLenA], a
    ld a, $3f
    ld [wOwnerCmpLenA+1], a
    ld a, $40
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
    call OwnerCmpTestCheckNoncanonicalCapacityBytes
    jp nc, .fail

    ; 247: reverse A/B. The full-capacity noncanonical descriptor is now A.
    ld a, 247
    ld [wTestCase], a
    ld a, 46
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, $40
    ld [wOwnerCmpLenA+1], a
    ld a, $ff
    ld [wOwnerCmpLenB], a
    ld a, $3f
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
    ; Recreate owner 45 after its earlier release. Banks 5 and 7 are free,
    ; while bank 6 remains owned by 42, so this is a deliberate fragmented pair.
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

    ; Store distinct nonzero top bytes on either side of the physical bank gap.
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 45
    ld [wOwnerRequest], a
    ld a, $33
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    xor a
    ld [wOwnerOffset], a
    ld a, $20
    ld [wOwnerOffset+1], a
    ld a, 1
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail

    ; 248: same fragmented owner, canonical 8192-byte A < 8193-byte B.
    ld a, 248
    ld [wTestCase], a
    ld a, 45
    ld [wOwnerCmpOwnerA], a
    ld [wOwnerCmpOwnerB], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    ld [wOwnerCmpLenA], a
    ld [wOwnerCmpLenA+2], a
    ld [wOwnerCmpLenB+2], a
    ld a, 1
    ld [wOwnerCmpLenB], a
    ld a, $20
    ld [wOwnerCmpLenA+1], a
    ld [wOwnerCmpLenB+1], a
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ; 249: reverse the lengths on the same fragmented owner.
    ld a, 249
    ld [wTestCase], a
    call OwnerCmpTestSwapLengthLow
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ; 250: negative 8192-byte A is greater than negative 8193-byte B.
    ld a, 250
    ld [wTestCase], a
    ld a, 1
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSwapLengthLow
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 1
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ; 251: reverse negative descriptors; the longer magnitude is now A < B.
    ld a, 251
    ld [wTestCase], a
    call OwnerCmpTestSwapLengthLow
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 2
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ; Make logical offset 8192 zero: length 8192 stays canonical, 8193 does not.
    xor a
    ld [wOwnerOffset], a
    ld a, $20
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 45
    ld [wOwnerRequest], a
    xor a
    ld [wOwnerByteValue], a
    call OwnerByteWrite
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail

    ; 252: valid 8192-byte A vs noncanonical 8193-byte B.
    ld a, 252
    ld [wTestCase], a
    xor a
    ld [wOwnerCmpSignA], a
    ld [wOwnerCmpSignB], a
    call OwnerCmpTestSwapLengthLow
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ; 253: reverse A/B so the invalid full-length descriptor is validated first.
    ld a, 253
    ld [wTestCase], a
    call OwnerCmpTestSwapLengthLow
    call OwnerCmpTestSnapshot
    call OwnerSignedCmp
    ld a, [wOwnerCmpResult]
    cp 3
    jp nz, .fail
    call OwnerCmpTestCheckSnapshot
    jp nc, .fail
    call OwnerCmpTestCheckFragmentedBytes
    jp nc, .fail

    ld a, 45
    ld [wOwnerRequest], a
    call OwnerLeaseRelease

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
    jp nz, .bad
    ld a, [wOwnerByteValue]
    cp $7f
    jp nz, .bad
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .bad
    ld a, [wOwnerByteValue]
    cp 1
    jp nz, .bad
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
    jp nz, .bad
    ld a, [wOwnerByteValue]
    or a
    jp nz, .bad
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .bad
    ld a, [wOwnerByteValue]
    or a
    jp nz, .bad
    ; Non-adjacent sentinels at the 8-KiB bank edge.
    ; A owner 46: [8191]=$33, [8192]=$01; B owner 42: [8191]=$00.
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .bad
    ld a, [wOwnerByteValue]
    cp $33
    jp nz, .bad
    ld a, 42
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .bad
    ld a, [wOwnerByteValue]
    or a
    jp nz, .bad
    xor a
    ld [wOwnerOffset], a
    ld [wOwnerOffset+2], a
    ld a, $20
    ld [wOwnerOffset+1], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jp nz, .bad
    ld a, [wOwnerByteValue]
    cp 1
    jp nz, .bad
    scf
    ret
.bad:
    and a
    ret

; Check the highest usable offset of the two-bank live owner after 240..243.
; Carry set = 0x5a unchanged, carry clear = corruption or access failure.
OwnerCmpTestCheckCapacityByte:
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp $5a
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret

; Check offset 16382 on the two-bank owner after cases 244-245.
; Carry set = 0x3c unchanged; clear = failed read or unexpected mutation.
OwnerCmpTestCheckPreCapacityByte:
    ld a, $fe
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp $3c
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret

; Verify the full-capacity noncanonical payload remains unchanged after 246-247.
; Offset 16382 is the nonzero top byte for canonical length 16383; offset
; 16383 is zero, making length 16384 noncanonical. Carry set = both unchanged.
OwnerCmpTestCheckNoncanonicalCapacityBytes:
    ld a, $fe
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 46
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp $3c
    jr nz, .bad
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $3f
    ld [wOwnerOffset+1], a
    xor a
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
    scf
    ret
.bad:
    and a
    ret

; Check logical offsets 8191 and 8192 through reallocated fragmented owner 45.
; They reside in physical banks 5 and 7 respectively; carry set = unchanged.
OwnerCmpTestCheckFragmentedBytes:
    ld a, $ff
    ld [wOwnerOffset], a
    ld a, $1f
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 45
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    cp $33
    jr nz, .bad
    xor a
    ld [wOwnerOffset], a
    ld a, $20
    ld [wOwnerOffset+1], a
    xor a
    ld [wOwnerOffset+2], a
    ld a, 45
    ld [wOwnerRequest], a
    call OwnerByteRead
    ld a, [wOwnerStatus]
    or a
    jr nz, .bad
    ld a, [wOwnerByteValue]
    ld b, a
    ld a, [wTestCase]
    cp 252
    jr nc, .expectZero
    ld a, b
    cp $01
    jr nz, .bad
    jr .ok
.expectZero:
    ld a, b
    or a
    jr nz, .bad
.ok:
    scf
    ret
.bad:
    and a
    ret
; Swap only the low length bytes; these six cases all use 8192/8193 bytes.
OwnerCmpTestSwapLengthLow:
    ld a, [wOwnerCmpLenA]
    ld b, a
    ld a, [wOwnerCmpLenB]
    ld [wOwnerCmpLenA], a
    ld a, b
    ld [wOwnerCmpLenB], a
    ret
