; Stage 1 normative day count for signed 32-bit Foundation offsets.
; Cases 81..92 run on native SM83, results compared to independent constants.
SECTION "Day count from Foundation test", ROM0

DayTestClear::
    ld hl, wDayOffset
    ld b, 14                 ; offset[4], actual[5], expected[5]
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

; Carry set if exact five-byte equality; clear if any mismatch.
DayTestCompare::
    call DayCountFromOffset
    ld hl, wDayCount
    ld de, wDayExpected
    ld b, 5
.loop:
    ld a, [de]
    cp [hl]
    jr nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .loop
    scf
    ret
.fail:
    and a
    ret

RunDayCountTests::
    ; 81. Foundation + 0 maps to 1, not 0.
    ld a, 81
    ld [wTestCase], a
    call DayTestClear
    ld a, 1
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ; 82. Foundation + 1 -> 3.
    ld a, 82
    ld [wTestCase], a
    call DayTestClear
    ld a, 1
    ld [wDayOffset], a
    ld a, 3
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ; 83. Foundation - 1 -> 2.
    ld a, 83
    ld [wTestCase], a
    call DayTestClear
    ld a, $ff
    ld [wDayOffset], a
    ld [wDayOffset + 1], a
    ld [wDayOffset + 2], a
    ld [wDayOffset + 3], a
    ld a, 2
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ; 84. Foundation + 2 -> 5.
    ld a, 84
    ld [wTestCase], a
    call DayTestClear
    ld a, 2
    ld [wDayOffset], a
    ld a, 5
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ; 85. Foundation - 2 -> 4.
    ld a, 85
    ld [wTestCase], a
    call DayTestClear
    ld a, $fe
    ld [wDayOffset], a
    ld a, $ff
    ld [wDayOffset + 1], a
    ld [wDayOffset + 2], a
    ld [wDayOffset + 3], a
    ld a, 4
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ; 86. Positive maximum 2^31-1 -> 2^32-1.
    ld a, 86
    ld [wTestCase], a
    call DayTestClear
    ld a, $ff
    ld [wDayOffset], a
    ld [wDayOffset + 1], a
    ld [wDayOffset + 2], a
    ld a, $7f
    ld [wDayOffset + 3], a
    ld a, $ff
    ld [wDayExpected], a
    ld [wDayExpected + 1], a
    ld [wDayExpected + 2], a
    ld [wDayExpected + 3], a
    call DayTestCompare
    jp nc, .fail

    ; 87. Negative minimum -2^31 -> 2^32 (fifth byte necessary).
    ld a, 87
    ld [wTestCase], a
    call DayTestClear
    ld a, $80
    ld [wDayOffset + 3], a
    ld a, 1
    ld [wDayExpected + 4], a
    call DayTestCompare
    jp nc, .fail
    ; Input was not modified by absolute-value computation.
    ld a, [wDayOffset + 3]
    cp $80
    jp nz, .fail

    ; 88. +65536 -> 131073 = 0x00020001.
    ld a, 88
    ld [wTestCase], a
    call DayTestClear
    ld a, 1
    ld [wDayOffset + 2], a
    ld [wDayExpected], a
    ld a, 2
    ld [wDayExpected + 2], a
    call DayTestCompare
    jp nc, .fail

    ; 89. -65536 -> 131072 = 0x00020000.
    ld a, 89
    ld [wTestCase], a
    call DayTestClear
    ld a, $ff
    ld [wDayOffset + 2], a
    ld [wDayOffset + 3], a
    ld a, 2
    ld [wDayExpected + 2], a
    call DayTestCompare
    jp nc, .fail

    ; 90. +2^30 -> 2^31+1.
    ld a, 90
    ld [wTestCase], a
    call DayTestClear
    ld a, $40
    ld [wDayOffset + 3], a
    ld a, 1
    ld [wDayExpected], a
    ld a, $80
    ld [wDayExpected + 3], a
    call DayTestCompare
    jp nc, .fail

    ; 91. -(2^31-1) -> 2^32-2.
    ld a, 91
    ld [wTestCase], a
    call DayTestClear
    ld a, 1
    ld [wDayOffset], a
    ld a, $80
    ld [wDayOffset + 3], a
    ld a, $fe
    ld [wDayExpected], a
    ld a, $ff
    ld [wDayExpected + 1], a
    ld [wDayExpected + 2], a
    ld [wDayExpected + 3], a
    call DayTestCompare
    jp nc, .fail

    ; 92. Repeated negative input (-3) -> 6; no stale carry or sign.
    ld a, 92
    ld [wTestCase], a
    call DayTestClear
    ld a, $fd
    ld [wDayOffset], a
    ld a, $ff
    ld [wDayOffset + 1], a
    ld [wDayOffset + 2], a
    ld [wDayOffset + 3], a
    ld a, 6
    ld [wDayExpected], a
    call DayTestCompare
    jp nc, .fail

    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
