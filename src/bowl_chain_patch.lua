-- PATCH 11: pase sis bòl korije yo soti nan yon gout pou pwochen an.
-- Chemen DISCOVERY 11 la kouri AVAN patch sa a; nou pa efase reset istorik la.
-- Pa genyen okenn douz brase final, selection, ni kouch Stage 24.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_reset_chain")
local Stir=require("stir_patch")
local Patch={}

local function six(source)
    assert(type(source)=="table" and source[7]==nil,"Sis bòl nesesè")
    local out={}
    for id=1,6 do out[id]=B.from(assert(source[id],"Bòl manke")) end
    return out
end
local function stones(source)
    assert(type(source)=="table","Wòch yo manke")
    local out={}
    for _,name in ipairs({"w","b","s","m","r"}) do
        out[name]=B.from(assert(source[name],"Wòch "..name.." manke"))
    end
    return out
end
local function copiedData(source,seen)
    if type(source)~="table" then return source end
    seen=seen or {}
    if seen[source] then return seen[source] end
    local out={}
    seen[source]=out
    for k,v in pairs(source) do out[copiedData(k,seen)]=copiedData(v,seen) end
    return out
end
local function snapshotInputs(drops,rows,initial)
    assert(type(drops)=="table" and type(rows)=="table"
        and #drops>=1 and #drops<=46,"Lis gout dwe gen 1..46 antre")
    assert(drops[#drops+1]==nil and rows[#drops+1]==nil,"Lis gout oswa wòch gen twòp antre")
    local values,rocks={},{}
    for i=1,#drops do
        values[i]=B.from(assert(drops[i],"Gout manke"))
        rocks[i]=stones(assert(rows[i],"Ranje wòch manke"))
    end
    return values,rocks,six(initial)
end
local function verifyStage21(child,i,drop,input,output)
    assert(type(child)=="table"
        and child.mode=="STAGE_21_PATCH_10"
        and child.status=="PATCH_STIR_RETURNED"
        and child.commitToken==4 and #child.branchTrace==4
        and child.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
        and child.branchTrace[2]=="BOWL_ORDER_POUR_PATCH"
        and child.branchTrace[3]=="LEGACY_ALIASED_STIR"
        and child.branchTrace[4]=="STIR_SNAPSHOT_PATCH"
        and child.pendingSemanticState==nil and child.rollbackSnapshot==nil,
        "PATCH 11: tras PATCH 10 pa otantik pou gout "..i)
    local state=child.semanticState
    assert(type(state)=="table" and state.aliasSeparated==true
        and state.source=="PATCH_10_FROZEN_SIX_BOWL_SNAPSHOT"
        and state.visibleIndex==i and state.dropDecimal==tostring(drop)
        and type(state.previousBowls)=="table"
        and type(state.correctedBowls)=="table",
        "PATCH 11: eta PATCH 10 pa otantik")
    for id=1,6 do
        assert(state.previousBowls[id]==tostring(input[id])
            and state.correctedBowls[id]==tostring(output[id]),
            "PATCH 11: bòl PATCH 10 la pa otantifye "..i..":"..id)
    end
end
local function verifyLegacy(wrong,ctx,values,rocks,initial)
    assert(type(ctx)=="table"
        and ctx.mode=="STAGE_22_DISCOVERY_11"
        and ctx.status=="LEGACY_RESET_COMPLETE"
        and ctx.commitToken==1
        and ctx.currentHandler=="LEGACY_BOWL_STATE_RESET"
        and #ctx.branchTrace==1
        and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
        and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
        and type(ctx.diagnostics)=="table" and #ctx.diagnostics==1
        and ctx.diagnostics[1].code=="DISCOVERY_11_DROP_CHAIN_DISCARDS_UPDATED_BOWLS"
        and ctx.diagnostics[1].resets==#values-1
        and ctx.metrics["legacy.reset.calls"]==1,
        "PATCH 11: prèv DISCOVERY 11 pa konplè")
    local state=ctx.semanticState
    assert(type(state)=="table"
        and state.source=="INITIAL_BOWLS_REUSED_AT_EVERY_VISIBLE_DROP"
        and state.completedDropCount==#values
        and state.ignoredPreviousOutputs==#values-1
        and type(state.perDrop)=="table" and #ctx.childContexts==#values,
        "PATCH 11: reset istorik pa otantifye")
    for id=1,6 do
        assert(state.firstInitialBowls[id]==tostring(initial[id])
            and state.lastBowls[id]==tostring(wrong[id])
            and state.perDrop[#values].outputBowls[id]==tostring(wrong[id]),
            "PATCH 11: rezilta legacy pa matche tras li")
    end
    for i=1,#values do
        local item=assert(state.perDrop[i],"Tras gout legacy manke")
        assert(item.index==i
            and item.dropDecimal==tostring(values[i])
            and item.restartedFromInitial==true
            and item.priorOutputIgnored==(i>1)
            and item.childCommits==4,
            "PATCH 11: gout legacy pa otantik")
        local input,output={},{}
        for id=1,6 do
            assert(item.inputBowls[id]==tostring(initial[id]),
                "PATCH 11: reset legacy a pa pwouve")
            input[id]=B.from(item.inputBowls[id])
            output[id]=B.from(item.outputBowls[id])
            if i>1 then
                assert(item.previousDropOutput[id]==state.perDrop[i-1].outputBowls[id],
                    "PATCH 11: tras eta ki te inyore a pa koeran")
            end
        end
        verifyStage21(ctx.childContexts[i],i,values[i],input,output)
    end
end

function Patch.execute(drops,stoneRows,initialBowls)
    -- Kouri egzakteman menm chèn istorik Stage 22 la, anvan PATCH 11.
    local wrong,ctx=Legacy.execute(drops,stoneRows,initialBowls)
    local values,rocks,original=snapshotInputs(drops,stoneRows,initialBowls)
    verifyLegacy(wrong,ctx,values,rocks,original)
    ctx.legacySemanticState=copiedData(ctx.semanticState)
    ctx.legacyLastBowls=six(wrong)
    ctx.patchedChildContexts={}
    local manager=Base.MonsterManager.new(ctx)
    ctx.mode="STAGE_23_PATCH_11"
    ctx.phase="PATCH_CARRY_BOWLS_BETWEEN_DROPS"
    ctx.status="PATCH_CHAIN_PENDING"
    manager.dispatcher:register("BOWL_CHAIN_STATE_PATCH",function(active,owner)
        local current=six(original)
        local entries={}
        local changed=0
        for i=1,#values do
            local before=six(current)
            -- Operasyon Stage 21 natif; rezilta sa a se input gout i+1.
            local corrected,child=Stir.execute(values[i],i,before,rocks[i])
            verifyStage21(child,i,values[i],before,corrected)
            local after=six(corrected)
            local item={
                index=i,
                dropDecimal=tostring(values[i]),
                inputBowls={},outputBowls={},
                sourceIsInitial=i==1,
                previousDropCarried=i>1,
                previousChildCommits=4
            }
            for id=1,6 do
                if i>1 then
                    assert(tostring(before[id])==entries[i-1].outputBowls[id],
                        "PATCH 11: eta gout anvan an pa t pase")
                end
                item.inputBowls[id]=tostring(before[id])
                item.outputBowls[id]=tostring(after[id])
            end
            entries[i]=item
            active.patchedChildContexts[i]=child
            current=after
        end
        local state={
            source="PATCH_11_CARRY_PREVIOUS_BOWLS",
            firstInitialBowls={},
            lastBowls={},
            legacyLastBowls={},
            completedDropCount=#values,
            legacyResetsPreserved=#values-1,
            carriedPreviousOutputs=#values-1,
            legacyCallPreserved=true,
            legacySource="INITIAL_BOWLS_REUSED_AT_EVERY_VISIBLE_DROP",
            perDrop=entries
        }
        for id=1,6 do
            state.firstInitialBowls[id]=tostring(original[id])
            state.lastBowls[id]=tostring(current[id])
            state.legacyLastBowls[id]=tostring(wrong[id])
            if B.compare(current[id],wrong[id])~=0 then changed=changed+1 end
        end
        state.changedBowlIds=changed
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("bowl.chain.patch.calls")
        owner.metricsManager:bump("bowl.chain.patch.legacyCallsPreserved")
        owner.metricsManager:observe("bowl.chain.patch.dropCount",#values)
        owner.metricsManager:observe("bowl.chain.patch.changedBowlIds",changed)
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_11_PASS_UPDATED_BOWLS_TO_NEXT_DROP",
            legacyResetsPreserved=#values-1,
            carriedStates=#values-1,
            patch10Calls=#values,
            changedBowlIds=changed
        }
        active.status="PATCH_CHAIN_COMPLETE"
        return six(current)
    end)
    local result=manager.dispatcher:dispatch(ctx,"BOWL_CHAIN_STATE_PATCH",manager)
    return six(result),ctx
end

return Patch
