identification division.
program-id. CALENDAR-GATE-WINDOW.
data division.
working-storage section.
78 epoch-rd value -15055671.
78 gap-cap value 615.
78 output-cap value 280.
01 i binary-long signed.
01 j binary-long signed.
01 first-idx binary-long signed.
01 last-idx binary-long signed.
01 epoch-idx binary-long signed.
01 total-n binary-long signed.
01 lo-rd binary-long signed.
01 hi-rd binary-long signed.
01 seq-table.
   02 rd-item binary-long signed occurs 1231 times.
linkage section.
01 action-rd binary-long signed.
01 negative-n binary-long signed.
01 negative-gaps.
   02 negative-gap binary-long signed occurs 615 times.
01 positive-n binary-long signed.
01 positive-gaps.
   02 positive-gap binary-long signed occurs 615 times.
01 output-n binary-long signed.
01 output-gates.
   02 output-rd binary-long signed occurs 280 times.
01 result-status binary-short unsigned.
procedure division using action-rd negative-n negative-gaps
    positive-n positive-gaps output-n output-gates result-status.
    move 22 to result-status
    move 0 to output-n
    initialize output-gates
    if action-rd < epoch-rd - 20000 or
       action-rd > epoch-rd + 20000 or
       negative-n < 0 or negative-n > gap-cap or
       positive-n < 0 or positive-n > gap-cap
        goback
    end-if
    perform varying i from 1 by 1 until i > negative-n
        if negative-gap(i) < 42 or negative-gap(i) > 963
            goback
        end-if
    end-perform
    perform varying i from 1 by 1 until i > positive-n
        if positive-gap(i) < 42 or positive-gap(i) > 963
            goback
        end-if
    end-perform
    compute epoch-idx = negative-n + 1
    compute total-n = epoch-idx + positive-n
    move epoch-rd to rd-item(epoch-idx)
    perform varying i from 1 by 1 until i > negative-n
        compute j = epoch-idx - i
        compute rd-item(j) = rd-item(j + 1) - negative-gap(i)
    end-perform
    perform varying i from 1 by 1 until i > positive-n
        compute j = epoch-idx + i
        compute rd-item(j) = rd-item(j - 1) + positive-gap(i)
    end-perform
    compute lo-rd = action-rd - 5778
    compute hi-rd = action-rd + 5778
    move 0 to first-idx last-idx
    perform varying i from 1 by 1 until i > total-n
        if rd-item(i) < lo-rd
            move i to first-idx
        end-if
        if last-idx = 0 and rd-item(i) > hi-rd
            move i to last-idx
        end-if
    end-perform
    if first-idx = 0 or last-idx = 0
        goback
    end-if
    compute j = last-idx - first-idx + 1
    if j < 2 or j > output-cap
        goback
    end-if
    move j to output-n
    perform varying i from 1 by 1 until i > output-n
        compute j = first-idx + i - 1
        move rd-item(j) to output-rd(i)
    end-perform
    move 0 to result-status
    goback.
end program CALENDAR-GATE-WINDOW.
