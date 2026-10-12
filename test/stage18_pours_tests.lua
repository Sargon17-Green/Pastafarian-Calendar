local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=require("legacy_fixed_pours")
local stone={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local factor={3,5,7}
local name={"w","b","s"}
local function normative(drop,i,order)
    local x=B.from(drop)
    local result={}
    for p=1,3 do
        result[p]=O.SAVE(B.mul(x,x)+B.from(stone[name[p]])*B.from(bowls[order[p]])+B.from(factor[p]*i))
    end
    return result
end
local function comparison(drop,i,expectedWrong)
    local before={}
    for k=1,6 do before[k]=bowls[k] end
    local got,ctx=S.legacyFixedBowlPoursProbe(drop,i,bowls,stone)
    local direct,order,permutationContext=F.legacyPoursToFixedBowlIds(drop,i,bowls,stone)
    local correct=normative(drop,i,order)
    local mismatches=0
    for p=1,3 do
        if B.compare(got[p],correct[p])~=0 then mismatches=mismatches+1 end
        assert(B.compare(got[p],direct[p])==0)
        local raw=O.SAVE(B.from(drop)*B.from(drop)+B.from(stone[name[p]])*B.from(bowls[p])+B.from(factor[p]*i))
        assert(B.compare(got[p],raw)==0,"Fè vide sou lòd olye id fizik")
        assert(ctx.semanticState.usedBowlIds[p]==p)
        assert(ctx.semanticState.historicalWrongPours[p]==tostring(raw))
    end
    assert(mismatches==expectedWrong)
    assert(ctx.mode=="STAGE_18_DISCOVERY_09" and ctx.commitToken==1)
    assert(ctx.status=="LEGACY_FIXED_BOWL_POURS_RETURNED")
    assert(#ctx.branchTrace==1 and ctx.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS")
    assert(ctx.metrics["legacy.fixedPour.calls"]==1)
    assert(ctx.permutationContext.commitToken==3 and permutationContext.commitToken==3)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(#ctx.diagnostics==1 and ctx.diagnostics[1].ignoredPermutation)
    assert(table.concat(ctx.semanticState.correctedOrder,",")==table.concat(order,","))
    for j=1,6 do assert(bowls[j]==before[j]) end
    return got,ctx
end
comparison(1,4,0)
comparison(121,4,2)
comparison(241,4,3)
local first,ctx=comparison(B.add(B.mul(B.from("1"..string.rep("0",80)),720),1),5,0)
-- drop M+1 gives identity rank; no difference is an incidental match.
first[1].d[1]=999
ctx.semanticState.usedBowlIds[1]=999
local again=select(1,comparison(1,4,0))
assert(tostring(again[1])==tostring(O.SAVE(B.from(1)+B.from(20)+B.from(12))))
for _,bad in ipairs({0,47,1.5,"3"}) do
    assert(not pcall(S.legacyFixedBowlPoursProbe,121,bad,bowls,stone))
end
print("PASS Stage 18: fè vide sou id 1,2,3; rank 1 matche, 121 gen 2 erè, 241 gen 3")
