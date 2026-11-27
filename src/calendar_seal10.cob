>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-SEAL10.
data division.
local-storage section.
01 operand-a pic x(39).
01 operand-b pic x(39).
01 op-code pic x.
01 mod-result pic x(39).
01 wide-a pic x(96).
01 wide-b pic x(96).
01 wide-out pic x(96).
01 plus-sign pic x value "+".
01 inner-status binary-short unsigned.
01 scratch-table.
   02 scratch-val pic x(39) occurs 64 times.
01 ws-action binary-long signed.
01 ws-target binary-long signed.
01 bi binary-long signed.
01 next-bowl binary-long signed.
01 first-answer pic x(39).
01 direction-val pic x(39).
01 sauce-bowls.
   02 bowl-val pic x(39) occurs 6 times.
01 sauce-order.
   02 order-val binary-long signed occurs 6 times.
linkage section.
01 action-rd binary-long signed.
01 candidate-n binary-long signed.
01 selected-rank binary-long signed.
01 result-status binary-short unsigned.
procedure division using action-rd candidate-n selected-rank result-status.
main.
    move 22 to result-status
    move 0 to selected-rank
    if action-rd < -15075671 or action-rd > -15035671
       or candidate-n < 1 or candidate-n > 19600
        goback
    end-if
    move action-rd to ws-action ws-target
    call "CALENDAR-SAUCE" using ws-action ws-target
        sauce-bowls sauce-order inner-status
    if inner-status not = 0
        move inner-status to result-status
        goback
    end-if
    move 1 to bi
    perform until bi > 6
        if order-val(bi) = 1 exit perform end-if
        add 1 to bi
    end-perform
    if bi > 6 goback end-if
    move order-val(function mod(bi, 6) + 1) to next-bowl
    if next-bowl < 1 or next-bowl > 6 goback end-if
    move bowl-val(1) to operand-a
    move "000000000000000000000000000000000000191" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move bowl-val(1) to operand-a
    move "000000000000000000000000000000000000191" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(1) to operand-a
    move scratch-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move "000000000000000000000000000000000000179" to operand-a
    move bowl-val(next-bowl) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(3) to operand-a
    move scratch-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000010" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move scratch-val(6) to first-answer
    move first-answer to operand-a
    move "000000000000000000000000000000000000204" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move first-answer to operand-a
    move "000000000000000000000000000000000000204" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(1) to operand-a
    move scratch-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move "000000000000000000000000000000000000193" to operand-a
    move first-answer to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(3) to operand-a
    move scratch-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move "000000000000000000000000000000000000197" to operand-a
    move bowl-val(6) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move scratch-val(5) to operand-a
    move scratch-val(6) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move scratch-val(7) to direction-val
    call "CALENDAR-SHORT-RANK" using first-answer direction-val
        candidate-n selected-rank result-status
    goback.
mod-op.
    move all "0" to wide-a wide-b
    move operand-a to wide-a(58:39)
    move operand-b to wide-b(58:39)
    call "CALENDAR-WIDE" using op-code wide-a wide-b
        wide-out inner-status
    if inner-status not = 0
        move inner-status to result-status
        goback
    end-if
    call "CALENDAR-SAVE" using plus-sign wide-out
        mod-result inner-status
    if inner-status not = 0
        move inner-status to result-status
        goback
    end-if.
end program CALENDAR-SEAL10.
