>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-SAVE.
data division.
local-storage section.
01 radix constant as 10000000000000.
01 modulus-hi constant as 1701411834604.
01 modulus-mid constant as 6923173168730.
01 modulus-lo constant as 3715884105727.
01 hi pic s9(15) comp-3.
01 mid pic s9(15) comp-3.
01 lo pic s9(15) comp-3.
01 temp-value pic s9(15) comp-3.
01 carry-value pic s9(15) comp-3.
01 borrow-value pic s9(15) comp-3.
01 digit-value pic 9.
01 ix binary-long signed.
01 output-parts.
   02 output-hi pic 9(13).
   02 output-mid pic 9(13).
   02 output-lo pic 9(13).
linkage section.
01 input-sign pic x.
01 input-digits pic x(96).
01 saved-digits pic x(39).
01 result-status binary-short unsigned.
procedure division using input-sign input-digits
    saved-digits result-status.
main.
    move all "0" to saved-digits
    move 22 to result-status
    if input-sign not = "+" and input-sign not = "-"
        goback
    end-if
    if input-digits is not numeric
        goback
    end-if
    move 0 to hi mid lo
    perform varying ix from 1 by 1 until ix > 96
        move input-digits(ix:1) to digit-value
        compute temp-value = lo * 10 + digit-value
        divide temp-value by radix giving carry-value
            remainder lo
        compute temp-value = mid * 10 + carry-value
        divide temp-value by radix giving carry-value
            remainder mid
        compute hi = hi * 10 + carry-value
        *> hi deliberately remains unnormalized until reduction.
        perform until hi < modulus-hi or
            (hi = modulus-hi and mid < modulus-mid) or
            (hi = modulus-hi and mid = modulus-mid
             and lo < modulus-lo)
            perform subtract-modulus
        end-perform
    end-perform
    if hi = 0 and mid = 0 and lo = 0
        move modulus-hi to hi
        move modulus-mid to mid
        move modulus-lo to lo
    else
        if input-sign = "-"
            move 0 to borrow-value
            compute lo = modulus-lo - lo
            if lo < 0
                add radix to lo
                move 1 to borrow-value
            end-if
            compute mid = modulus-mid - mid - borrow-value
            move 0 to borrow-value
            if mid < 0
                add radix to mid
                move 1 to borrow-value
            end-if
            compute hi = modulus-hi - hi - borrow-value
        end-if
    end-if
    move hi to output-hi
    move mid to output-mid
    move lo to output-lo
    move output-parts to saved-digits
    move 0 to result-status
    goback.
subtract-modulus.
    move 0 to borrow-value
    subtract modulus-lo from lo
    if lo < 0
        add radix to lo
        move 1 to borrow-value
    end-if
    compute mid = mid - modulus-mid - borrow-value
    move 0 to borrow-value
    if mid < 0
        add radix to mid
        move 1 to borrow-value
    end-if
    compute hi = hi - modulus-hi - borrow-value.
end program CALENDAR-SAVE.
