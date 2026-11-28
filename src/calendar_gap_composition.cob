>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-GAP-COMPOSITION.
data division.
local-storage section.
01 choose-table.
   05 choose-row occurs 137 times.
      10 choose-cell occurs 17 times pic 9(30).
01 n binary-long signed.
01 k binary-long signed.
01 ni binary-long signed.
01 ki binary-long signed.
01 row-prev binary-long signed.
01 col-prev binary-long signed.
01 rem-days binary-long signed.
01 parts-left binary-long signed.
01 gate-left binary-long signed.
01 child-days binary-long signed.
01 child-parts binary-long signed.
01 child-gate binary-long signed.
01 part-index binary-long signed.
01 candidate binary-long signed.
01 candidate-max binary-long signed.
01 chosen binary-short unsigned.
01 block-count pic 9(30).
01 total-count pic 9(30).
01 rank-value pic 9(30).
01 return-value pic 9(30).
01 work-vector.
   05 work-part occurs 17 times binary-short unsigned.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 svc-a.
   05 sa-SIGN PIC S9(4) COMP-5.
   05 sa-CHUNKS PIC 9(18) COMP-5.
   05 sa-HEAD USAGE POINTER.
   05 sa-TAIL USAGE POINTER.
01 svc-b.
   05 sb-SIGN PIC S9(4) COMP-5.
   05 sb-CHUNKS PIC 9(18) COMP-5.
   05 sb-HEAD USAGE POINTER.
   05 sb-TAIL USAGE POINTER.
01 svc-out.
   05 so-SIGN PIC S9(4) COMP-5.
   05 so-CHUNKS PIC 9(18) COMP-5.
   05 so-HEAD USAGE POINTER.
   05 so-TAIL USAGE POINTER.
01 svc-rem.
   05 sr-SIGN PIC S9(4) COMP-5.
   05 sr-CHUNKS PIC 9(18) COMP-5.
   05 sr-HEAD USAGE POINTER.
   05 sr-TAIL USAGE POINTER.
linkage section.
01 lk-op pic x.
01 lk-r binary-short unsigned.
01 lk-k binary-short unsigned.
01 lk-g binary-short unsigned.
01 lk-rank-in.
   05 ri-SIGN PIC S9(4) COMP-5.
   05 ri-CHUNKS PIC 9(18) COMP-5.
   05 ri-HEAD USAGE POINTER.
   05 ri-TAIL USAGE POINTER.
01 lk-vector-in.
   05 lk-in-part occurs 17 times binary-short unsigned.
01 lk-result.
   05 lr-SIGN PIC S9(4) COMP-5.
   05 lr-CHUNKS PIC 9(18) COMP-5.
   05 lr-HEAD USAGE POINTER.
   05 lr-TAIL USAGE POINTER.
01 lk-vector-out.
   05 lk-out-part occurs 17 times binary-short unsigned.
01 lk-status binary-short unsigned.
procedure division using lk-op lk-r lk-k lk-g lk-rank-in
    lk-vector-in lk-result lk-vector-out lk-status.
