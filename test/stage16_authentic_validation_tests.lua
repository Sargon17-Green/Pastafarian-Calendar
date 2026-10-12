local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local Legacy = require("legacy_permutation")
local S = require("spaghetti")

-- Validate provenance, not merely equality of an externally replayable error.
local original = Legacy.oldPermutationUnrank0
local ok, realToken = pcall(original, 720)
assert(not ok and type(realToken)=="table", "Validasyon orijinal la pa bay token prive li")

local observed=0
local function expectUntrusted(replacement, tag)
    Legacy.oldPermutationUnrank0 = replacement
    local succeeded, propagated = pcall(S.legacyPermutationProbe, 720)
    Legacy.oldPermutationUnrank0 = original
    assert(not succeeded, "Token otantik ki rejwe te pase kòm yon nouvo refi: " .. tag)
    assert(rawequal(propagated, realToken), "Token otantik la pa pase san chanjman: " .. tag)
    local result, ctx = S.legacyPermutationProbe(720)
    assert(result==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
    assert(ctx.commitToken==2)
    observed = observed+1
end

-- A monkey-patch can capture and replay the REAL error object; no strings involved.
expectUntrusted(function() error(realToken,0) end, "replay-direct")
expectUntrusted(function(rank)
    assert(rank==720)
    return original(rank)
end, "wrapper-calling-original")
-- Epitou, wrapper la ka ranplase tablo a AK fonksyon orijinal la
-- ANVAN li voye token li te kenbe a. Tcheke ki fonksyon yo te RELE,
-- pa sa ki sou tablo a apre pcall la.
do
    Legacy.oldPermutationUnrank0 = function()
        Legacy.oldPermutationUnrank0 = original
        error(realToken,0)
    end
    local succeeded, propagated = pcall(S.legacyPermutationProbe, 720)
    Legacy.oldPermutationUnrank0 = original
    assert(not succeeded and rawequal(propagated, realToken),
           "Yon wrapper restore-before-throw te kontoune gad provenans lan")
    local result, ctx = S.legacyPermutationProbe(720)
    assert(result==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
    observed = observed+1
end
assert(Legacy.oldPermutationUnrank0==original)
assert(observed==3)
print("PASS validasyon otantik Stage 16: 3 pyèj replay/wrapper/restorasyon, 3 rekiperasyon")
