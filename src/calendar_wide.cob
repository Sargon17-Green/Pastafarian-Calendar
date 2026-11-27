>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-WIDE.
data division.
local-storage section.
01 radix constant as 10000.
01 left-parts.
   02 left-limb binary-long unsigned occurs 24 times.
01 right-parts.
   02 right-limb binary-long unsigned occurs 24 times.
01 accumulators.
   02 cell-value pic 9(12) comp-3 occurs 48 times.
01 i binary-long signed.
01 j binary-long signed.
01 k binary-long signed.
01 offset-value binary-long signed.
01 piece pic 9(4).
01 carry-value pic 9(12) comp-3.
01 remainder-value pic 9(4) comp-3.
linkage section.
01 operation-code pic x.
01 left-digits pic x(96).
01 right-digits pic x(96).
01 output-digits pic x(96).
01 result-status binary-short unsigned.
procedure division using operation-code left-digits
    right-digits output-digits result-status.
main.
    move all "0" to output-digits
    move 22 to result-status
    if operation-code not = "+" and operation-code not = "*"
        goback
    end-if
    if left-digits is not numeric or right-digits is not numeric
        goback
    end-if
    initialize accumulators
    perform varying i from 1 by 1 until i > 24
        compute offset-value = 97 - 4 * i
        move left-digits(offset-value:4) to piece
        move piece to left-limb(i)
        move right-digits(offset-value:4) to piece
        move piece to right-limb(i)
    end-perform
    if operation-code = "+"
        perform varying i from 1 by 1 until i > 24
            compute cell-value(i) = left-limb(i) + right-limb(i)
        end-perform
    else
        perform varying i from 1 by 1 until i > 24
            if left-limb(i) not = 0
                perform varying j from 1 by 1 until j > 24
                    compute k = i + j - 1
                    compute cell-value(k) = cell-value(k) +
                        left-limb(i) * right-limb(j)
                end-perform
            end-if
        end-perform
    end-if
    perform varying i from 1 by 1 until i > 47
        divide cell-value(i) by radix giving carry-value
            remainder remainder-value
        move remainder-value to cell-value(i)
        compute k = i + 1
        add carry-value to cell-value(k)
    end-perform
    perform varying i from 25 by 1 until i > 48
        if cell-value(i) not = 0
            move 24 to result-status
            goback
        end-if
    end-perform
    perform varying i from 1 by 1 until i > 24
        compute offset-value = 97 - 4 * i
        move cell-value(i) to piece
        move piece to output-digits(offset-value:4)
    end-perform
    move 0 to result-status
    goback.
end program CALENDAR-WIDE.
