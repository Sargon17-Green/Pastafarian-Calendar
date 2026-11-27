>>SOURCE FORMAT FREE
identification division.
program-id. INT02-YEAR-DRIVER.
data division.
working-storage section.
01 action-rd binary-long signed.
01 gate-count binary-long signed.
01 gates.
   02 gate-rd binary-long signed occurs 280 times.
01 requested-rank binary-long signed.
01 candidate-count binary-long signed.
01 candidates.
   02 candidate occurs 19600 times.
      03 opening-rd binary-long signed.
      03 closing-rd binary-long signed.
01 selected-open binary-long signed.
01 selected-close binary-long signed.
01 result-status binary-short unsigned.
01 ix binary-long signed.
01 input-line pic x(32).
01 fmt1 pic +9(9).
01 fmt2 pic +9(9).
procedure division.
    accept input-line
    compute action-rd = function numval(input-line)
    accept input-line
    compute gate-count = function numval(input-line)
    accept input-line
    compute requested-rank = function numval(input-line)
    if gate-count >= 1 and gate-count <= 280
        perform varying ix from 1 by 1 until ix > gate-count
            accept input-line
            compute gate-rd(ix) = function numval(input-line)
        end-perform
    end-if
    call "CALENDAR-YEAR-CANDIDATES" using action-rd gate-count gates
        requested-rank candidate-count candidates
        selected-open selected-close result-status
    display "STATUS " result-status
    display "COUNT " candidate-count
    move selected-open to fmt1
    move selected-close to fmt2
    display "SELECT " fmt1 " " fmt2
    perform varying ix from 1 by 1 until ix > candidate-count
        move opening-rd(ix) to fmt1
        move closing-rd(ix) to fmt2
        display "C " fmt1 " " fmt2
    end-perform
    move 0 to return-code
    goback.
end program INT02-YEAR-DRIVER.
