-- PATCH 10: refè brase sis bòl yo avèk ansyen snapshot separe.
-- Legacy Stage 20 kouri an premye, ak move alias li a toujou prezan.
local B=require("bigint")
local Base=require("monster_base")
local Save=require("save_patch")
local Legacy=require("legacy_aliased_stir")
local Patch={}

local NAMES={"w","b","s","m","r","w"}
local function copyBowls(source)
    local result={}
    assert(type(source)=="table" and source[7]==nil,"Sis bòl sèlman")
    for id=1,6 do result[id]=B.from(assert(source[id],"Bòl manke")) end
    return result
end
local function copyOrder(source)
    local result={}
    for p=1,6 do result[p]=source[p] end
    return result
end
local function verifyLegacy(wrong,ctx,drop,index,bowls,stones)
    assert(type(ctx)=="table" and ctx.mode=="STAGE_20_DISCOVERY_10"
        and ctx.status=="LEGACY_STIR_ALIASED_RETURNED"
        and ctx.commitToken==3
        and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
        and #ctx.branchTrace==3
        and ctx.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
        and ctx.branchTrace[2]=="BOWL_ORDER_POUR_PATCH"
        and ctx.branchTrace[3]=="LEGACY_ALIASED_STIR",
        "PATCH 10: prèv legacy pa konplè")
    local state=ctx.semanticState
    assert(type(state)=="table" and state.localAliasing==true
        and state.inputBowlsNotMutated==true
        and state.patchedPoursPreserved==true
        and state.source=="OLD_AND_NEXT_BOWLS_SHARE_ONE_LOCAL_TABLE"
        and state.visibleIndex==index and state.dropDecimal==tostring(B.from(drop))
        and type(state.correctedOrder)=="table"
        and type(state.correctedPours)=="table"
        and type(state.previousBowls)=="table"
        and type(state.historicalAliasedBowls)=="table",
        "PATCH 10: eta legacy pa otantik")
    local order={}
    local seen={}
    for p=1,6 do
        local id=state.correctedOrder[p]
        assert(type(id)=="number" and math.type(id)=="integer"
            and id>=1 and id<=6 and not seen[id],
            "PATCH 10: lòd sis bòl pa valab")
        seen[id]=true
        order[p]=id
    end
    assert(type(ctx.permutationContext)=="table"
       and ctx.permutationContext.mode=="STAGE_17_PATCH_08"
       and ctx.permutationContext.commitToken==3
       and ctx.permutationContext.semanticState.permutation==table.concat(order,","),
       "PATCH 10: rank bòl pa otantifye")
    for id=1,6 do
        assert(state.previousBowls[id]==tostring(B.from(bowls[id]))
            and state.historicalAliasedBowls[id]==tostring(B.from(wrong[id])),
            "PATCH 10: kontni bòl legacy a pa menm ak prèv li")
    end
    for _,name in ipairs({"w","b","s","m","r"}) do B.from(assert(stones[name],"Wòch manke")) end
    for p=1,3 do B.from(assert(state.correctedPours[p],"Vide manke")) end
    assert(type(ctx.diagnostics)=="table" and #ctx.diagnostics==3
       and ctx.diagnostics[3].code=="DISCOVERY_10_OLD_BOWLS_ALIAS_NEXT"
       and ctx.diagnostics[3].samePhysicalWorkingTable==true,
       "PATCH 10: siyati dyagnostik alias la manke")
    return order
end

-- De tablo ki pa pataje okenn idantite oswa BigInt mutable.
-- Nou li TOUJOU old; okenn ekriti nan nextBowls pa janm tounen nan old.
function Patch.snapshotStir(drop,index,bowls,stones,order,pours)
    assert(type(index)=="number" and math.type(index)=="integer"
       and index>=1 and index<=46,"Endis gout dwe 1..46")
    local old=copyBowls(bowls)
    local nextBowls={}
    local value=B.from(drop)
    local rock={}
    for _,name in ipairs({"w","b","s","m","r"}) do rock[name]=B.from(stones[name]) end
    local usePours={}
    for p=1,3 do usePours[p]=B.from(pours[p]) end
    for p=4,6 do usePours[p]=B.from(0) end
    for p=1,6 do
        local id=order[p]
        local prev=order[(p+4)%6+1]
        local nxt=order[p%6+1]
        local sum=B.add(old[id],B.mulSmall(old[prev],2))
        sum=B.add(sum,B.mulSmall(old[nxt],3))
        sum=B.add(sum,usePours[p])
        sum=B.add(sum,value)
        sum=B.add(sum,rock[NAMES[p]])
        local result=B.mul(sum,sum)
        result=B.add(result,B.mulSmall(B.mul(old[prev],old[nxt]),5))
        result=B.add(result,index*p)
        nextBowls[id]=Save.savePatch(result)
    end
    return copyBowls(nextBowls)
end

function Patch.execute(drop,index,bowls,stones)
    -- Egzekisyon otantik ki gen defo: pa ekri nan modil legacy a.
    local wrong,context=Legacy.execute(drop,index,bowls,stones)
    local order=verifyLegacy(wrong,context,drop,index,bowls,stones)
    -- Eta piblik la pa gen okenn alias ak snapshot istorik la.
    local original={}
    for id=1,6 do original[id]=B.from(context.semanticState.previousBowls[id]) end
    local rock={}
    for _,name in ipairs({"w","b","s","m","r"}) do rock[name]=B.from(stones[name]) end
    local pours={}
    for p=1,3 do pours[p]=B.from(context.semanticState.correctedPours[p]) end
    local manager=Base.MonsterManager.new(context)
    context.phase="PATCH_SNAPSHOT_BOWL_STIR"
    context.mode="STAGE_21_PATCH_10"
    context.status="PATCH_STIR_PENDING"

    manager.dispatcher:register("STIR_SNAPSHOT_PATCH",function(active,owner)
        local corrected=Patch.snapshotStir(drop,index,original,rock,order,pours)
        local differences=0
        local state={
            source="PATCH_10_FROZEN_SIX_BOWL_SNAPSHOT",
            visibleIndex=index,
            dropDecimal=tostring(B.from(drop)),
            correctedOrder=copyOrder(order),
            correctedPours={},
            previousBowls={},
            historicalAliasedBowls={},
            correctedBowls={},
            legacyCallPreserved=true,
            aliasSeparated=true,
            historicalAliasingPreserved=true
        }
        for p=1,3 do state.correctedPours[p]=tostring(pours[p]) end
        for id=1,6 do
            state.previousBowls[id]=tostring(original[id])
            state.historicalAliasedBowls[id]=tostring(wrong[id])
            state.correctedBowls[id]=tostring(corrected[id])
            if B.compare(corrected[id],wrong[id])~=0 then differences=differences+1 end
        end
        state.changedBowlIds=differences
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("stir.patch.calls")
        owner.metricsManager:bump("stir.patch.legacyCallsPreserved")
        owner.metricsManager:observe("stir.patch.changedBowlIds",differences)
        owner.metricsManager:observe("stir.patch.order",table.concat(order,","))
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_10_SPLIT_OLD_AND_NEXT_BOWLS",
            legacySameTable=true,
            correctedDistinctTables=true,
            changes=differences,
            permutation=copyOrder(order)
        }
        active.status="PATCH_STIR_RETURNED"
        return copyBowls(corrected)
    end)
    local answer=manager.dispatcher:dispatch(context,"STIR_SNAPSHOT_PATCH",manager)
    return copyBowls(answer),context
end

return Patch
