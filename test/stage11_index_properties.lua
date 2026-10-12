local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local HiddenPatch = require("hidden_patch")
local LegacyHidden = require("legacy_hidden")

-- Evalye tout 7! permutasyon san kouri kalkil long sèt gout yo.
-- Valè yo distenk: zewo, siy negatif, baryè SAVE ak antye >256 bit.
local values = {
    B.from(0),
    B.from(-1),
    B.from(1),
    B.from("170141183460469231731687303715884105727"),
    B.from("170141183460469231731687303715884105728"),
    B.from("1" .. string.rep("0", 110)),
    B.from("-" .. string.rep("9", 125))
}
local used, permutation = {}, {}
local permutations, checks = 0, 0

local function verifyPermutation()
    local physical, before = {}, {}
    for k = 1, 7 do
        physical[k] = B.from(values[permutation[k]])
        before[k] = tostring(physical[k])
    end
    for k = 1, 7 do
        local expected = physical[8-k]
        local answer = HiddenPatch.hiddenByNearness(physical, k)
        assert(B.compare(answer, expected) == 0, "Plas lojik " .. k .. " pa egal fizik " .. (8-k))
        assert(tostring(answer) == before[8-k], "Valè desimal lojik la pa koresponn")
        assert(B.compare(LegacyHidden.oldHiddenAt(physical, k), physical[k]) == 0,
               "Aksè legacy fizik la te chanje")
        checks = checks + 1
    end
    for k = 1, 7 do
        assert(tostring(physical[k]) == before[k], "Yon lekti te chanje depo fizik la")
    end
    -- Tou de bout yo sou menm depo a, men opoze nan lekti lojik la.
    assert(B.compare(HiddenPatch.hiddenByNearness(physical, 1), physical[7]) == 0)
    assert(B.compare(HiddenPatch.hiddenByNearness(physical, 7), physical[1]) == 0)
    assert(B.compare(HiddenPatch.hiddenByNearness(physical, 4), physical[4]) == 0)
    permutations = permutations + 1
end

local function enumerate(depth)
    if depth == 8 then verifyPermutation(); return end
    for i = 1, 7 do
        if not used[i] then
            used[i] = true
            permutation[depth] = i
            enumerate(depth + 1)
            used[i] = false
        end
    end
end

enumerate(1)
assert(permutations == 5040 and checks == 35280,
       "Nimewo permutasyon oubyen lekti yo pa kòrèk")

-- Ka espesyal yo dwe refize anvan yo ta adrese depo a.
local physical = {}
for k = 1, 7 do physical[k] = B.from(k) end
for _, invalid in ipairs({0, -1, 8, 9, 2.5, "1", true, {}}) do
    assert(not pcall(HiddenPatch.hiddenByNearness, physical, invalid),
           "Endis ilegal pase nan PATCH 05")
end
assert(not pcall(HiddenPatch.hiddenByNearness, nil, 1))
assert(not pcall(HiddenPatch.hiddenByNearness, {}, 1))
print("PASS endis PATCH 05: 5040 permutasyon, 35280 lekti, >256 bit, validasyon")
