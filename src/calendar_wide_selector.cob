>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-WIDE-SELECTOR.
data division.
local-storage section.
01 handles.
   02 h occurs 16 times.
      03 h-sign pic s9(4) comp-5.
      03 h-chunks pic 9(18) comp-5.
      03 h-head usage pointer.
      03 h-tail usage pointer.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 digits-used binary-short unsigned.
01 detached pic 9.
linkage section.
01 lk-n.
   05 ln-sign pic s9(4) comp-5.
   05 ln-chunks pic 9(18) comp-5.
   05 ln-head usage pointer.
   05 ln-tail usage pointer.
01 lk-a1.
   05 la-sign pic s9(4) comp-5.
   05 la-chunks pic 9(18) comp-5.
   05 la-head usage pointer.
   05 la-tail usage pointer.
01 lk-result.
   05 lr-sign pic s9(4) comp-5.
   05 lr-chunks pic 9(18) comp-5.
   05 lr-head usage pointer.
   05 lr-tail usage pointer.
01 lk-dir binary-short signed.
01 lk-d binary-short unsigned.
01 lk-status binary-short unsigned.
procedure division using lk-n lk-a1 lk-dir lk-result lk-d lk-status.
main.
    initialize handles
    move 0 to lk-status lk-d digits-used detached
    if lr-head not = null or lr-tail not = null
        or lr-chunks not = 0 or lr-sign not = 0
        or ln-sign not = 1 or ln-chunks = 0
        or la-sign not = 1 or la-chunks = 0
        or (lk-dir not = 1 and lk-dir not = -1)
        move 22 to lk-status goback
    end-if
    move lk-n to h(12)
    move lk-a1 to h(13)
    move "SCOPE-BEGIN" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(14) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status goback
    end-if
    perform calculate-rank
    if lk-status = 0
    move "ARENA-DETACH" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(10) h(14) h(15) h(16) svc-cmp svc-status
        if svc-status = 0
            move 1 to detached
        else
            move svc-status to lk-status
        end-if
    end-if
    move "SCOPE-END" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(14) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0 and lk-status = 0
        move svc-status to lk-status
    end-if
    if detached = 1
        if lk-status = 0
            move h(10) to lk-result
            move digits-used to lk-d
        else
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(10) h(14) h(15) h(16) svc-cmp svc-status
        end-if
    end-if
    goback.
calculate-rank.
    *> Only the two fixed constants cross the decimal interface.
    move "1" to svc-text move 1 to svc-len
    move "INIT-TEXT" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(14) h(14) h(1) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "170141183460469231731687303715884105727" to svc-text
    move 39 to svc-len
    move "INIT-TEXT" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(14) h(14) h(2) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "CMP" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(13) h(2) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    if svc-cmp > 0 move 22 to lk-status exit paragraph end-if
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(1) h(14) h(3) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(13) h(14) h(5) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    *> Accumulator h(4) holds X-1; h(3) holds M**(i-1).
    perform until digits-used = 253
    move "SUB" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(1) h(6) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "MUL" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(6) h(3) h(7) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "ADD" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(4) h(7) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(4) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move h(15) to h(4)
    initialize h(15)
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(6) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(7) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "MUL" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(3) h(2) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(3) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move h(15) to h(3)
    initialize h(15)
        add 1 to digits-used
    move "CMP" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(3) h(12) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
        if svc-cmp >= 0 exit perform end-if
        if digits-used = 253
            move 24 to lk-status exit paragraph
        end-if
        if lk-dir = 1
    move "CMP" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(2) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            if svc-cmp = 0
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(1) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            else
    move "ADD" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(1) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            end-if
        else
    move "CMP" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(1) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            if svc-cmp = 0
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(2) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            else
    move "SUB" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(1) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
            end-if
        end-if
    move "FREE-A" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(5) h(14) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move h(15) to h(5)
    initialize h(15)
    end-perform
    *> L = S - S mod N. X-1 >= L iff X is in the rejected suffix.
    move "MOD-EUCLID" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(3) h(12) h(8) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "SUB" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(3) h(8) h(9) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "CMP" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(4) h(9) h(15) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    if svc-cmp >= 0
        if lk-dir = 1
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(1) h(14) h(10) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
        else
    move "COPY" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(12) h(14) h(10) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
        end-if
    else
    move "MOD-EUCLID" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(4) h(12) h(11) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    move "ADD" to svc-op
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        h(11) h(1) h(10) h(16) svc-cmp svc-status
    if svc-status not = 0
        move svc-status to lk-status exit paragraph
    end-if
    end-if.
end program CALENDAR-WIDE-SELECTOR.
