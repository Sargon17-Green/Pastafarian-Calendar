-- PATCH 12: vwazen bòl la swiv lòd permutation gout 46 la, pa non id fiks.
-- Premye twa commit yo soti nan vrè DISCOVERY 12; legacy rete entak.
-- San douz brase final yo, latch, selection, oswa PATCH 13.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_fixed_neighbor")
local LegacyPermutation=require("legacy_permutation")
local Patch={}

local function clone(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}
    if seen[value] then return seen[value] end
    local copy={}
    seen[value]=copy
    for k,v in pairs(value) do copy[clone(k,seen)]=clone(v,seen) end
    return copy
end

local function checkId(id)
    assert(type(id)=="number" and math.type(id)=="integer"
        and id>=1 and id<=6,"PATCH 12: id bòl dwe antye 1..6")
end

local function verifiedOrder(order)
    assert(type(order)=="table" and #order==6 and order[7]==nil,
        "PATCH 12: sis pozisyon permutation obligatwa")
    local visited={}
    local snapshot={}
    for position=1,6 do
        local id=order[position]
        assert(type(id)=="number" and math.type(id)=="integer"
            and id>=1 and id<=6 and not visited[id],
            "PATCH 12: id permutation yo dwe sis id inik 1..6")
        visited[id]=true
        snapshot[position]=id
    end
    return snapshot
end

-- Fonksyon nwayo a gen sis pozisyon fizik, epi yo pran vwazen siklik
-- ki vini APRE pozisyon id kesyone nan permutation gout 46 la.
function Patch.nextInOrder(order,queriedId)
    checkId(queriedId)
    local snapshot=verifiedOrder(order)
    local position
    for i=1,6 do
        if snapshot[i]==queriedId then position=i;break end
    end
    assert(position,"PATCH 12: id mande a pa nan permutation")
    return snapshot[(position%6)+1],position
end

local function checkLegacy(wrong,ctx,drops,queriedId)
    assert(type(ctx)=="table"
        and ctx.mode=="STAGE_24_DISCOVERY_12"
        and ctx.status=="LEGACY_FIXED_NEIGHBOR_COMPLETE"
        and ctx.phase=="LEGACY_NEIGHBOR_BY_FIXED_BOWL_NAME"
        and ctx.commitToken==3 and #ctx.branchTrace==3
        and ctx.currentHandler=="LEGACY_FIXED_NAME_NEIGHBOR"
        and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
        and ctx.branchTrace[2]=="BOWL_CHAIN_STATE_PATCH"
        and ctx.branchTrace[3]=="LEGACY_FIXED_NAME_NEIGHBOR"
        and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
        "PATCH 12: tras DISCOVERY 12 pa konplè")
    local state=ctx.semanticState
    assert(type(state)=="table"
        and state.source=="FIXED_BOWL_NAME_CYCLE_IGNORES_DROP46_ORDER"
        and state.fixedIdCycle==true
        and state.permutationIgnoredForNeighbor==true
        and state.stage23ChainPreserved==true
        and state.postStirNotExecuted==true
        and state.completedDropCount==46
        and state.queriedId==queriedId
        and state.selectedNextId==Legacy.oldNextBowlFixedName(queriedId)
        and wrong==state.selectedNextId
        and state.drop46Decimal==tostring(B.from(drops[46]))
        and type(state.bowlsAfter46)=="table",
        "PATCH 12: prèv chwa fiks istorik pa otantik")
    assert(type(ctx.metrics)=="table"
        and ctx.metrics["legacy.fixedNeighbor.calls"]==1
        and ctx.metrics["legacy.fixedNeighbor.permutationIgnored"]==1
        and type(ctx.diagnostics)=="table" and #ctx.diagnostics==3
        and ctx.diagnostics[3].code=="DISCOVERY_12_FIXED_BOWL_NAME_IGNORES_DROP46_ORDER"
        and ctx.diagnostics[3].queriedId==queriedId
        and ctx.diagnostics[3].selectedNextId==wrong,
        "PATCH 12: prèv metrik/dyagnostik istorik pa valab")
    local child=ctx.permutationContext
    local rank=LegacyPermutation.oldOneBasedRank(B.from(drops[46]))
    assert(type(child)=="table"
        and child.mode=="STAGE_17_PATCH_08"
        and child.status=="PATCH_PERM_RETURNED"
        and child.commitToken==3 and #child.branchTrace==3
        and child.branchTrace[3]=="PERMUTATION_PATCH"
        and child.pendingSemanticState==nil
        and child.rollbackSnapshot==nil
        and type(child.semanticState)=="table"
        and child.semanticState.source=="PATCH_08_ONE_BASED_TO_ZERO_BASED"
        and child.semanticState.rankOneBased==rank
        and child.semanticState.rankZeroBased==rank-1
        and child.semanticState.permutation==table.concat(state.orderAtDrop46,",")
        and state.rank46==rank,
        "PATCH 12: lòd gout 46 PATCH 08 pa otantik")
    local actual=verifiedOrder(state.orderAtDrop46)
    local reference=LegacyPermutation.oldPermutationUnrank0(rank-1)
    for position=1,6 do
        assert(actual[position]==reference[position],
            "PATCH 12: lòd gout 46 falsifye nan pozisyon "..position)
    end
    assert(type(ctx.stage23SemanticState)=="table"
        and ctx.stage23SemanticState.source=="PATCH_11_CARRY_PREVIOUS_BOWLS"
        and ctx.stage23SemanticState.completedDropCount==46
        and ctx.stage23SemanticState.carriedPreviousOutputs==45
        and type(ctx.stage23FinalBowls)=="table"
        and #ctx.childContexts==46
        and #ctx.patchedChildContexts==46,
        "PATCH 12: chèn 46 gout PATCH 11 pa otantik")
    for id=1,6 do
        assert(state.bowlsAfter46[id]==ctx.stage23SemanticState.lastBowls[id]
            and state.bowlsAfter46[id]==tostring(ctx.stage23FinalBowls[id]),
            "PATCH 12: eta sis bòl pa otantik")
    end
    return actual,rank
