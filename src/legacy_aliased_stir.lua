-- DISCOVERY 10: sis bòl yo brase ak yon alias fizik.
-- Gout ak vide yo soti nan PATCH 09; etap sa a PA fè PATCH 10.
local B=require("bigint")
local Base=require("monster_base")
local Save=require("save_patch")
local Pour=require("pour_patch")
local Stir={}

local STONE_NAMES={"w","b","s","m","r","w"}

local function copyBowls(values)
    local out={}
    assert(type(values)=="table" and values[7]==nil,"Sis bòl sèlman")
    for id=1,6 do out[id]=B.from(assert(values[id],"Bòl ki manke")) end
    return out
end

local function copyOrder(order)
    local out={}
    for position=1,6 do out[position]=order[position] end
    return out
end

local function verifyPour(pours,context,drop,index,bowls,stones)
    assert(type(pours)=="table" and #pours==3,
           "Twa vide PATCH 09 yo manke")
    assert(type(context)=="table" and context.mode=="STAGE_19_PATCH_09"
       and context.status=="PATCH_POUR_RETURNED"
       and context.commitToken==2 and context.pendingSemanticState==nil
       and context.rollbackSnapshot==nil and #context.branchTrace==2,
       "Tras PATCH 09 la pa konplè")
    assert(context.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
       and context.branchTrace[2]=="BOWL_ORDER_POUR_PATCH"
       and context.semanticState.source=="PATCH_09_POUR_USING_CORRECTED_BOWL_ORDER"
       and context.semanticState.visibleIndex==index
       and context.semanticState.dropDecimal==tostring(B.from(drop)),
       "Tras autentik PATCH 09 la pa dakò")
    local state=context.semanticState
    local order=copyOrder(state.correctedOrder)
    local seen={}
    for position=1,6 do
        local id=order[position]
        assert(type(id)=="number" and math.type(id)=="integer"
            and id>=1 and id<=6 and not seen[id],
            "Lòd sis bòl yo pa valab")
        seen[id]=true
        assert(state.initialBowlDecimals[position]==tostring(B.from(bowls[position])),
            "Bòl yo te modifye pandan apèl vide a")
    end
    assert(type(context.permutationContext)=="table"
        and context.permutationContext.mode=="STAGE_17_PATCH_08"
        and context.permutationContext.commitToken==3
        and context.permutationContext.semanticState.permutation==table.concat(order,","),
        "Lòd patch la pa otantifye")
    for _,name in ipairs({"w","b","s","m","r"}) do
        assert(state.stones[name]==tostring(B.from(stones[name])),
            "Wòch yo te modifye pandan apèl vide a")
    end
    for position=1,3 do
        assert(state.correctedPours[position]==tostring(B.from(pours[position]))
            and state.usedBowlIds[position]==order[position],
            "Vide koreksyon yo pa otantifye")
    end
    return order
end

local function copyStones(stones)
    local out={}
    for _,name in ipairs({"w","b","s","m","r"}) do
        out[name]=B.from(assert(stones[name],"Wòch ki manke"))
    end
    return out
end

-- DANGER ENTANSYONÈL: old ak nextBowls se MENM tab lokal la.
-- Nou pwoteje tablo moun k ap rele a, men nou pa pwoteje sis lekti
-- siksesif yo kont ekriti anvan yo.
function Stir.oldStirWithAlias(drop,index,bowls,stones,order,pours)
    assert(type(index)=="number" and math.type(index)=="integer"
       and index>=1 and index<=46,"Endis gout vizib la dwe 1..46")
    local working=copyBowls(bowls)
    local old=working
    local nextBowls=working
    local x=B.from(drop)
    local rock=copyStones(stones)
    local usedPours={}
    for position=1,6 do usedPours[position]=position<=3 and B.from(pours[position]) or B.from(0) end
    for position=1,6 do
        local id=order[position]
        local prev=order[(position+4)%6+1]
        local nxt=order[position%6+1]
        local s=B.add(old[id],B.mulSmall(old[prev],2))
        s=B.add(s,B.mulSmall(old[nxt],3))
        s=B.add(s,usedPours[position])
        s=B.add(s,x)
        s=B.add(s,rock[STONE_NAMES[position]])
        local v=B.mul(s,s)
        v=B.add(v,B.mulSmall(B.mul(old[prev],old[nxt]),5))
        v=B.add(v,index*position)
        nextBowls[id]=Save.savePatch(v)
    end
    return copyBowls(nextBowls)
end

function Stir.execute(drop,index,bowls,stones)
    local before=copyBowls(bowls)
    local rock=copyStones(stones)
    -- PATCH 09 kouri reyèlman, anvan nou kreye move alias sa a.
    local pours,context=Pour.execute(drop,index,bowls,stones)
    local order=verifyPour(pours,context,drop,index,bowls,stones)
    local manager=Base.MonsterManager.new(context)
    context.phase="LEGACY_ALIASED_BOWL_STIR"
    context.mode="STAGE_20_DISCOVERY_10"
    context.status="LEGACY_STIR_PENDING"
    manager.dispatcher:register("LEGACY_ALIASED_STIR",function(active,owner)
        local result=Stir.oldStirWithAlias(drop,index,before,rock,order,pours)
        local state={
            source="OLD_AND_NEXT_BOWLS_SHARE_ONE_LOCAL_TABLE",
            visibleIndex=index,
            dropDecimal=tostring(B.from(drop)),
            correctedOrder=copyOrder(order),
            correctedPours={},
            previousBowls={},
            historicalAliasedBowls={},
            localAliasing=true,
            inputBowlsNotMutated=true,
            patchedPoursPreserved=true
        }
        for p=1,3 do state.correctedPours[p]=tostring(pours[p]) end
        for id=1,6 do
            state.previousBowls[id]=tostring(before[id])
            state.historicalAliasedBowls[id]=tostring(result[id])
        end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.stir.aliasCalls")
        owner.metricsManager:bump("legacy.stir.aliasedUpdates")
        owner.metricsManager:observe("legacy.stir.visibleIndex",tostring(index))
        owner.metricsManager:observe("legacy.stir.permutation",table.concat(order,","))
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_10_OLD_BOWLS_ALIAS_NEXT",
            samePhysicalWorkingTable=true,
            updatedInPlace=true,
            order=copyOrder(order)
        }
        active.status="LEGACY_STIR_ALIASED_RETURNED"
        return copyBowls(result)
    end)
    local result=manager.dispatcher:dispatch(context,"LEGACY_ALIASED_STIR",manager)
    return copyBowls(result),context
end

return Stir