main.
    move 0 to lk-status
    initialize lk-result lk-vector-out work-vector
        svc-a svc-b svc-out svc-rem
    if lk-r < 6 or lk-r > 137 or lk-k < 6 or lk-k > 17
        or lk-k > lk-r or lk-g > lk-r
        or (lk-op not = "C" and lk-op not = "R" and lk-op not = "U")
        move 22 to lk-status
        goback
    end-if
    *> Pascal coefficients C(n,k), indices shifted by one.
    initialize choose-table
    move 1 to choose-cell(1, 1)
    perform varying n from 1 by 1 until n > lk-r - 1
        compute ni = n + 1
        move n to row-prev
        move 1 to choose-cell(ni, 1)
        perform varying k from 1 by 1 until k > 16 or k > n
            compute ki = k + 1
            move k to col-prev
            compute choose-cell(ni, ki) =
                choose-cell(row-prev, col-prev) + choose-cell(row-prev, ki)
        end-perform
    end-perform
    move lk-r to rem-days child-days
    move lk-k to parts-left child-parts
    move lk-g to gate-left child-gate
    if gate-left = rem-days move 0 to gate-left child-gate end-if
    perform count-child
    move block-count to total-count
    if lk-op = "C"
        move total-count to return-value
        perform export-value
        goback
    end-if
    move 1 to rank-value
    if lk-op = "U"
        *> Reject wide inputs before the text interface; legal rank <= 21 digits.
        if ri-sign not = 1 or ri-chunks > 3
            move 22 to lk-status goback
        end-if
        move lk-rank-in to svc-a
        move "TO-TEXT" to svc-op
        perform service-call
        if svc-status not = 0
            move svc-status to lk-status goback
        end-if
        if svc-len < 1 or svc-len > 21
            move 22 to lk-status goback
        end-if
        if svc-text(1:svc-len) is not numeric
            move 22 to lk-status goback
        end-if
        compute rank-value = function numval(svc-text(1:svc-len))
        if rank-value < 1 or rank-value > total-count
            move 22 to lk-status goback
        end-if
    end-if
    perform varying part-index from 1 by 1 until part-index > lk-k
        compute candidate-max = rem-days - parts-left + 1
        if lk-op = "R"
            if lk-in-part(part-index) < 1 or
                lk-in-part(part-index) > candidate-max
                move 22 to lk-status goback
            end-if
        end-if
        move 0 to chosen
        perform varying candidate from 1 by 1 until candidate > candidate-max
            or chosen = 1
            compute child-days = rem-days - candidate
            compute child-parts = parts-left - 1
            move 0 to child-gate
            if gate-left > 0
                compute child-gate = gate-left - candidate
            end-if
            perform count-child
            if lk-op = "R"
                if candidate < lk-in-part(part-index)
                    add block-count to rank-value
                else
                    if block-count = 0
                        move 22 to lk-status goback
                    end-if
                    move 1 to chosen
                end-if
            else
                if rank-value > block-count
                    subtract block-count from rank-value
                else
                    move 1 to chosen
                end-if
            end-if
            if chosen = 1
                move candidate to work-part(part-index)
                move child-days to rem-days
                move child-parts to parts-left
                move child-gate to gate-left
            end-if
        end-perform
        if chosen = 0
            move 22 to lk-status goback
        end-if
    end-perform
    if rem-days not = 0 or gate-left not = 0
        move 22 to lk-status goback
    end-if
    if lk-op = "R"
        perform varying part-index from lk-k by 1 until part-index >= 17
            if lk-in-part(part-index + 1) not = 0
                move 22 to lk-status goback
            end-if
        end-perform
        move rank-value to return-value
        perform export-value
    else
        if rank-value not = 1
            move 22 to lk-status goback
        end-if
        move work-vector to lk-vector-out
    end-if
    goback.
count-child.
    move 0 to block-count
    if child-gate < 0 or child-days < child-parts
        exit paragraph
    end-if
    if child-parts = 0
        if child-days = 0 and child-gate = 0 move 1 to block-count end-if
        exit paragraph
    end-if
    if child-gate = 0
        *> Choose p-1 cuts from r-1 positions.
        move choose-cell(child-days, child-parts) to block-count
    else
        *> One fixed interior cut; choose p-2 from the other r-2.
        if child-gate < child-days and child-parts >= 2
            compute ni = child-days - 1
            compute ki = child-parts - 1
            move choose-cell(ni, ki) to block-count
        end-if
    end-if.
export-value.
    *> Only one allocation, no local arena or scratch handle to detach.
    *> Service result belongs to the caller (or its active parent scope).
    move return-value to svc-text
    move 30 to svc-len
    move "INIT-TEXT" to svc-op
    perform service-call
    move svc-status to lk-status
    if svc-status = 0 move svc-out to lk-result end-if.
service-call.
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        svc-a svc-b svc-out svc-rem svc-cmp svc-status.
end program CALENDAR-GAP-COMPOSITION.
