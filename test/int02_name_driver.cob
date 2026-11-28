>>SOURCE FORMAT FREE
identification division.
program-id. INT02-NAME-DRIVER.
*> Isolated differential driver. One fixed-width request per line.
*> Mode C/R/U/X, occupied 0/1, n/k 2 digits, signed rank width 61,
*> 47 two-digit name indices. Response status|result|rank|word|heap.
data division.
working-storage section.
01 request-line.
   05 req-mode pic x.
   05 req-occupied pic x.
   05 req-n pic 99.
   05 req-k pic 99.
   05 req-rank pic x(61).
   05 req-word.
      10 req-name occurs 47 times pic 99.
01 count-line pic 9(6).
01 row-no binary-long signed.
01 j binary-long signed.
01 api-op pic x(8).
01 api-n binary-long signed.
01 api-k binary-long signed.
01 api-word.
   05 api-name occurs 47 times binary-long signed.
01 api-status pic 9(4) comp-5.
01 status-edit pic 9(5).
01 word-edit.
   05 name-edit occurs 47 times pic 99.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 result-text pic x(8192).
01 rank-text pic x(8192).
01 heap-edit pic 9(18).
01 rk.
   05 rk-sign pic s9(4) comp-5.
   05 rk-chunks pic 9(18) comp-5.
   05 rk-head usage pointer.
   05 rk-tail usage pointer.
01 rs.
   05 rs-sign pic s9(4) comp-5.
   05 rs-chunks pic 9(18) comp-5.
   05 rs-head usage pointer.
   05 rs-tail usage pointer.
01 da.
   05 da-sign pic s9(4) comp-5.
   05 da-chunks pic 9(18) comp-5.
   05 da-head usage pointer.
   05 da-tail usage pointer.
01 db.
   05 db-sign pic s9(4) comp-5.
   05 db-chunks pic 9(18) comp-5.
   05 db-head usage pointer.
   05 db-tail usage pointer.
01 dout.
   05 dout-sign pic s9(4) comp-5.
   05 dout-chunks pic 9(18) comp-5.
   05 dout-head usage pointer.
   05 dout-tail usage pointer.
01 drem.
   05 drem-sign pic s9(4) comp-5.
   05 drem-chunks pic 9(18) comp-5.
   05 drem-head usage pointer.
   05 drem-tail usage pointer.
procedure division.
main.
    accept count-line
    if count-line is not numeric or count-line > 20000
        stop run returning 2
    end-if
    perform varying row-no from 1 by 1 until row-no > count-line
        accept request-line
        initialize rk rs da db dout drem
        evaluate req-mode
            when "C" move "COUNT" to api-op
            when "R" move "RANK" to api-op
            when "U" move "UNRANK" to api-op
            when other move "INVALID" to api-op
        end-evaluate
        move req-n to api-n
        move req-k to api-k
        perform varying j from 1 by 1 until j > 47
            move req-name(j) to api-name(j)
        end-perform
        move "INIT-TEXT" to svc-op
        move function trim(req-rank) to svc-text
        compute svc-len = function length(function trim(req-rank))
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len da db rk drem svc-cmp svc-status
        perform assert-service
        if req-occupied = "1"
            move "INIT-TEXT" to svc-op
            move "7" to svc-text
            move 1 to svc-len
            call "BIG-INTEGER-SERVICE" using
                svc-op svc-text svc-len da db rs drem
                svc-cmp svc-status
            perform assert-service
        end-if
        call "CALENDAR-NAME-FAMILY" using
            api-op api-n api-k api-word rk rs api-status
        move api-status to status-edit
        move "TO-TEXT" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len rs db dout drem
            svc-cmp svc-status
        perform assert-service
        move svc-text to result-text
        move "TO-TEXT" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len rk db dout drem
            svc-cmp svc-status
        perform assert-service
        move svc-text to rank-text
        perform varying j from 1 by 1 until j > 47
            move api-name(j) to name-edit(j)
        end-perform
        move "FREE-A" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len rs db dout drem
            svc-cmp svc-status
        perform assert-service
        move "FREE-A" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len rk db dout drem
            svc-cmp svc-status
        perform assert-service
        move "HEAP-LIVE" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len da db dout drem
            svc-cmp svc-status
        perform assert-service
        move svc-len to heap-edit
        display status-edit "|" function trim(result-text) "|"
            function trim(rank-text) "|" word-edit "|" heap-edit
    end-perform
    stop run returning 0.
assert-service.
    if svc-status not = 0
        display "SERVICE-ERROR " svc-op " " svc-status
            upon stderr
        stop run returning 3
    end-if.
