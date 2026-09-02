local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. package.path
local B = require("bigint")
local function bi(x) return B.from(x) end
local function eq(actual, expected, label)
    assert(tostring(actual) == tostring(expected), label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

eq(bi("170141183460469231731687303715884105727"), "170141183460469231731687303715884105727", "M")
eq(bi("999999999999999999") + bi("1"), "1000000000000000000", "adisyon")
eq(bi("1000000000000000000") - bi("1"), "999999999999999999", "soustraksyon")
eq(bi("12345678901234567890") * bi("9876543210"), "121932631124828532111263526900", "miltiplikasyon")
local q, r = B.divmodFloor(bi("121932631124828532111263526900"), bi("9876543210"))
eq(q, "12345678901234567890", "divizyon")
eq(r, "0", "rès")
local q2, r2 = B.divmodFloor(bi("-10"), bi("3"))
eq(q2, "-4", "divizyon planche negatif")
eq(r2, "2", "modulo eklidyen negatif")
eq(bi("2") ^ 127, "170141183460469231731687303715884105728", "pisans")
print("PASS bigint")
