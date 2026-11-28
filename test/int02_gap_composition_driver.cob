>>SOURCE FORMAT FREE
identification division.
program-id. INT02-GAP-COMPOSITION-DRIVER.
data division.
working-storage section.
01 op-code pic x.
01 r binary-short unsigned.
01 k binary-short unsigned.
01 g binary-short unsigned.
01 status-code binary-short unsigned.
01 i binary-long signed.
01 inp.
   05 inp-part occurs 17 times binary-short unsigned.
01 outp.
   05 out-part occurs 17 times binary-short unsigned.
01 inp-before.
   05 inp-before-part occurs 17 times binary-short unsigned.
01 rank-before.
   05 rb-SIGN PIC S9(4) COMP-5.
   05 rb-CHUNKS PIC 9(18) COMP-5.
   05 rb-HEAD USAGE POINTER.
   05 rb-TAIL USAGE POINTER.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 live-before pic 9(18) comp-5.
01 rank-in.
   05 ri-SIGN PIC S9(4) COMP-5.
   05 ri-CHUNKS PIC 9(18) COMP-5.
   05 ri-HEAD USAGE POINTER.
   05 ri-TAIL USAGE POINTER.
01 result-handle.
   05 rh-SIGN PIC S9(4) COMP-5.
   05 rh-CHUNKS PIC 9(18) COMP-5.
   05 rh-HEAD USAGE POINTER.
   05 rh-TAIL USAGE POINTER.
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
01 svc-a.
   05 sa-SIGN PIC S9(4) COMP-5.
   05 sa-CHUNKS PIC 9(18) COMP-5.
   05 sa-HEAD USAGE POINTER.
   05 sa-TAIL USAGE POINTER.
procedure division.
    initialize inp outp rank-in result-handle svc-a svc-b svc-out svc-rem
    move "HEAP-CHUNK-LIVE" to svc-op perform service-call
    move svc-len to live-before
    accept op-code
    accept r
    accept k
    accept g
    accept svc-text
    if op-code = "U"
        compute svc-len = function length(function trim(svc-text))
        move "INIT-TEXT" to svc-op perform service-call
        if svc-status not = 0 move 3 to return-code stop run end-if
        move svc-out to rank-in
        initialize svc-out
    end-if
    perform varying i from 1 by 1 until i > 17
        accept inp-part(i)
    end-perform
    move inp to inp-before
    move rank-in to rank-before
    call "CALENDAR-GAP-COMPOSITION" using op-code r k g rank-in
        inp result-handle outp status-code
    if inp not = inp-before or rank-in not = rank-before
        move 2 to return-code stop run
    end-if
    move result-handle to svc-a
    move "TO-TEXT" to svc-op perform service-call
    if svc-status not = 0 move 3 to return-code stop run end-if
    display status-code " " function trim(svc-text)
    perform varying i from 1 by 1 until i > 17
        display out-part(i)
    end-perform
    move "FREE-A" to svc-op perform service-call
    if svc-status not = 0 move 3 to return-code stop run end-if
    move rank-in to svc-a
    move "FREE-A" to svc-op perform service-call
    if svc-status not = 0 move 3 to return-code stop run end-if
    move "HEAP-CHUNK-LIVE" to svc-op perform service-call
    if svc-status not = 0 or svc-len not = live-before
        move 4 to return-code stop run
    end-if
    move 0 to return-code
    stop run.
service-call.
    call "BIG-INTEGER-SERVICE" using svc-op svc-text svc-len
        svc-a svc-b svc-out svc-rem svc-cmp svc-status.
end program INT02-GAP-COMPOSITION-DRIVER.
