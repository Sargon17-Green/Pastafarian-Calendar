>>SOURCE FORMAT FREE
identification division.
program-id. INT02-WIDE-DRIVER.
data division.
working-storage section.
01 op-code pic x.
01 a pic x(96).
01 b pic x(96).
01 out-digits pic x(96).
01 result-status binary-short unsigned.
01 a-before pic x(96).
01 b-before pic x(96).
01 op-before pic x.
procedure division.
    accept op-code
    accept a
    accept b
    move a to a-before
    move b to b-before
    move op-code to op-before
    move all "?" to out-digits
    move 65535 to result-status
    call "CALENDAR-WIDE" using op-code a b out-digits result-status
    if a not = a-before or b not = b-before or op-code not = op-before
        move 2 to return-code
        stop run
    end-if
    display result-status " " out-digits
    move 0 to return-code
    stop run.
end program INT02-WIDE-DRIVER.
