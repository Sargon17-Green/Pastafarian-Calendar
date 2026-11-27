>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-SAUCE.
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
01 a-offset binary-long signed.
01 t-offset binary-long signed.
01 k binary-long signed.
01 h binary-long signed.
01 di binary-long signed.
01 grind binary-long signed.
01 si binary-long signed.
01 stir binary-long signed.
01 ws-pos binary-long signed.
01 bi binary-long signed.
01 li binary-long signed.
01 ri binary-long signed.
01 ord-pos binary-long signed.
01 digit-idx binary-long signed.
01 rank-rem binary-long signed.
01 block-size binary-long signed.
01 pick-index binary-long signed.
01 remain-count binary-long signed.
01 shift-idx binary-long signed.
01 weight-two pic x(39).
01 weight-three pic x(39).
01 weight-four pic x(39).
01 weight-five pic x(39).
01 index-text pic x(39).
01 grind-text pic x(39).
01 position-text pic x(39).
01 x-value pic x(39).
01 pour-value pic x(39).
01 total-value pic x(39).
01 rank-source pic x(39).
01 digit-value pic 9.
01 counts.
   02 count-val pic x(39) occurs 5 times.
01 stones.
   02 stone-row occurs 46 times.
      03 stone-val pic x(39) occurs 5 times.
01 primes.
   02 prime-val pic x(39) occurs 14 times.
01 drops.
   02 drop-val pic x(39) occurs 53 times.
01 old-bowls.
   02 bowl-val pic x(39) occurs 6 times.
01 new-bowls.
   02 new-val pic x(39) occurs 6 times.
01 current-order.
   02 order-val binary-long signed occurs 6 times.
01 visible-order.
   02 visible-val binary-long signed occurs 6 times.
01 remaining-table.
   02 remaining-val binary-long signed occurs 6 times.
linkage section.
01 action-rd binary-long signed.
01 target-rd binary-long signed.
01 output-bowls.
   02 output-bowl pic x(39) occurs 6 times.
01 output-order.
   02 output-index binary-long signed occurs 6 times.
01 result-status binary-short unsigned.
procedure division using action-rd target-rd output-bowls
    output-order result-status.
