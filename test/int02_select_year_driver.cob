>>SOURCE FORMAT FREE
identification division.
program-id. INT02-SELECT-YEAR-DRIVER.
data division.
working-storage section.
01 rd-input pic -(9)9.
01 action-rd binary-long signed.
01 gate-n binary-long signed.
01 gates.
   02 gate-rd binary-long signed occurs 280 times.
01 candidate-n binary-long signed.
01 pairs.
   02 candidate occurs 19600 times.
      03 opening-rd binary-long signed.
      03 closing-rd binary-long signed.
01 selected-rank binary-long signed.
01 selected-open binary-long signed.
01 selected-close binary-long signed.
01 result-status binary-short unsigned.
01 i binary-long signed.
procedure division.
    accept rd-input
    compute action-rd = function numval(rd-input)
    call "CALENDAR-SELECT-YEAR" using action-rd gate-n gates
        candidate-n pairs selected-rank selected-open selected-close
        result-status
    display result-status " " gate-n " " candidate-n " "
        selected-rank " " selected-open " " selected-close
    perform varying i from 1 by 1 until i > gate-n
        display gate-rd(i)
    end-perform
    perform varying i from 1 by 1 until i > candidate-n
        display opening-rd(i) " " closing-rd(i)
    end-perform
    move 0 to return-code
    goback.
end program INT02-SELECT-YEAR-DRIVER.
