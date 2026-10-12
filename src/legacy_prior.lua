local BigInt = require("bigint")
local Base = require("monster_base")
local HiddenPatch = require("hidden_patch")
local LegacyPrior = {}

local function requireIndices(i, back)
    assert(type(i) == "number" and math.type(i) == "integer" and i >= 1,
           "Endis gout vizib la dwe yon antye pozitif")
    assert(type(back) == "number" and math.type(back) == "integer" and back >= 1 and back <= 7,
           "Kantite etap dèyè a dwe yon antye ant 1 ak 7")
end

function LegacyPrior.copyStore(store)
    assert(type(store) == "table", "Depo gout vizib la dwe yon tablo")
    local owned = {}
    for index, value in pairs(store) do
        if type(index) == "number" and math.type(index) == "integer" then
            owned[index] = BigInt.from(value)
        end
    end
    return owned
end

-- Erè istorik la: li pa konnen sèt gout kache yo ditou.
-- Lè i-back <= 0, lekti sa a tonbe sou nil si store pa gen plas sa a.
-- Pa ajoute okenn tradiksyon endis hidden oubyen rele hiddenByNearness isit la.
function LegacyPrior.legacyPrior(dropStore, i, back)
    return dropStore[i-back]
end

function LegacyPrior.execute(dropStore, calculationDay, targetDay, i, back)
    requireIndices(i, back)
    local owned = LegacyPrior.copyStore(dropStore)
    -- Chemen PATCH 05 la kalkile sèt gout kache yo vre. LegacyPrior pa sèvi
    -- avèk yo pou fè lekti a: li toujou li dropStore[i-back] sèlman.
    local hidden, hiddenContext = HiddenPatch.execute(calculationDay, targetDay)
    local ctx = Base.MonsterContext.new(calculationDay, targetDay)
    ctx.phase = "LEGACY_PRIOR"
    ctx.mode = "STAGE_12_DISCOVERY_06"
    ctx.status = "LEGACY_PRIOR_PENDING"
    ctx.nestedHiddenContext = hiddenContext
    local manager = Base.MonsterManager.new(ctx)

    manager.dispatcher:register("LEGACY_PRIOR", function(active, owner)
        local slot = i-back
        local oldValue = LegacyPrior.legacyPrior(owned, i, back)
        local missing = oldValue == nil
        local candidate = {
            visibleIndex = i,
            back = back,
            requestedSlot = slot,
            hasValue = not missing,
            resultDecimal = missing and "MISSING" or tostring(oldValue),
            source = "VISIBLE_HISTORY_ONLY",
            ignoredHiddenCount = #hidden
        }
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.prior.calls")
        owner.metricsManager:observe("legacy.prior.slots", tostring(slot))
        if missing then owner.metricsManager:bump("legacy.prior.misses") end
        active.diagnostics[#active.diagnostics+1] = {
            code = missing and "HIDDEN_HISTORY_NOT_RESOLVED" or "VISIBLE_HISTORY_READ",
            phase = active.phase,
            requestedSlot = slot,
            ignoredHiddenCount = #hidden
        }
        active.status = missing and "LEGACY_PRIOR_MISSING" or "LEGACY_PRIOR_RETURNED"
        -- Yon anvlòp kenbe dispatch la detèminis menm si done a nil.
        if missing then return {value = nil, found = false} end
        return {value = BigInt.from(oldValue), found = true}
    end)
    local envelope = manager.dispatcher:dispatch(ctx, "LEGACY_PRIOR", manager)
    return envelope.value, ctx
end

return LegacyPrior