main.
    move all "0" to output-bowls
    initialize output-order
    move 22 to result-status
    if action-rd < epoch-rd - 20000 or
       action-rd > epoch-rd + 20000 or
       target-rd < epoch-rd - 20000 or
       target-rd > epoch-rd + 20000
        goback
    end-if
    compute a-offset = action-rd - epoch-rd
    compute t-offset = target-rd - epoch-rd
    if a-offset < 0
        compute small-value = -2 * a-offset
        move all "0" to count-val(1)
        move small-value to count-val(1)(28:12)
    else
        compute small-value = 2 * a-offset + 1
        move all "0" to count-val(1)
        move small-value to count-val(1)(28:12)
    end-if
    if t-offset < 0
        compute small-value = -2 * t-offset
        move all "0" to count-val(2)
        move small-value to count-val(2)(28:12)
    else
        compute small-value = 2 * t-offset + 1
        move all "0" to count-val(2)
        move small-value to count-val(2)(28:12)
    end-if
    compute small-value = function abs(t-offset - a-offset) + 1
    move all "0" to count-val(3)
    move small-value to count-val(3)(28:12)
    move count-val(1) to operand-a
    move count-val(2) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move scratch-val(1) to count-val(4)
    evaluate true
    when target-rd < action-rd
        move "000000000000000000000000000000000000001" to count-val(5)
    when target-rd = action-rd
        move "000000000000000000000000000000000000002" to count-val(5)
    when other
        move "000000000000000000000000000000000000003" to count-val(5)
    end-evaluate
    move "000000000000000000000000000000000000017" to stone-val(1, 1)
    move "000000000000000000000000000000000000029" to stone-val(1, 2)
    move "000000000000000000000000000000000000043" to stone-val(1, 3)
    move "000000000000000000000000000000000000071" to stone-val(1, 4)
    move "000000000000000000000000000000000000101" to stone-val(1, 5)
    move "000000000000000000000000000000000000003" to prime-val(1)
    move "000000000000000000000000000000000000005" to prime-val(2)
    move "000000000000000000000000000000000000007" to prime-val(3)
    move "000000000000000000000000000000000000011" to prime-val(4)
    move "000000000000000000000000000000000000013" to prime-val(5)
    move "000000000000000000000000000000000000017" to prime-val(6)
    move "000000000000000000000000000000000000019" to prime-val(7)
    move "000000000000000000000000000000000000023" to prime-val(8)
    move "000000000000000000000000000000000000029" to prime-val(9)
    move "000000000000000000000000000000000000031" to prime-val(10)
    move "000000000000000000000000000000000000037" to prime-val(11)
    move "000000000000000000000000000000000000041" to prime-val(12)
    move "000000000000000000000000000000000000043" to prime-val(13)
    move "000000000000000000000000000000000000047" to prime-val(14)
    perform varying k from 2 by 1 until k > 46
        compute small-value = k
        move all "0" to index-text
        move small-value to index-text(28:12)
        move stone-val(k - 1, 1) to operand-a
        move stone-val(k - 1, 1) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move "000000000000000000000000000000000000003" to operand-a
        move stone-val(k - 1, 2) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move index-text to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to stone-val(k, 1)
        move stone-val(k - 1, 2) to operand-a
        move stone-val(k - 1, 2) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move "000000000000000000000000000000000000005" to operand-a
        move stone-val(k - 1, 3) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move stone-val(k - 1, 1) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to stone-val(k, 2)
        move stone-val(k - 1, 3) to operand-a
        move stone-val(k - 1, 3) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move "000000000000000000000000000000000000007" to operand-a
        move stone-val(k - 1, 4) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move stone-val(k - 1, 2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to stone-val(k, 3)
        move stone-val(k - 1, 4) to operand-a
        move stone-val(k - 1, 4) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move "000000000000000000000000000000000000011" to operand-a
        move stone-val(k - 1, 5) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move stone-val(k - 1, 3) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to stone-val(k, 4)
        move stone-val(k - 1, 5) to operand-a
        move stone-val(k - 1, 5) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move "000000000000000000000000000000000000013" to operand-a
        move stone-val(k - 1, 1) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move stone-val(k - 1, 4) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to stone-val(k, 5)
    end-perform
    perform varying h from 7 by -1 until h < 1
        compute di = 8 - h
        compute small-value = 2 * h + 1
        move all "0" to weight-two
        move small-value to weight-two(28:12)
        compute small-value = 3 * h + 1
        move all "0" to weight-three
        move small-value to weight-three(28:12)
        compute small-value = 4 * h + 2
        move all "0" to weight-four
        move small-value to weight-four(28:12)
        compute small-value = 4 * h + 4
        move all "0" to weight-five
        move small-value to weight-five(28:12)
        move weight-two to operand-a
        move count-val(2) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move count-val(1) to operand-a
        move scratch-val(1) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move weight-three to operand-a
        move count-val(3) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(2) to operand-a
        move scratch-val(3) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move weight-four to operand-a
        move count-val(4) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(5)
        move scratch-val(4) to operand-a
        move scratch-val(5) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(6)
        move weight-five to operand-a
        move count-val(5) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(7)
        move scratch-val(6) to operand-a
        move scratch-val(7) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(8)
        move scratch-val(8) to operand-a
        move stone-val(h, 1) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(9)
        move scratch-val(9) to operand-a
        move stone-val(h, 2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(10)
        move scratch-val(10) to operand-a
        move stone-val(h, 3) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(11)
        move scratch-val(11) to operand-a
        move stone-val(h, 4) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(12)
        move scratch-val(12) to operand-a
        move stone-val(h, 5) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(13)
        move scratch-val(13) to x-value
        perform varying grind from 1 by 1 until grind > 7
            compute si = function mod(grind - 1, 5) + 1
            compute small-value = grind
            move all "0" to grind-text
            move small-value to grind-text(28:12)
            move x-value to operand-a
            move x-value to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(1)
            move "000000000000000000000000000000000000003" to operand-a
            move x-value to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(2)
            move scratch-val(1) to operand-a
            move scratch-val(2) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(3)
            move scratch-val(3) to operand-a
            move stone-val(h, si) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(4)
            move scratch-val(4) to operand-a
            move grind-text to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(5)
            move scratch-val(5) to x-value
        end-perform
        move x-value to drop-val(di)
    end-perform
    move "000000000000000000000000000000000000001" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000289" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000001" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000000289" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000001" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(1)
    move "000000000000000000000000000000000000002" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000361" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000002" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000000361" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000002" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(2)
    move "000000000000000000000000000000000000003" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000529" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000003" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000000529" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000003" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(3)
    move "000000000000000000000000000000000000004" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000841" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000004" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000000841" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000004" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(4)
    move "000000000000000000000000000000000000005" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000000961" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000005" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000000961" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000005" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(5)
    move "000000000000000000000000000000000000006" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(1)
    move count-val(1) to operand-a
    move scratch-val(1) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(2)
    move scratch-val(2) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(3)
    move scratch-val(3) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(4)
    move scratch-val(4) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(5)
    move scratch-val(5) to operand-a
    move "000000000000000000000000000000000001369" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(6)
    move "000000000000000000000000000000000000006" to operand-a
    move count-val(2) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(7)
    move count-val(1) to operand-a
    move scratch-val(7) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(8)
    move scratch-val(8) to operand-a
    move count-val(3) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(9)
    move scratch-val(9) to operand-a
    move count-val(4) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(10)
    move scratch-val(10) to operand-a
    move count-val(5) to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(11)
    move scratch-val(11) to operand-a
    move "000000000000000000000000000000000001369" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(12)
    move scratch-val(6) to operand-a
    move scratch-val(12) to operand-b
    move "*" to op-code
    perform mod-op
    move mod-result to scratch-val(13)
    move scratch-val(13) to operand-a
    move "000000000000000000000000000000000000006" to operand-b
    move "+" to op-code
    perform mod-op
    move mod-result to scratch-val(14)
    move scratch-val(14) to bowl-val(6)
    perform varying k from 1 by 1 until k > 46
        compute di = k + 7
        compute small-value = k
        move all "0" to index-text
        move small-value to index-text(28:12)
        move stone-val(k, 1) to operand-a
        move count-val(1) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move stone-val(k, 2) to operand-a
        move count-val(2) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(1) to operand-a
        move scratch-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move stone-val(k, 3) to operand-a
        move count-val(3) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(3) to operand-a
        move scratch-val(4) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(5)
        move stone-val(k, 4) to operand-a
        move count-val(4) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(6)
        move scratch-val(5) to operand-a
        move scratch-val(6) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(7)
        move stone-val(k, 5) to operand-a
        move count-val(5) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(8)
        move scratch-val(7) to operand-a
        move scratch-val(8) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(9)
        move scratch-val(9) to operand-a
        move drop-val(di - 1) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(10)
        move "000000000000000000000000000000000000003" to operand-a
        move drop-val(di - 3) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(11)
        move scratch-val(10) to operand-a
        move scratch-val(11) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(12)
        move "000000000000000000000000000000000000005" to operand-a
        move drop-val(di - 7) to operand-b
        move "*" to op-code
        perform mod-op
        move mod-result to scratch-val(13)
        move scratch-val(12) to operand-a
        move scratch-val(13) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(14)
        move scratch-val(14) to operand-a
        move index-text to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(15)
        move scratch-val(15) to x-value
        perform varying grind from 1 by 1 until grind > 11
            compute si = function mod(grind - 1, 5) + 1
            move x-value to operand-a
            move x-value to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(1)
            move prime-val(grind) to operand-a
            move x-value to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(2)
            move scratch-val(1) to operand-a
            move scratch-val(2) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(3)
            move prime-val(grind + 1) to operand-a
            move drop-val(di - 1) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(4)
            move scratch-val(3) to operand-a
            move scratch-val(4) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(5)
            move prime-val(grind + 2) to operand-a
            move drop-val(di - 3) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(6)
            move scratch-val(5) to operand-a
            move scratch-val(6) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(7)
            move prime-val(grind + 3) to operand-a
            move drop-val(di - 7) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(8)
            move scratch-val(7) to operand-a
            move scratch-val(8) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(9)
            move scratch-val(9) to operand-a
            move stone-val(k, si) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(10)
            move scratch-val(10) to x-value
        end-perform
        move x-value to drop-val(di) rank-source
        perform make-order
        move current-order to visible-order
        perform varying ws-pos from 1 by 1 until ws-pos > 6
            perform neighbours
            compute si = function mod(ws-pos - 1, 5) + 1
            move "000000000000000000000000000000000000000" to pour-value
            if ws-pos <= 3
                compute small-value = (2 * ws-pos + 1) * k
                move all "0" to position-text
                move small-value to position-text(28:12)
                move x-value to operand-a
                move x-value to operand-b
                move "*" to op-code
                perform mod-op
                move mod-result to scratch-val(1)
                move stone-val(k, ws-pos) to operand-a
                move bowl-val(bi) to operand-b
                move "*" to op-code
                perform mod-op
                move mod-result to scratch-val(2)
                move scratch-val(1) to operand-a
                move scratch-val(2) to operand-b
                move "+" to op-code
                perform mod-op
                move mod-result to scratch-val(3)
                move scratch-val(3) to operand-a
                move position-text to operand-b
                move "+" to op-code
                perform mod-op
                move mod-result to scratch-val(4)
                move scratch-val(4) to pour-value
            end-if
            compute small-value = k * ws-pos
            move all "0" to position-text
            move small-value to position-text(28:12)
            move "000000000000000000000000000000000000002" to operand-a
            move bowl-val(li) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(1)
            move bowl-val(bi) to operand-a
            move scratch-val(1) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(2)
            move "000000000000000000000000000000000000003" to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(3)
            move scratch-val(2) to operand-a
            move scratch-val(3) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(4)
            move scratch-val(4) to operand-a
            move pour-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(5)
            move scratch-val(5) to operand-a
            move x-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(6)
            move scratch-val(6) to operand-a
            move stone-val(k, si) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(7)
            move "000000000000000000000000000000000000002" to operand-a
            move bowl-val(li) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(8)
            move bowl-val(bi) to operand-a
            move scratch-val(8) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(9)
            move "000000000000000000000000000000000000003" to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(10)
            move scratch-val(9) to operand-a
            move scratch-val(10) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(11)
            move scratch-val(11) to operand-a
            move pour-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(12)
            move scratch-val(12) to operand-a
            move x-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(13)
            move scratch-val(13) to operand-a
            move stone-val(k, si) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(14)
            move scratch-val(7) to operand-a
            move scratch-val(14) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(15)
            move bowl-val(li) to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(16)
            move "000000000000000000000000000000000000005" to operand-a
            move scratch-val(16) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(17)
            move scratch-val(15) to operand-a
            move scratch-val(17) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(18)
            move scratch-val(18) to operand-a
            move position-text to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(19)
            move scratch-val(19) to new-val(bi)
        end-perform
        move new-bowls to old-bowls
    end-perform
    perform varying stir from 1 by 1 until stir > 12
        compute small-value = 149 * stir
        move all "0" to index-text
        move small-value to index-text(28:12)
        move bowl-val(1) to operand-a
        move bowl-val(2) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(1)
        move scratch-val(1) to operand-a
        move bowl-val(3) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(2)
        move scratch-val(2) to operand-a
        move bowl-val(4) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(3)
        move scratch-val(3) to operand-a
        move bowl-val(5) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(4)
        move scratch-val(4) to operand-a
        move bowl-val(6) to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(5)
        move scratch-val(5) to operand-a
        move index-text to operand-b
        move "+" to op-code
        perform mod-op
        move mod-result to scratch-val(6)
        move scratch-val(6) to total-value
        move total-value to rank-source
        perform make-order
        perform varying ws-pos from 1 by 1 until ws-pos > 6
            perform neighbours
            compute small-value = stir + ws-pos * ws-pos
            move all "0" to position-text
            move small-value to position-text(28:12)
            move "000000000000000000000000000000000000003" to operand-a
            move bowl-val(li) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(1)
            move bowl-val(bi) to operand-a
            move scratch-val(1) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(2)
            move "000000000000000000000000000000000000005" to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(3)
            move scratch-val(2) to operand-a
            move scratch-val(3) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(4)
            move scratch-val(4) to operand-a
            move total-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(5)
            move scratch-val(5) to operand-a
            move position-text to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(6)
            move "000000000000000000000000000000000000003" to operand-a
            move bowl-val(li) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(7)
            move bowl-val(bi) to operand-a
            move scratch-val(7) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(8)
            move "000000000000000000000000000000000000005" to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(9)
            move scratch-val(8) to operand-a
            move scratch-val(9) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(10)
            move scratch-val(10) to operand-a
            move total-value to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(11)
            move scratch-val(11) to operand-a
            move position-text to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(12)
            move scratch-val(6) to operand-a
            move scratch-val(12) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(13)
            move bowl-val(li) to operand-a
            move bowl-val(ri) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(14)
            move "000000000000000000000000000000000000007" to operand-a
            move scratch-val(14) to operand-b
            move "*" to op-code
            perform mod-op
            move mod-result to scratch-val(15)
            move scratch-val(13) to operand-a
            move scratch-val(15) to operand-b
            move "+" to op-code
            perform mod-op
            move mod-result to scratch-val(16)
            move scratch-val(16) to new-val(bi)
        end-perform
        move new-bowls to old-bowls
    end-perform
    move old-bowls to output-bowls
    move visible-order to output-order
    move 0 to result-status
    goback.
neighbours.
    move order-val(ws-pos) to bi
    move order-val(function mod(ws-pos + 4, 6) + 1) to li
    move order-val(function mod(ws-pos, 6) + 1) to ri.
make-order.
    move 0 to rank-rem
    perform varying digit-idx from 1 by 1 until digit-idx > 39
        move rank-source(digit-idx:1) to digit-value
        compute rank-rem = function mod(rank-rem * 10
            + digit-value, 720)
    end-perform
    compute rank-rem = function mod(rank-rem + 719, 720)
    perform varying ord-pos from 1 by 1 until ord-pos > 6
        move ord-pos to remaining-val(ord-pos)
    end-perform
    perform varying ord-pos from 1 by 1 until ord-pos > 6
        evaluate ord-pos
            when 1 move 120 to block-size
            when 2 move 24 to block-size
            when 3 move 6 to block-size
            when 4 move 2 to block-size
            when other move 1 to block-size
        end-evaluate
        compute pick-index = function integer(
            rank-rem / block-size) + 1
        compute rank-rem = function mod(rank-rem, block-size)
        move remaining-val(pick-index) to order-val(ord-pos)
        compute remain-count = 7 - ord-pos
        perform varying shift-idx from pick-index by 1
            until shift-idx >= remain-count
            move remaining-val(shift-idx + 1)
                to remaining-val(shift-idx)
        end-perform
    end-perform.
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
end program CALENDAR-SAUCE.
