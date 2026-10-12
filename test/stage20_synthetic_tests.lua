local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stones={w=2,b=3,s=5,m=7,r=11}
local inputs={10,20,30,40,50,60}
local stoneNames={"w","b","s","m","r","w"}
local factors={3,5,7}
local function frozenStep(drop,index,bowls)
    local order=O.bowlOrderFromDrop(B.from(drop))
    local old={}
    for id=1,6 do old[id]=B.from(bowls[id]) end
    local pours={}
    for p=1,3 do
        pours[p]=O.SAVE(B.from(drop)*B.from(drop)+B.from(stones[stoneNames[p]])*old[order[p]]+B.from(factors[p]*index))
    end
    local result={}
    for p=1,6 do
        local id=order[p]
        local prev=order[(p+4)%6+1]
        local nextId=order[p%6+1]
        local x=old[id]+B.from(2)*old[prev]+B.from(3)*old[nextId]
              +(p<=3 and pours[p] or B.from(0))+B.from(drop)+B.from(stones[stoneNames[p]])
        result[id]=O.SAVE(x*x+B.from(5)*old[prev]*old[nextId]+B.from(index*p))
    end
    return result,order
end
local cases={{1,1},{2,7},{121,17},{241,33},{720,46},{0,4},{-37,2}}
local changed,firstMatches=0,0
for _,case in ipairs(cases) do
    local drop,index=case[1],case[2]
    local wrong,ctx=S.legacyAliasedStirProbe(drop,index,inputs,stones)
    local norm,order=frozenStep(drop,index,inputs)
    assert(ctx.mode=="STAGE_20_DISCOVERY_10")
    assert(ctx.phase=="LEGACY_ALIASED_BOWL_STIR")
    assert(ctx.status=="LEGACY_STIR_ALIASED_RETURNED" and ctx.commitToken==3)
    assert(ctx.currentHandler=="LEGACY_ALIASED_STIR")
    assert(ctx.previousHandler=="BOWL_ORDER_POUR_PATCH")
    assert(#ctx.branchTrace==3 and ctx.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
        and ctx.branchTrace[2]=="BOWL_ORDER_POUR_PATCH"
        and ctx.branchTrace[3]=="LEGACY_ALIASED_STIR")
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.metrics["legacy.fixedPour.calls"]==1)
    assert(ctx.metrics["pour.patch.calls"]==1 and ctx.metrics["legacy.stir.aliasCalls"]==1)
    assert(#ctx.diagnostics==3 and ctx.diagnostics[3].samePhysicalWorkingTable)
    assert(ctx.semanticState.localAliasing and ctx.semanticState.inputBowlsNotMutated)
    assert(table.concat(ctx.semanticState.correctedOrder,",")==table.concat(order,","))
    local count=0
    for p=1,6 do
        local id=order[p]
        if B.compare(wrong[id],norm[id])~=0 then count=count+1 end
        assert(ctx.semanticState.historicalAliasedBowls[id]==tostring(wrong[id]))
        assert(ctx.semanticState.previousBowls[id]==tostring(inputs[id]))
        assert(inputs[id]==id*10)
    end
    assert(B.compare(wrong[order[1]],norm[order[1]])==0,
        "Premye pozisyon an pa dwe wè okenn update anvan li")
    assert(count>=1,"Aliasing pa vizib pou gout "..drop)
    firstMatches=firstMatches+1
    changed=changed+count
end
assert(firstMatches==#cases and changed>=7)
local returned=select(1,S.legacyAliasedStirProbe(121,17,inputs,stones))
local direct=S.legacyAliasedStirProbe(121,17,inputs,stones)
for id=1,6 do assert(B.compare(returned[id],direct[id])==0) end
assert(select("#",S.aliasedStirSpaghetti(1,1,inputs,stones))==1)
assert(select("#",S.legacyAliasedStirProbe(1,1,inputs,stones))==2)
print("PASS Stage 20 synthetic: 7 lòd, premye pozisyon kòrèk, alias pita diferan")
