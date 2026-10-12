-- DISCOVERY 12: ansyen wout la chwazi vwazen bòl dapre non fiks 1..6.
-- PATCH 11 fini chèn 46 gout yo; lòd gout 46 soti nan PATCH 08.
-- DÈYÈ: pa korije vwazen an, pa fè douz brase final yo, pa fè PATCH 12.
local B=require("bigint")
local Base=require("monster_base")
local Chain=require("bowl_chain_patch")
local Permutation=require("permutation_patch")
local Legacy={}

local function six(values)
    assert(type(values)=="table" and values[7]==nil,"Sis bòl sèlman")
    local out={}
    for id=1,6 do out[id]=B.from(assert(values[id],"Bòl manke")) end
    return out
end
local function copyOrder(values)
    local out={}
    for pos=1,6 do out[pos]=values[pos] end
    return out
end
local function copyData(src,seen)
    if type(src)~="table" then return src end
    seen=seen or {}
    if seen[src] then return seen[src] end
    local dst={}
    seen[src]=dst
    for k,v in pairs(src) do dst[copyData(k,seen)]=copyData(v,seen) end
    return dst
end

-- Erè istorik egzak: non bòl yo konte 1,2,3,4,5,6 siklik,
-- menm lè permutation gout 46 la gen yon lòt lòd.
function Legacy.oldNextBowlFixedName(queriedId)
    assert(type(queriedId)=="number" and math.type(queriedId)=="integer"
        and queriedId>=1 and queriedId<=6,"Id bòl kesyone dwe 1..6")
    return queriedId%6+1
end

local function validateChain(bowls,ctx)
    assert(type(ctx)=="table" and ctx.mode=="STAGE_23_PATCH_11"
        and ctx.status=="PATCH_CHAIN_COMPLETE"
        and ctx.commitToken==2 and #ctx.branchTrace==2
        and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
        and ctx.branchTrace[2]=="BOWL_CHAIN_STATE_PATCH"
        and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
        and type(ctx.semanticState)=="table"
        and ctx.semanticState.source=="PATCH_11_CARRY_PREVIOUS_BOWLS"
        and ctx.semanticState.completedDropCount==46
        and ctx.semanticState.carriedPreviousOutputs==45
        and ctx.semanticState.legacyResetsPreserved==45
        and type(ctx.childContexts)=="table" and #ctx.childContexts==46
        and type(ctx.patchedChildContexts)=="table" and #ctx.patchedChildContexts==46,
        "DISCOVERY 12: 46 gout PATCH 11 pa otantik")
    for id=1,6 do
        assert(ctx.semanticState.lastBowls[id]==tostring(bowls[id]),
            "DISCOVERY 12: bòl final PATCH 11 pa otantik")
    end
    for i=1,46 do
        assert(ctx.patchedChildContexts[i].commitToken==4,
            "DISCOVERY 12: brase PATCH 10 gout "..i.." pa konplè")
    end
end

local function validateOrder(order,ctx,drop46)
    assert(type(ctx)=="table" and ctx.mode=="STAGE_17_PATCH_08"
        and ctx.status=="PATCH_PERM_RETURNED"
        and ctx.commitToken==3 and ctx.pendingSemanticState==nil
        and ctx.rollbackSnapshot==nil
        and #ctx.branchTrace==3
        and ctx.branchTrace[3]=="PERMUTATION_PATCH"
        and ctx.semanticState.permutation==table.concat(order,","),
        "DISCOVERY 12: lòd gout 46 PATCH 08 pa otantik")
    assert(type(order)=="table" and #order==6 and order[7]==nil,
        "DISCOVERY 12: sis id permutation manke")
    local seen={}
    for p=1,6 do
        local id=order[p]
        assert(type(id)=="number" and math.type(id)=="integer"
            and id>=1 and id<=6 and not seen[id],
            "DISCOVERY 12: permutation kout oswa falsifye")
        seen[id]=true
    end
    assert(ctx.semanticState.rankOneBased>=1 and ctx.semanticState.rankOneBased<=720,
        "DISCOVERY 12: rank pa valab")
end

function Legacy.execute(drops,stoneRows,initialBowls,queriedId)
    -- Verifye id avan okenn kalkil long, san chanje defo siklik la.
    Legacy.oldNextBowlFixedName(queriedId)
    assert(type(drops)=="table" and #drops==46 and drops[47]==nil,
        "DISCOVERY 12 mande egzakteman 46 gout")
    assert(type(stoneRows)=="table" and stoneRows[47]==nil,
        "DISCOVERY 12 mande 46 ranje wòch")
    -- Routin Stage 23 natif ak tout 46 gout ap pase reyèlman.
    local bowls,context=Chain.execute(drops,stoneRows,initialBowls)
    bowls=six(bowls)
    validateChain(bowls,context)
    local drop46=B.from(assert(drops[46],"Dènye gout vizib manke"))
    local order,permCtx=Permutation.execute(drop46)
    validateOrder(order,permCtx,drop46)
    context.stage23SemanticState=copyData(context.semanticState)
    context.stage23FinalBowls=six(bowls)
    context.permutationContext=permCtx
    local manager=Base.MonsterManager.new(context)
    context.mode="STAGE_24_DISCOVERY_12"
    context.phase="LEGACY_NEIGHBOR_BY_FIXED_BOWL_NAME"
    context.status="LEGACY_FIXED_NEIGHBOR_PENDING"
    manager.dispatcher:register("LEGACY_FIXED_NAME_NEIGHBOR",function(active,owner)
        local oldNext=Legacy.oldNextBowlFixedName(queriedId)
        local state={
            source="FIXED_BOWL_NAME_CYCLE_IGNORES_DROP46_ORDER",
            queriedId=queriedId,
            selectedNextId=oldNext,
            drop46Decimal=tostring(drop46),
            rank46=permCtx.semanticState.rankOneBased,
            orderAtDrop46=copyOrder(order),
            bowlsAfter46={},
            fixedIdCycle=true,
            permutationIgnoredForNeighbor=true,
            stage23ChainPreserved=true,
            postStirNotExecuted=true,
            completedDropCount=46
        }
        for id=1,6 do state.bowlsAfter46[id]=tostring(bowls[id]) end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.fixedNeighbor.calls")
        owner.metricsManager:bump("legacy.fixedNeighbor.permutationIgnored")
        owner.metricsManager:observe("legacy.fixedNeighbor.rank46",tostring(state.rank46))
        owner.metricsManager:observe("legacy.fixedNeighbor.queriedId",tostring(queriedId))
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_12_FIXED_BOWL_NAME_IGNORES_DROP46_ORDER",
            queriedId=queriedId,selectedNextId=oldNext,
            orderAt46=copyOrder(order),usedFixedNameCycle=true
        }
        active.status="LEGACY_FIXED_NEIGHBOR_COMPLETE"
        return oldNext
    end)
    local wrong=manager.dispatcher:dispatch(context,"LEGACY_FIXED_NAME_NEIGHBOR",manager)
    return wrong,context
end

return Legacy
