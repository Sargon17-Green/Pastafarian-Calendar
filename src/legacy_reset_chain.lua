-- DISCOVERY 11: chak gout rdemare brase sis bòl nan eta inisyal la.
-- PATCH 10 fèt reyèlman nan chak gout; defo a se kontinwite ANT gout yo.
-- Pa fè koreksyon Stage 23 ni douz brase final yo.
local B=require("bigint")
local Base=require("monster_base")
local StirPatch=require("stir_patch")
local Reset={}

local function copySix(values)
    assert(type(values)=="table" and values[7]==nil,"Egzakteman sis bòl")
    local result={}
    for id=1,6 do
        result[id]=B.from(assert(values[id],"Bòl inisyal manke"))
    end
    return result
end

local function stoneSnapshot(stones)
    assert(type(stones)=="table","Tablo wòch manke")
    local result={}
    for _,name in ipairs({"w","b","s","m","r"}) do
        result[name]=B.from(assert(stones[name],"Wòch "..name.." manke"))
    end
    return result
end

local function verifyInputs(drops,stoneRows,initialBowls)
    assert(type(drops)=="table" and type(stoneRows)=="table",
           "Lis gout ak wòch nesesè")
    assert(#drops>=1 and #drops<=46 and drops[#drops+1]==nil,
           "Nimewo gout dwe 1..46")
    assert(stoneRows[#drops+1]==nil,"Ranje wòch anplis")
    local initial=copySix(initialBowls)
    local values,rocks={},{}
    for i=1,#drops do
        values[i]=B.from(assert(drops[i],"Gout vizib manke"))
        rocks[i]=stoneSnapshot(assert(stoneRows[i],"Ranje wòch manke"))
    end
    return initial,values,rocks
end

-- Konpayi defo a PA itilize bowls ki sòti nan gout i-1.
-- Okontrè, chak apèl se PATCH 10 otantik epi li jwenn menm snapshot
-- inisyal la; sa pwouve erè kontinwite a san depann sou alias Stage 20.
function Reset.legacyResetEachDrop(drops,stoneRows,initialBowls)
    local original,values,rocks=verifyInputs(drops,stoneRows,initialBowls)
    local context=Base.MonsterContext.new(#values,#values)
    context.mode="STAGE_22_DISCOVERY_11"
    context.phase="LEGACY_RESET_BOWLS_FOR_EACH_DROP"
    context.status="LEGACY_RESET_PENDING"
    context.childContexts={}
    local manager=Base.MonsterManager.new(context)
    manager.dispatcher:register("LEGACY_BOWL_STATE_RESET",function(active,owner)
        local previousOutput=nil
        local rows={}
        local latest
        for i=1,#values do
            -- Bug: 'original' is used again even when previousOutput exists.
            local restartedFrom=copySix(original)
            local nextBowls,child=StirPatch.execute(
                values[i],i,restartedFrom,rocks[i])
            assert(child.mode=="STAGE_21_PATCH_10"
               and child.status=="PATCH_STIR_RETURNED"
               and child.commitToken==4
               and #child.branchTrace==4
               and child.pendingSemanticState==nil
               and child.rollbackSnapshot==nil,
               "PATCH 10 pa otantik pou gout "..i)
            local item={
                index=i,
                dropDecimal=tostring(values[i]),
                restartedFromInitial=true,
                inputBowls={},
                previousDropOutput={},
                outputBowls={},
                priorOutputIgnored=previousOutput~=nil,
                childCommits=child.commitToken
            }
            for id=1,6 do
                item.inputBowls[id]=tostring(restartedFrom[id])
                item.previousDropOutput[id]=previousOutput and tostring(previousOutput[id]) or nil
                item.outputBowls[id]=tostring(nextBowls[id])
            end
            rows[i]=item
            active.childContexts[i]=child
            previousOutput=copySix(nextBowls)
            latest=copySix(nextBowls)
        end
        local state={
            source="INITIAL_BOWLS_REUSED_AT_EVERY_VISIBLE_DROP",
            usedFirstDropIndex=1,
            completedDropCount=#values,
            ignoredPreviousOutputs=#values-1,
            firstInitialBowls={},
            perDrop=rows,
            lastBowls={}
        }
        for id=1,6 do
            state.firstInitialBowls[id]=tostring(original[id])
            state.lastBowls[id]=tostring(latest[id])
        end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.reset.calls")
        owner.metricsManager:observe("legacy.reset.dropCount",#values)
        owner.metricsManager:observe("legacy.reset.ignoredPriorStates",#values-1)
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_11_DROP_CHAIN_DISCARDS_UPDATED_BOWLS",
            childPatch10Calls=#values,
            resets=#values-1,
            correctedPerDropStir=true,
            carriedState=false
        }
        active.status="LEGACY_RESET_COMPLETE"
        return copySix(latest)
    end)
    local last=manager.dispatcher:dispatch(context,"LEGACY_BOWL_STATE_RESET",manager)
    return copySix(last),context
end
Reset.execute=Reset.legacyResetEachDrop
return Reset
