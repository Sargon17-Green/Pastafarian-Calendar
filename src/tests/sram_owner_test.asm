; Native SM83 group-ownership and atomic allocation tests, Stage 1 cases 165..173.
SECTION "Owned SRAM bank tests", ROM0
RunOwnerLeaseTests::
    call SRAMEnable
    call LeaseResetAll

    ; 165 — owner zero is invalid; leaves all scratch banks free.
    ld a, 165
    ld [wTestCase], a
    xor a
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail

    ; 166 — owner 9 acquires clean banks 3 and 4, ascending.
    ld a, 166
    ld [wTestCase], a
    ld a, 9
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerAllocated]
    cp 2
    jp nz, .fail
    ld a, [wOwnerBanks]
    cp 3
    jp nz, .fail
    ld a, [wOwnerBanks+1]
    cp 4
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 11
    jp nz, .fail
    ld a, [wLeaseTable+4]
    cp 11
    jp nz, .fail

    ; 167 — another owner receives disjoint banks 5,6,7.
    ld a, 167
    ld [wTestCase], a
    ld a, 10
    ld [wOwnerRequest], a
    ld a, 3
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerAllocated]
    cp 3
    jp nz, .fail
    ld a, [wOwnerBanks]
    cp 5
    jp nz, .fail
    ld a, [wOwnerBanks+1]
    cp 6
    jp nz, .fail
    ld a, [wOwnerBanks+2]
    cp 7
    jp nz, .fail
    ld a, 5
    call SRAMSelectBank
    ld a, $5a
    ld [$bfff], a

    ; 168 — legacy LeaseFree cannot release someone else's group bank.
    ld a, 168
    ld [wTestCase], a
    ld a, 5
    call LeaseFree
    ld a, [wLeaseStatus]
    cp 3
    jp nz, .fail
    ld a, [wLeaseTable+5]
    cp 12
    jp nz, .fail
    ld a, [$bfff]
    cp $5a
    jp nz, .fail

    ; 169 — duplicate owner cannot grow its allocation implicitly.
    ld a, 169
    ld [wTestCase], a
    ld a, 9
    ld [wOwnerRequest], a
    ld a, 1
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    cp 3
    jp nz, .fail
    ld a, [wOwnerAllocated]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 11
    jp nz, .fail

    ; 170 — only eight free banks remain; request nine is atomic failure.
    ld a, 170
    ld [wTestCase], a
    ld a, 11
    ld [wOwnerRequest], a
    ld a, 9
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    cp 1
    jp nz, .fail
    ld a, [wOwnerAllocated]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+8]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+15]
    or a
    jp nz, .fail

    ; 171 — release owner 9 only; repeated release fails closed.
    ld a, 171
    ld [wTestCase], a
    ld a, 9
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerAllocated]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+4]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+5]
    cp 12
    jp nz, .fail
    ld a, 5
    call SRAMSelectBank
    ld a, [$bfff]
    cp $5a
    jp nz, .fail
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    cp 3
    jp nz, .fail

    ; 172 — newly claimed banks 3,4 have been fully scrubbed.
    ld a, 172
    ld [wTestCase], a
    ld a, 11
    ld [wOwnerRequest], a
    ld a, 2
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wOwnerBanks]
    cp 3
    jp nz, .fail
    ld a, [wOwnerBanks+1]
    cp 4
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail

    ; 173 — release other owners, preserving reserved legacy banks.
    ld a, 173
    ld [wTestCase], a
    ld a, 10
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, 11
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+5]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+15]
    or a
    jp nz, .fail
    ld a, [wLeaseTable]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable+2]
    cp 2
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
