-- PATCH 09: vide sou id bòl ki nan lòd koreksyon an.
-- Chemen LEGACY_FIXED_BOWL_POURS nan Stage 18 rete entak.
local B=require("bigint")
local Base=require("monster_base")
local Save=require("save_patch")
local Legacy=require("legacy_fixed_pours")
local Patch={}

local FAKTOR={3,5,7}
local NON={"w","b","s"}
local function copyBigints(values,count)
    local result={}
    for i=1,count do result[i]=B.from(values[i]) end
    return result
end
local function copySix(values)
    local result={}
    for i=1,6 do result[i]=values[i] end
    return result
end
local function copyTable(values)
    local result={}
    for k,v in pairs(values) do result[k]=v end
    return result
end

local function verifyLegacy(context,wrong,drop,index,oldBowls,stoneRow)
    assert(type(context)=="table"
        and context.mode=="STAGE_18_DISCOVERY_09"
        and context.status=="LEGACY_FIXED_BOWL_POURS_RETURNED"
        and context.commitToken==1 and #context.branchTrace==1
        and context.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
        and context.pendingSemanticState==nil and context.rollbackSnapshot==nil,
        "PATCH 09: tras legacy pa konplè")
    assert(type(wrong)=="table" and #wrong==3,"PATCH 09: twa vide legacy manke")
    local state=context.semanticState
    assert(type(state)=="table" and state.visibleIndex==index
        and state.dropDecimal==tostring(B.from(drop))
        and type(state.correctedOrder)=="table" and #state.correctedOrder==6
        and type(state.historicalWrongPours)=="table"
        and type(state.initialBowlDecimals)=="table"
        and type(state.stones)=="table",
        "PATCH 09: eta legacy a pa konplè")
    local order=copySix(state.correctedOrder)
    local seen={}
    for i=1,6 do
        local id=order[i]
        assert(type(id)=="number" and math.type(id)=="integer"
            and id>=1 and id<=6 and not seen[id],
            "PATCH 09: lòd permutation pa valab")
        seen[id]=true
        assert(state.initialBowlDecimals[i]==tostring(B.from(oldBowls[i])),
            "PATCH 09: bòl antre a chanje pandan legacy")
    end
    local p=context.permutationContext
    assert(type(p)=="table" and p.mode=="STAGE_17_PATCH_08"
        and p.status=="PATCH_PERM_RETURNED" and p.commitToken==3
        and type(p.semanticState)=="table"
        and p.semanticState.permutation==table.concat(order,","),
        "PATCH 09: permutation pa otantifye")
    for _,name in ipairs({"w","b","s","m","r"}) do
        assert(state.stones[name]==tostring(B.from(stoneRow[name])),
            "PATCH 09: wòch antre a chanje pandan legacy")
    end
    for position=1,3 do
        assert(state.historicalWrongPours[position]==tostring(B.from(wrong[position])),
            "PATCH 09: tras vide legacy a pa koresponn")
    end
    return order
end

function Patch.execute(drop,index,oldBowls,stoneRow)
    -- Legacy egzekite AVAN correction: pa ranplase apèl sa a.
    local wrong,context=Legacy.execute(drop,index,oldBowls,stoneRow)
    local order=verifyLegacy(context,wrong,drop,index,oldBowls,stoneRow)
    local old={}
    for i=1,6 do old[i]=B.from(context.semanticState.initialBowlDecimals[i]) end
    local stone={}
    for _,name in ipairs({"w","b","s","m","r"}) do
        stone[name]=B.from(context.semanticState.stones[name])
    end
    local dropValue=B.from(drop)
    local manager=Base.MonsterManager.new(context)
    context.phase="PATCH_POUR_BOWL_ORDER"
    context.mode="STAGE_19_PATCH_09"
    context.status="PATCH_POUR_PENDING"

    manager.dispatcher:register("BOWL_ORDER_POUR_PATCH",function(active,owner)
        local square=B.mul(dropValue,dropValue)
        local result,changed={},0
        for position=1,3 do
            local id=order[position]
            local term=B.add(square,B.mul(stone[NON[position]],old[id]))
            term=B.add(term,FAKTOR[position]*index)
            result[position]=Save.savePatch(term)
            if B.compare(result[position],wrong[position])~=0 then
                changed=changed+1
            end
        end
        local state=copyTable(active.semanticState)
        state.source="PATCH_09_POUR_USING_CORRECTED_BOWL_ORDER"
        state.legacyCallPreserved=true
        state.historicalFixedBowlIds={1,2,3}
        state.historicalWrongPours={}
        state.correctedPours={}
        state.usedBowlIds={}
        state.correctedOrder=copySix(order)
        state.fixedBowlIds={1,2,3}
        state.pourDifferences=changed
        state.corrected=true
        for position=1,3 do
            state.historicalWrongPours[position]=tostring(wrong[position])
            state.correctedPours[position]=tostring(result[position])
            state.usedBowlIds[position]=order[position]
        end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("pour.patch.calls")
        owner.metricsManager:bump("pour.patch.legacyCallsPreserved")
        owner.metricsManager:observe("pour.patch.changedPositions",changed)
        owner.metricsManager:observe("pour.patch.order",table.concat(order,","))
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_09_USE_PERMUTED_BOWL_IDS",
            legacyIds={1,2,3},
            correctedIds={order[1],order[2],order[3]},
            changedPositions=changed
        }
        active.status="PATCH_POUR_RETURNED"
        return copyBigints(result,3)
    end)

    local corrected=manager.dispatcher:dispatch(context,"BOWL_ORDER_POUR_PATCH",manager)
    return copyBigints(corrected,3),context
end

return Patch
