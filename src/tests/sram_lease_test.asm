; Stage 1 native Game Boy MBC5 scratch-bank lease contract, tests 67..80.
; The first three banks remain reserved; 13 scratch leases are managed.
SECTION "SRAM lease native tests", ROM0
RunLeaseTests::
    call SRAMEnable

    ; 67: reset initializes permanent reservations and free scratch list.
    ld a, 67
    ld [wTestCase], a
    call LeaseResetAll
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable + 1]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable + 2]
    cp 2
    jp nz, .fail
    ld a, [wLeaseTable + 3]
    or a
    jp nz, .fail
    ld a, [wLeaseTable + 15]
    or a
    jp nz, .fail

    ; 68: first allocation is bank 3 and all 8KiB were initialized.
    ld a, 68
    ld [wTestCase], a
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseBank]
    cp 3
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail
    ld a, $77
    ld [$a000], a
    ld a, $88
    ld [$bfff], a

    ; 69: second allocation returns bank 4, isolated and initially zero.
    ld a, 69
    ld [wTestCase], a
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseBank]
    cp 4
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail
    ld a, $55
    ld [$a000], a

    ; 70: bank 3 still has both sentinels, bank 4 is not an alias.
    ld a, 70
    ld [wTestCase], a
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $77
    jp nz, .fail
    ld a, [$bfff]
    cp $88
    jp nz, .fail

    ; 71: forbidden reserved bank 2 cannot be freed or modified.
    ld a, 71
    ld [wTestCase], a
    ld a, 2
    call SRAMSelectBank
    ld a, $3d
    ld [$a000], a
    ld a, $7e
    ld [$bfff], a
    ld a, 2
    call LeaseFree
    ld a, [wLeaseStatus]
    cp 2
    jp nz, .fail
    ld a, [$a000]
    cp $3d
    jp nz, .fail
    ld a, [$bfff]
    cp $7e
    jp nz, .fail

    ; 72: unleased bank 5 reports status 3 without changing SRAM mapping.
    ld a, 72
    ld [wTestCase], a
    ld a, 5
    call LeaseFree
    ld a, [wLeaseStatus]
    cp 3
    jp nz, .fail
    ld a, [$a000]
    cp $3d
    jp nz, .fail

    ; 73: free leased bank 3 and scrub both ends of all 8KiB.
    ld a, 73
    ld [wTestCase], a
    ld a, 3
    call LeaseFree
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable + 3]
    or a
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail

    ; 74: double-free fails closed; bank stays clear.
    ld a, 74
    ld [wTestCase], a
    ld a, 3
    call LeaseFree
    ld a, [wLeaseStatus]
    cp 3
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail

    ; 75: deterministic reallocation of lowest bank (3), zero initialized.
    ld a, 75
    ld [wTestCase], a
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseBank]
    cp 3
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail
    ld a, 4
    call SRAMSelectBank
    ld a, [$a000]
    cp $55
    jp nz, .fail

    ; 76: allocate all remaining banks 5..15 in deterministic order.
    ld a, 76
    ld [wTestCase], a
    ld a, 5
    ld [wLeaseTestNext], a
.allocRest:
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseBank]
    ld b, a
    ld a, [wLeaseTestNext]
    cp b
    jp nz, .fail
    inc a
    ld [wLeaseTestNext], a
    cp 16
    jr c, .allocRest

    ; 77: exhaustion returns FF, never reuses a live bank.
    ld a, 77
    ld [wTestCase], a
    call LeaseAlloc
    ld a, [wLeaseStatus]
    cp 1
    jp nz, .fail
    ld a, [wLeaseBank]
    cp $ff
    jp nz, .fail

    ; 78: free last bank 15; both ends and arbitrary middle are wiped.
    ld a, 78
    ld [wTestCase], a
    ld a, 15
    call SRAMSelectBank
    ld a, $e1
    ld [$a000], a
    ld a, $e2
    ld [$aabc], a
    ld a, $e3
    ld [$bfff], a
    ld a, 15
    call LeaseFree
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$aabc]
    or a
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail

    ; 79: allocation succeeds at just-released bank 15.
    ld a, 79
    ld [wTestCase], a
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseBank]
    cp 15
    jp nz, .fail

    ; 80: destructive reset releases and zeroizes all 13 live leases
    ; without mutating reserved operand/result bank 2.
    ld a, 80
    ld [wTestCase], a
    call LeaseResetAll
    ld a, [wLeaseStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable + 3]
    or a
    jp nz, .fail
    ld a, [wLeaseTable + 4]
    or a
    jp nz, .fail
    ld a, [wLeaseTable + 15]
    or a
    jp nz, .fail
    ld a, 4
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, 2
    call SRAMSelectBank
    ld a, [$a000]
    cp $3d
    jp nz, .fail
    ld a, [$bfff]
    cp $7e
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
