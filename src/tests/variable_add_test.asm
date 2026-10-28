; Stage-1 bounded variable-length unsigned addition cases 151..159.
SECTION "Variable length SRAM addition tests", ROM0
RunVariableAdditionTests::
    call SRAMEnable
    xor a
    call SRAMZero8KiB
    ld a, 1
    call SRAMZero8KiB
    xor a
    ld [wVarALength], a
    ld [wVarALength+1], a
    ld [wVarBLength], a
    ld [wVarBLength+1], a

    ; 151: two empty declared operands, canonical zero, full scrub.
    ld a, 151
    ld [wTestCase], a
    call VarAdd8192
    ld a, [wVarStatus]
    or a
    jp nz, .fail
    ld a, [wVarResultLength]
    ld b, a
    ld a, [wVarResultLength+1]
    or b
    jp nz, .fail
    ld a, [$bfff]
    or a
    jp nz, .fail

    ; 152: distinct one-byte operands, result length 1.
    ld a, 152
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    ld [wVarALength], a
    ld a, 1
    call SRAMSelectBank
    ld a, 2
    ld [$a000], a
    ld a, 1
    ld [wVarBLength], a
    call VarAdd8192
    ld a, [wVarStatus]
    or a
    jp nz, .fail
    ld a, [wVarResultLength]
    cp 1
    jp nz, .fail
    ld a, [$a000]
    cp 3
    jp nz, .fail

    ; 153: cross-byte carry, 0xFF + 1 = 0x0100.
    ld a, 153
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $ff
    ld [$a000], a
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call VarAdd8192
    ld a, [wVarStatus]
    or a
    jp nz, .fail
    ld a, [wVarResultLength]
    cp 2
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail

    ; 154: exact 8192-byte value (top nonzero), no spurious carry.
    ld a, 154
    ld [wTestCase], a
    xor a
    call SRAMZero8KiB
    ld a, $80
    ld [$bfff], a
    xor a
    ld [wVarALength], a
    ld [wVarBLength], a
    ld [wVarBLength+1], a
    ld a, $20
    ld [wVarALength+1], a
    call VarAdd8192
    ld a, [wVarStatus]
    or a
    jp nz, .fail
    ld a, [wVarResultLength+1]
    cp $20
    jp nz, .fail
    ld a, [wVarResultLength]
    or a
    jp nz, .fail
    ld a, [$bfff]
    cp $80
    jp nz, .fail

    ; 155: 8192 bytes all FF plus 1 cannot fit: fail closed.
    ld a, 155
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld hl, $a000
    ld bc, 8192
.fillFF:
    ld a, $ff
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .fillFF
    ld a, 1
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    ld [wVarBLength], a
    call VarAdd8192
    ld a, [wVarStatus]
    cp 2
    jp nz, .fail
    call VerifyVariableReject
    jp nc, .fail

    ; 156: length 8193 must reject rather than wrap SRAM address.
    ld a, 156
    ld [wTestCase], a
    ld a, 1
    ld [wVarALength], a
    call VarAdd8192
    ld a, [wVarStatus]
    cp 1
    jp nz, .fail
    call VerifyVariableReject
    jp nc, .fail

    ; 157: noncanonical leading zero at declared length 2 rejects.
    ld a, 157
    ld [wTestCase], a
    xor a
    call SRAMZero8KiB
    ld a, 9
    ld [$a000], a
    ld a, 2
    ld [wVarALength], a
    xor a
    ld [wVarALength+1], a
    ld [wVarBLength], a
    call VarAdd8192
    ld a, [wVarStatus]
    cp 1
    jp nz, .fail
    call VerifyVariableReject
    jp nc, .fail

    ; 158: recovery after multiple failures, 9 + 1 = 10.
    ld a, 158
    ld [wTestCase], a
    ld a, 1
    ld [wVarALength], a
    ld [wVarBLength], a
    call VarAdd8192
    ld a, [wVarStatus]
    or a
    jp nz, .fail
    ld a, [wVarResultLength]
    cp 1
    jp nz, .fail
    ld a, [wVarResultLength+1]
    or a
    jp nz, .fail
    ld a, [$a000]
    cp 10
    jp nz, .fail

    ; 159: input bytes were not overwritten, and result is isolated.
    ld a, 159
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp 9
    jp nz, .fail
    ld a, 1
    call SRAMSelectBank
    ld a, [$a000]
    cp 1
    jp nz, .fail
    ld a, 2
    call SRAMSelectBank
    ld a, [$a000]
    cp 10
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

; Called after VarAdd8192; bank 2 is selected.
VerifyVariableReject:
    ld a, [wVarResultLength]
    ld b, a
    ld a, [wVarResultLength+1]
    or b
    jr nz, .bad
    ld a, [$a000]
    or a
    jr nz, .bad
    ld a, [$afff]
    or a
    jr nz, .bad
    ld a, [$bfff]
    or a
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret
