local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyPrior = require("legacy_prior")
local HiddenPatch = require("hidden_patch")
local PriorPatch = {}

local function validate(i, back)
    assert(type(i)=="number" and math.type(i)=="integer" and i>=1,
           "Endis gout vizib la dwe yon antye pozitif")
    assert(type(back)=="number" and math.type(back)=="integer" and back>=1 and back<=7,
           "Kantite etap dèyè a dwe ant 1 ak 7")
end

-- Li history legacy dirèkteman pou slot pozitif; pou 0..-6,
-- HiddenPatch tradui hiddenK nan plas fizik 8-hiddenK.
function PriorPatch.priorPatch(dropStore, hiddenPhysical, i, back)
    validate(i, back)
    local slot = i-back
    if slot >= 1 then
        assert(type(dropStore)=="table", "Depo gout vizib la dwe yon tablo")
        local value = LegacyPrior.legacyPrior(dropStore, i, back)
        if value==nil then return nil end
        return BigInt.from(value)
    end
    local hiddenK = 1-slot
    return BigInt.from(HiddenPatch.hiddenByNearness(hiddenPhysical, hiddenK))
end

local function physicalFromLegacyContext(context)
    local state = assert(assert(context.nestedHiddenContext).semanticState)
    local physical = {}
    for k=1,7 do physical[k]=BigInt.from(state["physical"..k]) end
    return physical
end

function PriorPatch.execute(dropStore, calculationDay, targetDay, i, back)
    validate(i, back)
    local owned = LegacyPrior.copyStore(dropStore)
    local legacyValue, context = LegacyPrior.execute(owned, calculationDay, targetDay, i, back)
    local oldMissing = legacyValue == nil
    local slot = i-back
    local physical = slot<1 and physicalFromLegacyContext(context) or nil
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_PRIOR"
    context.mode = "STAGE_13_PATCH_06"
    context.status = "PATCH_PRIOR_PENDING"
    manager.dispatcher:register("PRIOR_PATCH", function(active, owner)
        local result = PriorPatch.priorPatch(owned, physical, i, back)
        local missing = result==nil
        local hiddenK = slot<1 and 1-slot or nil
        local candidate = {
            visibleIndex=i, back=back, requestedSlot=slot,
            hiddenIndex=hiddenK or "NONE",
            physicalHiddenIndex=hiddenK and (8-hiddenK) or "NONE",
            originalLegacyMissing=oldMissing,
            legacyValueDecimal=oldMissing and "MISSING" or tostring(legacyValue),
            hasValue=not missing,
            resultDecimal=missing and "MISSING" or tostring(result),
            source=hiddenK and "HIDDEN_HISTORY_BACKFILL" or "VISIBLE_HISTORY_PRESERVED",
            legacyCallPreserved=true, hiddenStorageUnchanged=true
        }
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("prior.patch.calls")
        if hiddenK then
            owner.metricsManager:bump("prior.patch.hiddenReads")
            owner.metricsManager:observe("prior.patch.hiddenIndex", tostring(hiddenK))
        else
            owner.metricsManager:bump("prior.patch.visibleReads")
        end
        owner.metricsManager:observe("prior.patch.lastSlot", tostring(slot))
        active.diagnostics[#active.diagnostics+1] = {
            code=hiddenK and "PATCH_06_REMAP_TO_HIDDEN" or "PATCH_06_PRESERVE_VISIBLE_LEGACY",
            phase=active.phase, requestedSlot=slot,
            hiddenIndex=hiddenK or "NONE", oldMissing=oldMissing
        }
        active.status=missing and "PATCH_PRIOR_MISSING" or "PATCH_PRIOR_RETURNED"
        if missing then return {found=false} end
        return {found=true, value=BigInt.from(result)}
    end)
    local envelope = manager.dispatcher:dispatch(context, "PRIOR_PATCH", manager)
    return envelope.value, context
end
return PriorPatch
