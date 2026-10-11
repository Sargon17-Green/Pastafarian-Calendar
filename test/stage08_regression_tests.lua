local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local BigInt = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")

local seed = {w=17, b=29, s=43, m=71, r=101}
local wrong = S.stoneSpaghetti(2, seed)
-- Prèv test-only ki kalkile senk wòch yo sou menm snapshot ansyen an.
local expected = {
    w = O.SAVE(BigInt.from(seed.w)^2 + 3*BigInt.from(seed.b) + 2),
    b = O.SAVE(BigInt.from(seed.b)^2 + 5*BigInt.from(seed.s) + seed.w),
    s = O.SAVE(BigInt.from(seed.s)^2 + 7*BigInt.from(seed.m) + seed.b),
    m = O.SAVE(BigInt.from(seed.m)^2 + 11*BigInt.from(seed.r) + seed.s),
    r = O.SAVE(BigInt.from(seed.r)^2 + 13*BigInt.from(seed.w) + seed.m)
}
assert(BigInt.compare(wrong.w, expected.w) == 0, "Premye wòch la dwe egal")
local differences = {}
for _, name in ipairs({"b", "s", "m", "r"}) do
    if BigInt.compare(wrong[name], expected[name]) ~= 0 then
        differences[#differences+1] = name .. ": legacy=" .. tostring(wrong[name]) ..
            " normative=" .. tostring(expected[name])
    end
end
if #differences > 0 then
    error("EXPECTED_RED Stage 8 DISCOVERY 04: " .. #differences ..
          " wòch diferan apre mutation: " .. table.concat(differences, "; "), 0)
end
print("PASS Stage 8: mutation wòch yo ekivalan")
