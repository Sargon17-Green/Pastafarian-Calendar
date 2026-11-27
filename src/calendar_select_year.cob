>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-SELECT-YEAR.
data division.
local-storage section.
78 epoch-rd value -15055671.
01 negative-n binary-long signed.
01 positive-n binary-long signed.
01 neg-gaps.
   02 neg-gap binary-long signed occurs 615 times.
01 pos-gaps.
   02 pos-gap binary-long signed occurs 615 times.
01 current-rd binary-long signed.
01 gap-index binary-long signed.
01 gap-value binary-long signed.
01 enumeration-rank binary-long signed.
01 inner-status binary-short unsigned.
linkage section.
01 action-rd binary-long signed.
01 gate-n binary-long signed.
01 gate-table.
   02 gate-rd binary-long signed occurs 280 times.
01 candidate-n binary-long signed.
01 candidate-table.
   02 candidate occurs 19600 times.
      03 opening-rd binary-long signed.
      03 closing-rd binary-long signed.
01 selected-rank binary-long signed.
01 selected-open binary-long signed.
01 selected-close binary-long signed.
01 result-status binary-short unsigned.
procedure division using action-rd gate-n gate-table candidate-n
    candidate-table selected-rank selected-open selected-close
    result-status.
    move 22 to result-status
    perform clear-output
    if action-rd < epoch-rd - 20000 or
       action-rd > epoch-rd + 20000
        goback
    end-if
    move 0 to negative-n positive-n enumeration-rank
    move epoch-rd to current-rd
    perform until current-rd < action-rd - 5778
        if negative-n >= 615 goback end-if
        add 1 to negative-n
        compute gap-index = 0 - negative-n
        call "CALENDAR-GAP" using gap-index gap-value inner-status
        perform check-gap
        move gap-value to neg-gap(negative-n)
        subtract gap-value from current-rd
    end-perform
    move epoch-rd to current-rd
    perform until current-rd > action-rd + 5778
        if positive-n >= 615 goback end-if
        add 1 to positive-n
        move positive-n to gap-index
        call "CALENDAR-GAP" using gap-index gap-value inner-status
        perform check-gap
        move gap-value to pos-gap(positive-n)
        add gap-value to current-rd
    end-perform
    call "CALENDAR-GATE-WINDOW" using action-rd negative-n neg-gaps
        positive-n pos-gaps gate-n gate-table inner-status
    perform check-status
    call "CALENDAR-YEAR-CANDIDATES" using action-rd gate-n gate-table
        enumeration-rank candidate-n candidate-table
        selected-open selected-close inner-status
    perform check-status
    if candidate-n < 1 or candidate-n > 19600
        perform clear-output
        goback
    end-if
    call "CALENDAR-SEAL10" using action-rd candidate-n
        selected-rank inner-status
    perform check-status
    if selected-rank < 1 or selected-rank > candidate-n
        perform clear-output
        goback
    end-if
    move opening-rd(selected-rank) to selected-open
    move closing-rd(selected-rank) to selected-close
    move 0 to result-status
    goback.
check-gap.
    perform check-status
    if gap-value < 42 or gap-value > 963 goback end-if.
check-status.
    if inner-status not = 0
        perform clear-output
        move inner-status to result-status
        goback
    end-if.
clear-output.
    move 0 to gate-n candidate-n selected-rank selected-open
        selected-close
    initialize gate-table candidate-table.
end program CALENDAR-SELECT-YEAR.
