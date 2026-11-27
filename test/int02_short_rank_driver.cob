>>SOURCE FORMAT FREE
identification division.
program-id. INT02-SHORT-RANK-DRIVER.
data division.
working-storage section.
01 count-text pic 9(6).
01 case-count binary-long signed.
01 i binary-long signed.
01 first-answer pic x(39).
01 direction-val pic x(39).
01 n-text pic x(8).
01 candidate-n binary-long signed.
01 selected-rank binary-long signed.
01 result-status binary-short unsigned.
procedure division.
    accept count-text
    move count-text to case-count
    if case-count < 1 or case-count > 200000
        move 2 to return-code
        goback
    end-if
    perform varying i from 1 by 1 until i > case-count
        accept first-answer
        accept direction-val
        accept n-text
        compute candidate-n = function numval(n-text)
        move -999 to selected-rank
        move 99 to result-status
        call "CALENDAR-SHORT-RANK" using first-answer
            direction-val candidate-n selected-rank result-status
        display result-status " " selected-rank
    end-perform
    move 0 to return-code
    goback.
end program INT02-SHORT-RANK-DRIVER.
