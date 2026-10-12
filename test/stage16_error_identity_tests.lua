local root = arg[1] or "."
package.path = root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local Legacy = require("legacy_permutation")
local Spaghetti = require("spaghetti")

local original = Legacy.oldPermutationUnrank0
local expectedText = "Rang legacy a dwe yon antye 0..719"

-- Kontra a mande yon erè REYÈL soti nan validatè ansyen an, pa yon
-- lòt erè ki sèlman gen menm mo yo. Token an pa yon string.
local ok, actualValidation = pcall(original, 720)
assert(not ok and type(actualValidation) == "table")
assert(tostring(actualValidation) == expectedText)
assert(not pcall(original, -1))
local empty, context = Spaghetti.legacyPermutationProbe(720)
assert(empty == nil and context.status == "LEGACY_PERM_RANK_OUT_OF_RANGE")

local fakeObject = setmetatable({}, {__tostring = function() return expectedText end})
local adversarial = {
    {name="suffix", value=expectedText .. "__UNEXPECTED_CORRUPTION"},
    {name="prefix", value="UNEXPECTED_CORRUPTION__" .. expectedText},
    {name="exact-fake-string", value=expectedText},
    {name="forged-trace", value="./src/legacy_permutation.lua:11: " .. expectedText},
    {name="forged-object", value=fakeObject},
    {name="other-exception", value="UNEXPECTED_ERROR_NOT_A_RANGE_FAILURE"}
}
local checked = 0
for _, case in ipairs(adversarial) do
    Legacy.oldPermutationUnrank0 = function()
        error(case.value, 0)
    end
    local succeeded, propagated = pcall(Spaghetti.legacyPermutationProbe, 720)
    Legacy.oldPermutationUnrank0 = original
    assert(not succeeded, "Nou vale panik etranje kòm rang 720: " .. case.name)
    assert(rawequal(propagated, case.value),
           "Panik la chanje oubyen disparèt: " .. case.name)
    local normal, fresh = Spaghetti.legacyPermutationProbe(720)
    assert(normal == nil and fresh.status == "LEGACY_PERM_RANK_OUT_OF_RANGE")
    assert(fresh.commitToken == 2 and #fresh.branchTrace == 2)
    assert(fresh.metrics["legacy.permutation.rank720Rejected"] == 1)
    checked = checked + 1
end
assert(Legacy.oldPermutationUnrank0 == original)
assert(checked == 6)
print("PASS idantite erè Stage 16: 6 panik ki imite rank720 pa ka kache, 6 rekiperasyon")
