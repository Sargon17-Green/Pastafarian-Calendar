>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-NAME-FAMILY.
*> INT-02 / Tablets XX, XXI. Author source SHA256:
*> 0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae
*> Generic ordered distinct name indices (n=17 or 47 in calendar).
*> n=1..47, k=1..n; count=P(n,k); ranks one-based lexicographic.
*> COUNT/RANK return caller-owned BigInt in initially empty LK-RESULT.
*> UNRANK reads canonical positive caller-owned LK-RANK, returns
*> exactly k indices and zero trailing slots, leaves LK-RESULT empty.
*> All parameters are distinct storage; rank is a valid service handle.
*> No arena active; caller frees successful results with FREE-A.
*> Errors: 22 bad operation/size, 23 bad word/rank, 24 occupied result,
*> 49 internal invariant; underlying BigInt statuses propagated.
*> Errors preserve caller word/result/rank. No new year scope.
*> Count <=47! (60 digits); at most 47 multiplications, 47 divisions,
*> 1081 rank/unrank skip additions/subtractions; no family enumeration.
*> Independent model: 28 families, 16064 exhaustive rows,
*> 15 large inverse probes (model only, not COBOL Native).
data division.
working-storage section.
01 handles.
   05 h occurs 5 times.
      10 h-sign pic s9(4) comp-5.
      10 h-chunks pic 9(18) comp-5.
      10 h-head usage pointer.
      10 h-tail usage pointer.
01 aa.
   05 aa-SIGN PIC S9(4) COMP-5.
   05 aa-CHUNKS PIC 9(18) COMP-5.
   05 aa-HEAD USAGE POINTER.
   05 aa-TAIL USAGE POINTER.
01 bb.
   05 bb-SIGN PIC S9(4) COMP-5.
   05 bb-CHUNKS PIC 9(18) COMP-5.
   05 bb-HEAD USAGE POINTER.
   05 bb-TAIL USAGE POINTER.
01 oo.
   05 oo-SIGN PIC S9(4) COMP-5.
   05 oo-CHUNKS PIC 9(18) COMP-5.
   05 oo-HEAD USAGE POINTER.
   05 oo-TAIL USAGE POINTER.
01 rr.
   05 rr-SIGN PIC S9(4) COMP-5.
   05 rr-CHUNKS PIC 9(18) COMP-5.
   05 rr-HEAD USAGE POINTER.
   05 rr-TAIL USAGE POINTER.
01 svc-op pic x(16).
01 svc-text pic x(8192).
01 svc-len pic 9(18) comp-5.
01 svc-cmp pic s9(4) comp-5.
01 svc-status pic 9(4) comp-5.
01 ai binary-long signed.
01 bi binary-long signed.
01 oi binary-long signed.
01 slot-no binary-long signed.
01 keep-slot binary-long signed.
01 i binary-long signed.
01 j binary-long signed.
01 x binary-long signed.
01 radix binary-long signed.
01 digit-no binary-long signed.
01 left-no binary-long signed.
01 used-table.
   05 used-flag occurs 47 times pic 9.
01 scratch-word.
   05 scratch-name occurs 47 times binary-long signed.
linkage section.
01 lk-op pic x(8).
01 lk-n binary-long signed.
01 lk-k binary-long signed.
01 lk-word.
   05 lk-name occurs 47 times binary-long signed.
01 lk-rank.
   05 lk-rank-SIGN PIC S9(4) COMP-5.
   05 lk-rank-CHUNKS PIC 9(18) COMP-5.
   05 lk-rank-HEAD USAGE POINTER.
   05 lk-rank-TAIL USAGE POINTER.
01 lk-result.
   05 lk-result-SIGN PIC S9(4) COMP-5.
   05 lk-result-CHUNKS PIC 9(18) COMP-5.
   05 lk-result-HEAD USAGE POINTER.
   05 lk-result-TAIL USAGE POINTER.
01 lk-status pic 9(4) comp-5.
procedure division using lk-op lk-n lk-k lk-word
    lk-rank lk-result lk-status.
main.
    move 0 to lk-status keep-slot
    if address of lk-rank = address of lk-result
        move 22 to lk-status
        goback
    end-if
    if lk-result-sign not = 0 or lk-result-chunks not = 0
        or lk-result-head not = null or lk-result-tail not = null
        move 24 to lk-status
        goback
    end-if
    if lk-n < 1 or lk-n > 47 or lk-k < 1 or lk-k > lk-n
        or (lk-op not = "COUNT" and lk-op not = "RANK"
            and lk-op not = "UNRANK")
        move 22 to lk-status
        goback
    end-if
    initialize handles used-table scratch-word
    move 1 to oi svc-len
    move 0 to ai bi
    move "1" to svc-text
    move "INIT-TEXT" to svc-op
    perform invoke-svc
    perform varying i from 1 by 1
        until i > lk-k or lk-status not = 0
        compute svc-len = lk-n - i + 1
        move "MUL-SMALL-N" to svc-op
        move 1 to ai
        move 0 to bi
        move 3 to oi
        perform invoke-svc
        move 1 to slot-no
        perform replace-slot
    end-perform
    if lk-status = 0
        evaluate lk-op
            when "COUNT" move 1 to keep-slot
            when "RANK"
                perform rank-word
                if lk-status = 0 move 4 to keep-slot end-if
            when "UNRANK" perform unrank-word
        end-evaluate
    end-if
    perform varying slot-no from 1 by 1 until slot-no > 4
        if slot-no not = keep-slot perform release-slot end-if
    end-perform
    *> slot 5 is a borrowed descriptor; never release its input chain.
    initialize h(5)
    if lk-status = 0
        if lk-op = "UNRANK"
            move scratch-word to lk-word
        else
            move h(keep-slot) to lk-result
            initialize h(keep-slot)
        end-if
    else
        if keep-slot > 0
            move keep-slot to slot-no
            perform release-slot
        end-if
    end-if
    goback.

