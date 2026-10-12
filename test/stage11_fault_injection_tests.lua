local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local BigInt = require("bigint")
local LegacyHidden = require("legacy_hidden")
local HiddenPatch = require("hidden_patch")
local F = -15055671

local originalRead = LegacyHidden.oldHiddenAt
local originalExecute = LegacyHidden.execute
local physical = originalExecute(F, F)
local originalDecimal = {}
for k = 1, 7 do originalDecimal[k] = tostring(physical[k]) end
local runs, errors, clones = 0, 0, 0

-- Kontra a mande yon lekti pase nan ansyen aksè a nan lòd fizik 7..1.
local visited = {}
LegacyHidden.oldHiddenAt = function(storage, k)
    visited[#visited + 1] = k
    return originalRead(storage, k)
end
local ok, patched, context = pcall(HiddenPatch.execute, F, F)
LegacyHidden.oldHiddenAt = originalRead
assert(ok, "Kalkil PATCH 05 echwe pandan n ap obsève aksè yo: " .. tostring(patched))
assert(table.concat(visited, ",") == "7,6,5,4,3,2,1", "PATCH 05 pa rele legacy nan lòd 8-k")
assert(context.commitToken == 2 and context.pendingSemanticState == nil)
for k = 1, 7 do
    assert(tostring(patched[k]) == originalDecimal[8-k])
end
runs = runs + 1

-- Yon echèk nan chak nan sèt lekti yo pa dwe tounen yon rezilta pasyèl.
-- Apre chak echèk, yon nouvo invocation dwe gen eta, tras ak metrik nòmal.
for failingSlot = 1, 7 do
    local marker = "INJECTED_HIDDEN_SLOT_" .. failingSlot
    LegacyHidden.oldHiddenAt = function(storage, k)
        if k == failingSlot then error(marker, 0) end
        return originalRead(storage, k)
    end
    local succeeded, message = pcall(HiddenPatch.execute, F, F)
    LegacyHidden.oldHiddenAt = originalRead
    assert(not succeeded and tostring(message):find(marker, 1, true),
           "Echèk sou plas fizik " .. failingSlot .. " pa rive kote li dwe rive")
    errors = errors + 1
    local fresh, freshContext = HiddenPatch.execute(F, F)
    assert(freshContext.status == "PATCH_HIDDEN_RETURNED")
    assert(freshContext.commitToken == 2)
    assert(freshContext.pendingSemanticState == nil and freshContext.rollbackSnapshot == nil)
    assert(freshContext.metrics["legacy.hidden.calls"] == 1)
    assert(freshContext.metrics["hidden.patch.calls"] == 1)
    assert(#freshContext.branchTrace == 2 and freshContext.branchTrace[1] == "LEGACY_HIDDEN")
    for k = 1, 7 do
        assert(tostring(fresh[k]) == originalDecimal[8-k], "Eta premye echèk la koule deyò")
    end
    runs = runs + 1
end

-- Echèk anvan jwenn depo legacy a dwe parèt klèman, san efè sou lòt apèl yo.
LegacyHidden.execute = function() error("INJECTED_LEGACY_EXECUTE", 0) end
local succeeded, message = pcall(HiddenPatch.execute, F, F)
LegacyHidden.execute = originalExecute
assert(not succeeded and tostring(message):find("INJECTED_LEGACY_EXECUTE", 1, true))
errors = errors + 1
local fresh, ctx = HiddenPatch.execute(F, F)
assert(ctx.commitToken == 2 and tostring(fresh[1]) == originalDecimal[7])
runs = runs + 1

-- Tout pozisyon ki manke oubyen ki pa reprezante yon BigInt valab refize.
for missingSlot = 1, 7 do
    local incomplete = {}
    for k = 1, 7 do incomplete[k] = BigInt.from(physical[k]) end
    incomplete[missingSlot] = nil
    local logicalIndex = 8 - missingSlot
    assert(not pcall(HiddenPatch.hiddenByNearness, incomplete, logicalIndex))
    for k = 1, 7 do
        if k ~= missingSlot then
            assert(tostring(incomplete[k]) == originalDecimal[k], "Yon erè modifye depo a")
        end
    end
    errors = errors + 1
end

-- BigInt yo se kopi posede, pa menm objè ki nan depo fizik la.
for k = 1, 7 do
    local answer = HiddenPatch.hiddenByNearness(physical, k)
    local slot = 8-k
    assert(not rawequal(answer, physical[slot]), "Yon gout ap pataje objè depo fizik la")
    assert(tostring(answer) == originalDecimal[slot])
    -- Detekte alias pwofon nan limb BigInt yo, si reprezantasyon an ekspoze yo.
    -- Avèk lòt reprezantasyon BigInt, modifye yon jaden nan kopi a sèlman.
    local changed = false
    if type(answer.d) == "table" and #answer.d > 0 then
        answer.d[1] = (answer.d[1] + 1) % (BigInt.BASE or 10000000)
        changed = true
    else
        for field in pairs(answer) do
            answer[field] = "INJECTED_CORRUPTION"
            changed = true
            break
        end
    end
    assert(changed and tostring(physical[slot]) == originalDecimal[slot],
           "Objè depo a chanje lè yon moun modifye repons lan")
    clones = clones + 1
end

-- Netwaye tout monkey-patch yo menm nan yon suite k ap kouri an seri.
assert(LegacyHidden.execute == originalExecute and LegacyHidden.oldHiddenAt == originalRead)
print("PASS rezilyans PATCH 05: " .. runs .. " invocation, " .. errors ..
      " echèk izole, " .. clones .. " BigInt ki pa pataje")
