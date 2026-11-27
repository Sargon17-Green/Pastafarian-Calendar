>>SOURCE FORMAT FREE
identification division.
program-id. INT02-GAP-WINDOW-TESTS.
data division.
working-storage section.
01 action-rd binary-long signed.
01 target-rd binary-long signed.
01 gap-index binary-long signed.
01 output-gap binary-long signed.
01 result-status binary-short unsigned.
01 checks pic 99 value 0.
01 j binary-long signed.
01 sauce-bowls.
   02 bowl-val pic x(39) occurs 6 times.
01 sauce-order.
   02 order-val binary-long signed occurs 6 times.
01 neg-n binary-long signed.
01 pos-n binary-long signed.
01 neg-gaps.
   02 neg-gap binary-long signed occurs 615 times.
01 pos-gaps.
   02 pos-gap binary-long signed occurs 615 times.
01 output-n binary-long signed.
01 output-gates.
   02 output-rd binary-long signed occurs 280 times.
procedure division.
main.
    move -15055671 to action-rd target-rd
    call "CALENDAR-SAUCE" using action-rd target-rd
        sauce-bowls sauce-order result-status
    if result-status not = 0 perform fail-case end-if
    if bowl-val(1) not = "65286679584284972964194865805379907599" perform fail-case end-if
    if bowl-val(2) not = "127720283375330263615328810127751035299" perform fail-case end-if
    if bowl-val(3) not = "54364069496183805843611594721403108554" perform fail-case end-if
    if bowl-val(4) not = "93072329024469476118876155742008280619" perform fail-case end-if
    if bowl-val(5) not = "54867842942953573450868747713087920246" perform fail-case end-if
    if bowl-val(6) not = "111207247632761530752404582123499651367" perform fail-case end-if
    if order-val(1) not = 4 perform fail-case end-if
    if order-val(2) not = 5 perform fail-case end-if
    if order-val(3) not = 2 perform fail-case end-if
    if order-val(4) not = 3 perform fail-case end-if
    if order-val(5) not = 6 perform fail-case end-if
    if order-val(6) not = 1 perform fail-case end-if
    add 1 to checks
    move 12 to neg-n
    move 10 to pos-n
    move -12 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 746
        perform fail-case
    end-if
    if gap-index not = -12 perform fail-case end-if
    move output-gap to neg-gap(12)
    add 1 to checks
    move -11 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 546
        perform fail-case
    end-if
    if gap-index not = -11 perform fail-case end-if
    move output-gap to neg-gap(11)
    add 1 to checks
    move -10 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 51
        perform fail-case
    end-if
    if gap-index not = -10 perform fail-case end-if
    move output-gap to neg-gap(10)
    add 1 to checks
    move -9 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 488
        perform fail-case
    end-if
    if gap-index not = -9 perform fail-case end-if
    move output-gap to neg-gap(9)
    add 1 to checks
    move -8 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 414
        perform fail-case
    end-if
    if gap-index not = -8 perform fail-case end-if
    move output-gap to neg-gap(8)
    add 1 to checks
    move -7 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 558
        perform fail-case
    end-if
    if gap-index not = -7 perform fail-case end-if
    move output-gap to neg-gap(7)
    add 1 to checks
    move -6 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 890
        perform fail-case
    end-if
    if gap-index not = -6 perform fail-case end-if
    move output-gap to neg-gap(6)
    add 1 to checks
    move -5 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 433
        perform fail-case
    end-if
    if gap-index not = -5 perform fail-case end-if
    move output-gap to neg-gap(5)
    add 1 to checks
    move -4 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 759
        perform fail-case
    end-if
    if gap-index not = -4 perform fail-case end-if
    move output-gap to neg-gap(4)
    add 1 to checks
    move -3 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 329
        perform fail-case
    end-if
    if gap-index not = -3 perform fail-case end-if
    move output-gap to neg-gap(3)
    add 1 to checks
    move -2 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 441
        perform fail-case
    end-if
    if gap-index not = -2 perform fail-case end-if
    move output-gap to neg-gap(2)
    add 1 to checks
    move -1 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 503
        perform fail-case
    end-if
    if gap-index not = -1 perform fail-case end-if
    move output-gap to neg-gap(1)
    add 1 to checks
    move 1 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 345
        perform fail-case
    end-if
    if gap-index not = 1 perform fail-case end-if
    move output-gap to pos-gap(1)
    add 1 to checks
    move 2 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 818
        perform fail-case
    end-if
    if gap-index not = 2 perform fail-case end-if
    move output-gap to pos-gap(2)
    add 1 to checks
    move 3 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 831
        perform fail-case
    end-if
    if gap-index not = 3 perform fail-case end-if
    move output-gap to pos-gap(3)
    add 1 to checks
    move 4 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 218
        perform fail-case
    end-if
    if gap-index not = 4 perform fail-case end-if
    move output-gap to pos-gap(4)
    add 1 to checks
    move 5 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 854
        perform fail-case
    end-if
    if gap-index not = 5 perform fail-case end-if
    move output-gap to pos-gap(5)
    add 1 to checks
    move 6 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 136
        perform fail-case
    end-if
    if gap-index not = 6 perform fail-case end-if
    move output-gap to pos-gap(6)
    add 1 to checks
    move 7 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 674
        perform fail-case
    end-if
    if gap-index not = 7 perform fail-case end-if
    move output-gap to pos-gap(7)
    add 1 to checks
    move 8 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 649
        perform fail-case
    end-if
    if gap-index not = 8 perform fail-case end-if
    move output-gap to pos-gap(8)
    add 1 to checks
    move 9 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 617
        perform fail-case
    end-if
    if gap-index not = 9 perform fail-case end-if
    move output-gap to pos-gap(9)
    add 1 to checks
    move 10 to gap-index
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 0 or output-gap not = 763
        perform fail-case
    end-if
    if gap-index not = 10 perform fail-case end-if
    move output-gap to pos-gap(10)
    add 1 to checks
    call "CALENDAR-GATE-WINDOW" using action-rd neg-n neg-gaps
        pos-n pos-gaps output-n output-gates result-status
    if result-status not = 0 or output-n not = 23
        perform fail-case
    end-if
    if output-rd(1) not = -15061829 perform fail-case end-if
    if output-rd(2) not = -15061083 perform fail-case end-if
    if output-rd(3) not = -15060537 perform fail-case end-if
    if output-rd(4) not = -15060486 perform fail-case end-if
    if output-rd(5) not = -15059998 perform fail-case end-if
    if output-rd(6) not = -15059584 perform fail-case end-if
    if output-rd(7) not = -15059026 perform fail-case end-if
    if output-rd(8) not = -15058136 perform fail-case end-if
    if output-rd(9) not = -15057703 perform fail-case end-if
    if output-rd(10) not = -15056944 perform fail-case end-if
    if output-rd(11) not = -15056615 perform fail-case end-if
    if output-rd(12) not = -15056174 perform fail-case end-if
    if output-rd(13) not = -15055671 perform fail-case end-if
    if output-rd(14) not = -15055326 perform fail-case end-if
    if output-rd(15) not = -15054508 perform fail-case end-if
    if output-rd(16) not = -15053677 perform fail-case end-if
    if output-rd(17) not = -15053459 perform fail-case end-if
    if output-rd(18) not = -15052605 perform fail-case end-if
    if output-rd(19) not = -15052469 perform fail-case end-if
    if output-rd(20) not = -15051795 perform fail-case end-if
    if output-rd(21) not = -15051146 perform fail-case end-if
    if output-rd(22) not = -15050529 perform fail-case end-if
    if output-rd(23) not = -15049766 perform fail-case end-if
    perform varying j from 24 by 1 until j > 280
        if output-rd(j) not = 0 perform fail-case end-if
    end-perform
    add 1 to checks
    move 0 to gap-index
    move 999 to output-gap
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 22 or output-gap not = 0
        perform fail-case
    end-if
    add 1 to checks
    move -616 to gap-index
    move 999 to output-gap
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 22 or output-gap not = 0
        perform fail-case
    end-if
    add 1 to checks
    move 616 to gap-index
    move 999 to output-gap
    call "CALENDAR-GAP" using gap-index output-gap result-status
    if result-status not = 22 or output-gap not = 0
        perform fail-case
    end-if
    add 1 to checks
    display "GAP_WINDOW_CHECKS=" checks
    display "GAP_WINDOW_GATE=PASS"
    move 0 to return-code
    stop run.
fail-case.
    display "GAP_WINDOW_GATE=FAIL checks=" checks
        " index=" gap-index " status=" result-status
        " gap=" output-gap
    move 1 to return-code
    stop run.
end program INT02-GAP-WINDOW-TESTS.
