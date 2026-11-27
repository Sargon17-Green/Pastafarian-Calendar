>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-SHORT-RANK.
data division.
local-storage section.
78 modulus-text value "170141183460469231731687303715884105727".
01 limit-text pic x(39).
01 i binary-long signed.
01 rem-x binary-long signed.
01 rem-m binary-long signed.
01 borrow-n binary-long signed.
01 digit-n binary-long signed.
01 d pic 9.
linkage section.
01 first-answer pic x(39).
01 direction-val pic x(39).
01 candidate-n binary-long signed.
01 selected-rank binary-long signed.
01 result-status binary-short unsigned.
procedure division using first-answer direction-val candidate-n
    selected-rank result-status.
    move 0 to selected-rank rem-x rem-m
    move 22 to result-status
    if candidate-n < 1 or candidate-n > 19600
       or first-answer is not numeric
       or direction-val is not numeric
       or first-answer = all "0" or direction-val = all "0"
       or first-answer > modulus-text or direction-val > modulus-text
        goback
    end-if
    move modulus-text to limit-text
    perform varying i from 1 by 1 until i > 39
        move first-answer(i:1) to d
        compute rem-x = function mod(rem-x * 10 + d, candidate-n)
        move limit-text(i:1) to d
        compute rem-m = function mod(rem-m * 10 + d, candidate-n)
    end-perform
    move rem-m to borrow-n
    perform varying i from 39 by -1 until i < 1
        move limit-text(i:1) to d
        compute digit-n = d - function mod(borrow-n, 10)
        compute borrow-n = function integer(borrow-n / 10)
        if digit-n < 0
            add 10 to digit-n
            add 1 to borrow-n
        end-if
        move digit-n to d
        move d to limit-text(i:1)
    end-perform
    if first-answer > limit-text
        move direction-val(39:1) to d
        if function mod(d, 2) = 1
            move 1 to selected-rank
        else
            move candidate-n to selected-rank
        end-if
    else
        move rem-x to selected-rank
        if selected-rank = 0 move candidate-n to selected-rank end-if
    end-if
    move 0 to result-status
    goback.
end program CALENDAR-SHORT-RANK.
