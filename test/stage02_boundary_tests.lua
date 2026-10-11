local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. package.path
local B = require("bigint")
local S = require("spaghetti")
local M = B.from("170141183460469231731687303715884105727")
local count, mismatchCount = 0, 0

-- Egzamine tout deplasman -2..2 bò kote miltip M, ak toude siy.
for multiplier = -12, 12 do
    for offset = -2, 2 do
        local input = B.mul(M, B.from(multiplier)) + B.from(offset)
        local expectedRemainder
        if offset < 0 then
            expectedRemainder = M + B.from(offset)
        else
            expectedRemainder = B.from(offset)
        end
        local wrong, context = S.legacySaveProbe(input)
        local public = S.saveSpaghetti(input)
        assert(tostring(wrong) == tostring(expectedRemainder),
            "Rès legacy la pa mache pou " .. multiplier .. "M" .. offset)
        assert(tostring(public) == tostring(offset == 0 and M or expectedRemainder))
        assert(context.semanticState.inputDecimal == tostring(input))
        assert(context.semanticState.resultDecimal == tostring(expectedRemainder))
        assert(context.commitToken == 1 and context.status == "LEGACY_RETURNED")
        if offset == 0 then
            assert(tostring(wrong) == "0")
            mismatchCount = mismatchCount + 1
        else
            assert(not wrong:isZero())
        end
        count = count + 1
    end
end
assert(count == 125 and mismatchCount == 25)

-- Yon antre ki depase 256 bit rete presi, san konvèsyon floating point.
local giant = B.from("1" .. string.rep("0", 120))
local hugeValues = {
    giant, -giant, giant + M, -giant - M,
    B.mul(M, giant), -B.mul(M, giant)
}
for _, input in ipairs(hugeValues) do
    local actual = S.saveSpaghetti(input)
    assert(B.compare(actual, 1) >= 0 and B.compare(actual, M) <= 0)
    local quotient, rem = B.divmodFloor(input, M)
    assert(tostring(input) == tostring(B.mul(quotient, M) + rem),
        "Pèt presizyon nan divizyon antye gwo")
    assert(tostring(actual) == tostring(rem:isZero() and M or rem))
end
print("PASS limit Stage 2: 125 ka toupre miltip M, 6 antre gwo")
