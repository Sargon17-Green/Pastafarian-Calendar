-- PATCH 08: transfere rang one-based nan unrank0, ak prèv legacy konsève.
-- Pa gen okenn operasyon vide oubyen brase bòl nan Stage 17.
local BigInt = require("bigint")
local Base = require("monster_base")
local Legacy = require("legacy_permutation")
local Patch = {}

local BLOCK = {120,24,6,2,1,1}
local function copy(order)
    local out = {}
    for i=1,6 do out[i]=order[i] end
    return out
end

-- Verifye id bòl ak rank factoradic, endepandan de fonksyon istorik la.
-- Tout rezilta kòripsyon dwe bay erè.
local function verifyOrder(order, rank0)
    assert(type(order)=="table" and #order==6, "PATCH 08: tab permutation pa valab")
    local unused={1,2,3,4,5,6}
    local reconstructed=0
    for position=1,6 do
        local id=order[position]
        assert(type(id)=="number" and math.type(id)=="integer",
               "PATCH 08: id bòl pa yon antye")
        local found
        for j=1,#unused do
            if unused[j]==id then found=j;break end
        end
        assert(found, "PATCH 08: bòl repete oubyen andeyò limit")
        reconstructed=reconstructed+(found-1)*BLOCK[position]
        table.remove(unused,found)
    end
    assert(reconstructed==rank0,"PATCH 08: unrank0 pa retounen rank koreksyon an")
end

function Patch.execute(dropValue)
    -- De premye handler yo kouri nan chemen istorik ki pa chanje.
    -- Rang 720 toujou bay dyagnostik orijinal li.
    local legacyOrder,context=Legacy.execute(dropValue)
    local oneBased=context.semanticState.rankOneBased
    assert(type(oneBased)=="number" and math.type(oneBased)=="integer"
           and oneBased>=1 and oneBased<=720,
           "PATCH 08: rank one-based la pa valab")
    local legacyRank=context.semanticState.rankActuallyPassed
    assert(legacyRank==oneBased and context.commitToken==2
           and context.pendingSemanticState==nil and context.rollbackSnapshot==nil,
           "PATCH 08: tras istorik la pa konplè")
    local legacyMissing=context.semanticState.missing
    local oldSerialized=legacyOrder and table.concat(legacyOrder,",") or "MISSING"
    local manager=Base.MonsterManager.new(context)
    context.phase="PATCH_PERM_UNRANK"
    context.mode="STAGE_17_PATCH_08"
    context.status="PATCH_PERM_PENDING"

    manager.dispatcher:register("PERMUTATION_PATCH",function(active,owner)
        -- Nou rele menm fonksyon unrank0 reyèl la ak rank korije a.
        -- Pa modifye oldOrderFromDropWrong.
        local zeroBased=oneBased-1
        local corrected=Legacy.oldPermutationUnrank0(zeroBased)
        verifyOrder(corrected,zeroBased)
        local state={}
        for k,v in pairs(active.semanticState) do state[k]=v end
        state.source="PATCH_08_ONE_BASED_TO_ZERO_BASED"
        state.legacyCallPreserved=true
        state.legacyRankActuallyPassed=legacyRank
        state.legacyMissing=legacyMissing
        state.legacyPermutation=oldSerialized
        state.rankActuallyPassed=zeroBased
        state.rankZeroBased=zeroBased
        state.missing=false
        state.permutation=table.concat(corrected,",")
        state.corrected=true
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("permutation.patch.calls")
        owner.metricsManager:bump("permutation.patch.correctedRanks")
        owner.metricsManager:observe("permutation.patch.zeroBasedRank",tostring(zeroBased))
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_08_SHIFT_ONE_BASED_RANK_DOWN_ONE",
            legacyRank=legacyRank, correctedRank=zeroBased,
            legacyMissing=legacyMissing
        }
        active.status="PATCH_PERM_RETURNED"
        return copy(corrected)
    end)
    local corrected=manager.dispatcher:dispatch(context,"PERMUTATION_PATCH",manager)
    return copy(corrected),context
end

return Patch
