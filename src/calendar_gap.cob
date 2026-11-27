>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-GAP.
data division.
local-storage section.
78 epoch-rd value -15055671.
01 operand-a pic x(39).
01 operand-b pic x(39).
01 op-code pic x.
01 mod-result pic x(39).
01 wide-a pic x(96).
01 wide-b pic x(96).
01 wide-out pic x(96).
01 plus-sign pic x value "+".
01 inner-status binary-short unsigned.
01 small-value pic 9(12).
01 scratch-table.
   02 scratch-val pic x(39) occurs 64 times.
01 ws-action binary-long signed.
01 ws-target binary-long signed.
01 bi binary-long signed.
01 next-bowl binary-long signed.
01 digit-idx binary-long signed.
01 rank-rem binary-long signed.
01 digit-value pic 9.
01 first-answer pic x(39).
01 direction-val pic x(39).
01 sauce-bowls.
   02 bowl-val pic x(39) occurs 6 times.
01 sauce-order.
   02 order-val binary-long signed occurs 6 times.
linkage section.
01 gap-index binary-long signed.
01 output-gap binary-long signed.
01 result-status binary-short unsigned.
procedure division using gap-index output-gap result-status.
main.
    move 22 to result-status
    move 0 to output-gap
    if gap-index = 0 or gap-index < -615 or
       gap-index > 615
        goback
    end-if
    move epoch-rd to ws-action
    compute ws-target = epoch-rd + gap-index
    call "CALENDAR-SAUCE" using ws-action ws-target
        sauce-bowls sauce-order inner-status
    if inner-status not = 0
        move inner-status to result-status
        goback
    end-if
    move 1 to bi
    perform until order-val(bi) = 1 or bi > 6
        add 1 to bi
    end-perform
    if bi > 6 goback end-if
    move order-val(function mod(bi, 6) + 1) to next-bowl
    move bowl-val(1) to operand-a
    move "000000000000000000000000000000000000182" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move bowl-val(1) to operand-a
    move "000000000000000000000000000000000000182" to operand-b
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
    move "000000000000000000000000000000000000001" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move scratch-val(6) to first-answer
    move first-answer to operand-a
    move "000000000000000000000000000000000000195" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move first-answer to operand-a
    move "000000000000000000000000000000000000195" to operand-b
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
    if first-answer > "170141183460469231731687303715884105506"
        move direction-val(39:1) to digit-value
        if function mod(digit-value, 2) = 1
            move 1 to rank-rem
        else
            move 922 to rank-rem
        end-if
    else
        move 0 to rank-rem
        perform varying digit-idx from 1 by 1 until digit-idx > 39
            move first-answer(digit-idx:1) to digit-value
            compute rank-rem = function mod(rank-rem * 10
                + digit-value, 922)
        end-perform
        if rank-rem = 0 move 922 to rank-rem end-if
    end-if
    compute output-gap = 41 + rank-rem
    move 0 to result-status
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
end program CALENDAR-GAP.
