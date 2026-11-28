>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-MONTH-COMPOSITION.
data division.
local-storage section.
*> Little-endian base 10^9, 99 digits, no heap table handles.
01 dp-table.
   05 dp-row occurs 48 times.
      10 dp-cell occurs 5779 times.
         15 dp-limb occurs 11 times binary-long unsigned.
01 p binary-long signed.
01 s binary-long signed.
01 row-now binary-long signed.
01 row-prev binary-long signed.
01 col-now binary-long signed.
01 col-prev binary-long signed.
01 add-col binary-long signed.
01 sub-col binary-long signed.
01 i binary-long signed.
01 j binary-long signed.
01 remaining-days binary-long signed.
01 remaining-months binary-long signed.
01 part-index binary-long signed.
01 candidate binary-long signed.
01 candidate-max binary-long signed.
01 chosen binary-long signed.
01 offset-value binary-long signed.
01 comparison binary-long signed.
01 carry-value binary-long-long signed.
01 calc-value binary-long-long signed.
01 piece pic 9(9).
01 digits-buffer pic x(99).
01 rank-word.
   05 rank-limb occurs 11 times binary-long unsigned.
01 block-word.
   05 block-limb occurs 11 times binary-long unsigned.
01 total-word.
   05 total-limb occurs 11 times binary-long unsigned.

01 work-vector.
   05 work-part occurs 47 times binary-short unsigned.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 svc-a.
   05 sa-sign pic s9(4) comp-5.
   05 sa-chunks pic 9(18) comp-5.
   05 sa-head usage pointer.
   05 sa-tail usage pointer.
01 svc-b.
   05 sb-sign pic s9(4) comp-5.
   05 sb-chunks pic 9(18) comp-5.
   05 sb-head usage pointer.
   05 sb-tail usage pointer.
01 svc-out.
   05 so-sign pic s9(4) comp-5.
   05 so-chunks pic 9(18) comp-5.
   05 so-head usage pointer.
   05 so-tail usage pointer.
01 svc-rem.
   05 sr-sign pic s9(4) comp-5.
   05 sr-chunks pic 9(18) comp-5.
   05 sr-head usage pointer.
   05 sr-tail usage pointer.

linkage section.
01 lk-op pic x.
01 lk-y binary-short unsigned.
01 lk-m binary-short unsigned.
01 lk-rank-in.
   05 ri-sign pic s9(4) comp-5.
   05 ri-chunks pic 9(18) comp-5.
   05 ri-head usage pointer.
   05 ri-tail usage pointer.

01 lk-vector-in.
   05 lk-in-part occurs 47 times binary-short unsigned.
01 lk-result.
   05 lr-sign pic s9(4) comp-5.
   05 lr-chunks pic 9(18) comp-5.
   05 lr-head usage pointer.
   05 lr-tail usage pointer.

01 lk-vector-out.
   05 lk-out-part occurs 47 times binary-short unsigned.
01 lk-status binary-short unsigned.
procedure division using lk-op lk-y lk-m lk-rank-in
    lk-vector-in lk-result lk-vector-out lk-status.