end

function Patch.execute(drops,stoneRows,initialBowls,queriedId)
    checkId(queriedId)
    local wrong,ctx=Legacy.execute(drops,stoneRows,initialBowls,queriedId)
    local order,rank=checkLegacy(wrong,ctx,drops,queriedId)
    ctx.legacyNeighborSemanticState=clone(ctx.semanticState)
    ctx.legacyNeighborSelectedId=wrong
    local manager=Base.MonsterManager.new(ctx)
    ctx.mode="STAGE_25_PATCH_12"
    ctx.phase="PATCH_NEIGHBOR_FROM_DROP46_ORDER"
    ctx.status="PATCH_NEIGHBOR_PENDING"
    manager.dispatcher:register("DROP46_NEIGHBOR_ORDER_PATCH",function(active,owner)
        -- Egzekite menm nwayo nan lòd PATCH 08 valide a.
        local nextId,position=Patch.nextInOrder(order,queriedId)
        local state={
            source="PATCH_12_USE_DROP46_ORDER_NEIGHBOR",
            queriedId=queriedId,
            selectedNextId=nextId,
            positionInDrop46Order=position,
            orderAtDrop46=clone(order),
            drop46Decimal=tostring(B.from(drops[46])),
            rank46=rank,
            legacySelectedNextId=wrong,
            legacyCallPreserved=true,
            previousCommitCount=3,
            completedDropCount=46,
            carriedPreviousOutputs=45,
            postStirNotExecuted=true,
            nextIdFollowsPermutation=true,
            bowlsAfter46=clone(ctx.legacyNeighborSemanticState.bowlsAfter46)
        }
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("neighbor.patch.calls")
        owner.metricsManager:bump("neighbor.patch.legacyCallsPreserved")
        owner.metricsManager:observe("neighbor.patch.rank46",tostring(rank))
        owner.metricsManager:observe("neighbor.patch.position",tostring(position))
        owner.metricsManager:observe("neighbor.patch.correctedId",tostring(nextId))
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_12_NEXT_BOWL_IN_DROP46_ORDER",
            legacySelectedNextId=wrong,correctedSelectedNextId=nextId,
            queriedId=queriedId,position=position,orderAt46=clone(order)
        }
        active.status="PATCH_NEIGHBOR_COMPLETE"
        return nextId
    end)
    local corrected=manager.dispatcher:dispatch(ctx,"DROP46_NEIGHBOR_ORDER_PATCH",manager)
    return corrected,ctx
end

return Patch