rank-word.
    move "1" to svc-text
    move 1 to svc-len
    move 0 to ai bi
    move 4 to oi
    move "INIT-TEXT" to svc-op
    perform invoke-svc
    perform varying i from 1 by 1
        until i > lk-k or lk-status not = 0
        move lk-name(i) to x
        if x < 1 or x > lk-n
            move 23 to lk-status
            exit perform
        end-if
        if used-flag(x) = 1
            move 23 to lk-status
            exit perform
        end-if
        perform next-block
        if lk-status not = 0 exit perform end-if
        move 0 to digit-no
        perform varying j from 1 by 1 until j >= x
            if used-flag(j) = 0 add 1 to digit-no end-if
        end-perform
        perform digit-no times
            if lk-status not = 0 exit perform end-if
            move "ADD" to svc-op
            move 4 to ai
            move 1 to bi
            move 3 to oi
            perform invoke-svc
            move 4 to slot-no
            perform replace-slot
        end-perform
        move 1 to used-flag(x)
    end-perform.

unrank-word.
    if lk-rank-sign not = 1 or lk-rank-chunks < 1
        or lk-rank-chunks > 7 or lk-rank-head = null
        or lk-rank-tail = null
        move 23 to lk-status
        exit paragraph
    end-if
    move lk-rank to h(5)
    move "CMP" to svc-op
    move 5 to ai
    move 1 to bi
    move 0 to oi
    perform invoke-svc
    if lk-status not = 0 exit paragraph end-if
    if svc-cmp > 0
        move 23 to lk-status
        exit paragraph
    end-if
    move "COPY" to svc-op
    move 5 to ai
    move 0 to bi
    move 4 to oi
    perform invoke-svc
    perform varying i from 1 by 1
        until i > lk-k or lk-status not = 0
        perform next-block
        move 0 to digit-no
        perform until digit-no >= radix or lk-status not = 0
            move "CMP" to svc-op
            move 4 to ai
            move 1 to bi
            move 0 to oi
            perform invoke-svc
            if lk-status not = 0 or svc-cmp <= 0
                exit perform
            end-if
            move "SUB" to svc-op
            move 3 to oi
            perform invoke-svc
            move 4 to slot-no
            perform replace-slot
            add 1 to digit-no
        end-perform
        if lk-status not = 0 exit perform end-if
        if digit-no >= radix
            move 49 to lk-status
            exit perform
        end-if
        move digit-no to left-no
        move 0 to x
        perform varying j from 1 by 1 until j > lk-n
            if used-flag(j) = 0
                if left-no = 0
                    move j to x
                    exit perform
                end-if
                subtract 1 from left-no
            end-if
        end-perform
        if x = 0
            move 49 to lk-status
            exit perform
        end-if
        move 1 to used-flag(x)
        move x to scratch-name(i)
    end-perform.

next-block.
    compute radix = lk-n - i + 1
    move radix to svc-len
    move "DIV-SMALL-N" to svc-op
    move 1 to ai
    move 0 to bi
    move 3 to oi
    perform invoke-svc
    move 1 to slot-no
    perform replace-slot.

invoke-svc.
    if lk-status not = 0 exit paragraph end-if
    initialize aa bb oo rr
    if ai > 0 move h(ai) to aa end-if
    if bi > 0 move h(bi) to bb end-if
    call "BIG-INTEGER-SERVICE" using
        svc-op svc-text svc-len aa bb oo rr svc-cmp svc-status
    if oi > 0 move oo to h(oi) end-if
    if svc-status not = 0 move svc-status to lk-status end-if
    *> AA/BB borrowed, OO transferred; these are descriptor aliases.
    initialize aa bb oo rr.

replace-slot.
    if lk-status not = 0 exit paragraph end-if
    perform release-slot
    if lk-status = 0
        move h(3) to h(slot-no)
        initialize h(3)
    end-if.

release-slot.
    if h-head(slot-no) not = null
        initialize bb oo rr
        move "FREE-A" to svc-op
        call "BIG-INTEGER-SERVICE" using
            svc-op svc-text svc-len h(slot-no) bb oo rr
            svc-cmp svc-status
        if svc-status not = 0 and lk-status = 0
            move svc-status to lk-status
        end-if
    end-if
    initialize h(slot-no).