main.
    initialize lk-result lk-vector-out work-vector
        svc-a svc-b svc-out svc-rem rank-word block-word total-word
    move 22 to lk-status
    if lk-y < 252 or lk-y > 5778 or lk-m < 1 or lk-m > 47
        or lk-y < 4 * lk-m or lk-y > 123 * lk-m
        or (lk-op not = "C" and lk-op not = "R" and lk-op not = "U")
        goback
    end-if
    initialize dp-table
    move 1 to dp-limb(1, 1, 1)
    perform varying p from 1 by 1 until p > lk-m
        compute row-now = p + 1
        move p to row-prev
        perform varying s from 4 by 1 until s > lk-y
            compute col-now = s + 1
            move s to col-prev
            compute add-col = s - 3
            compute sub-col = s - 123
            move 0 to carry-value
            perform varying i from 1 by 1 until i > 11
                compute calc-value = dp-limb(row-now, col-prev, i)
                    + dp-limb(row-prev, add-col, i) + carry-value
                if sub-col > 0
                    subtract dp-limb(row-prev, sub-col, i) from calc-value
                end-if
                perform normalize-limb
                move calc-value to dp-limb(row-now, col-now, i)
            end-perform
            if carry-value not = 0
                move 24 to lk-status goback
            end-if
        end-perform
    end-perform
    compute row-now = lk-m + 1
    compute col-now = lk-y + 1
    move dp-cell(row-now, col-now) to total-word
    if lk-op = "C"
        move total-word to rank-word
        perform export-rank goback
    end-if
    move 1 to rank-limb(1)
    if lk-op = "U"
        if ri-sign not = 1 or ri-chunks > 11 goback end-if
        move lk-rank-in to svc-a
        move "TO-TEXT" to svc-op perform service-call
        if svc-status not = 0
            move svc-status to lk-status goback
        end-if
        if svc-len < 1 or svc-len > 99 goback end-if
        if svc-text(1:svc-len) is not numeric goback end-if
        move all "0" to digits-buffer
        compute offset-value = 100 - svc-len
        move svc-text(1:svc-len) to digits-buffer(offset-value:svc-len)
        perform varying i from 1 by 1 until i > 11
            compute offset-value = 100 - 9 * i
            move digits-buffer(offset-value:9) to piece
            move piece to rank-limb(i)
        end-perform
        move total-word to block-word
        perform compare-words
        if comparison > 0 goback end-if
    end-if
    move lk-y to remaining-days
    move lk-m to remaining-months
    perform varying part-index from 1 by 1 until part-index > lk-m
        compute candidate-max = function min(123,
            remaining-days - 4 * (remaining-months - 1))
        if lk-op = "R"
            if lk-in-part(part-index) < 4 or
                lk-in-part(part-index) > candidate-max goback end-if
        end-if
        move 0 to chosen
        perform varying candidate from 4 by 1 until
            candidate > candidate-max or chosen = 1
            compute col-now = remaining-days - candidate + 1
            move dp-cell(remaining-months, col-now) to block-word
            if lk-op = "R"
                if candidate < lk-in-part(part-index)
                    perform add-block
                    if carry-value not = 0 move 24 to lk-status goback end-if
                else
                    move 0 to comparison
                    perform varying i from 1 by 1 until i > 11
                        if block-limb(i) not = 0 move 1 to comparison end-if
                    end-perform
                    if comparison = 0 goback end-if
                    move 1 to chosen
                end-if
            else
                perform compare-words
                if comparison > 0
                    perform subtract-block
                    if carry-value not = 0 move 24 to lk-status goback end-if
                else
                    move 1 to chosen
                end-if
            end-if
            if chosen = 1
                move candidate to work-part(part-index)
                subtract candidate from remaining-days
                subtract 1 from remaining-months
            end-if
        end-perform
        if chosen = 0 goback end-if
    end-perform
    if remaining-days not = 0 goback end-if
    if lk-op = "R"
        perform varying j from lk-m by 1 until j >= 47
            if lk-in-part(j + 1) not = 0 goback end-if
        end-perform
        perform export-rank
    else
        initialize block-word
        move 1 to block-limb(1)
        perform compare-words
        if comparison not = 0 goback end-if
        move work-vector to lk-vector-out
        move 0 to lk-status
    end-if
    goback.
normalize-limb.
    move 0 to carry-value
    if calc-value < 0
        add 1000000000 to calc-value
        move -1 to carry-value
    else
        if calc-value >= 1000000000
            subtract 1000000000 from calc-value
            move 1 to carry-value
        end-if
    end-if.
compare-words.
    move 0 to comparison
    perform varying i from 11 by -1 until i < 1 or comparison not = 0
        evaluate true
        when rank-limb(i) > block-limb(i) move 1 to comparison
        when rank-limb(i) < block-limb(i) move -1 to comparison
        end-evaluate
    end-perform.
add-block.
    move 0 to carry-value
    perform varying i from 1 by 1 until i > 11
        compute calc-value = rank-limb(i) + block-limb(i) + carry-value
        perform normalize-limb
        move calc-value to rank-limb(i)
    end-perform.
subtract-block.
    move 0 to carry-value
    perform varying i from 1 by 1 until i > 11
        compute calc-value = rank-limb(i) - block-limb(i) + carry-value
        perform normalize-limb
        move calc-value to rank-limb(i)
    end-perform.
export-rank.
    perform varying i from 1 by 1 until i > 11
        compute offset-value = 100 - 9 * i
        move rank-limb(i) to piece
        move piece to digits-buffer(offset-value:9)
    end-perform
    move digits-buffer to svc-text
    move 99 to svc-len
    move "INIT-TEXT" to svc-op perform service-call
    move svc-status to lk-status
    if svc-status = 0 move svc-out to lk-result end-if.
service-call.
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        svc-a svc-b svc-out svc-rem svc-cmp svc-status.
end program CALENDAR-MONTH-COMPOSITION.
