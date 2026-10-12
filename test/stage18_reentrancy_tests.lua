local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Permutation=require("permutation_patch")
local oldPerm=Permutation.execute
local oldMul=B.mul
local stone={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local nested,outer=0,0
local function check(pours,ctx)
    assert(#pours==3 and ctx.commitToken==1)
    assert(ctx.mode=="STAGE_18_DISCOVERY_09")
    assert(ctx.metrics["legacy.fixedPour.calls"]==1)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
end
for _,drop in ipairs({1,121,241,720}) do
    local guard=false
    local captured
    Permutation.execute=function(...)
        if not guard then
            guard=true
            local p,c=S.legacyFixedBowlPoursProbe(121,4,bowls,stone)
            captured={p,c}
            guard=false
        end
        return oldPerm(...)
    end
    local ok,p,c=pcall(S.legacyFixedBowlPoursProbe,drop,4,bowls,stone)
    Permutation.execute=oldPerm
    assert(ok and captured,"Reentrance permutation pa pase")
    check(p,c);check(captured[1],captured[2])
    captured[2].semanticState.usedBowlIds[1]=99
    assert(c.semanticState.usedBowlIds[1]==1)
    nested=nested+1;outer=outer+1
end
for _,drop in ipairs({1,121,241,720}) do
    local guard=false
    local captured
    B.mul=function(...)
        if not guard then
            guard=true
            local p,c=S.legacyFixedBowlPoursProbe(241,4,bowls,stone)
            captured={p,c}
            guard=false
        end
        return oldMul(...)
    end
    local ok,p,c=pcall(S.legacyFixedBowlPoursProbe,drop,4,bowls,stone)
    B.mul=oldMul
    assert(ok and captured,"Reentrance pandan miltiplikasyon pa pase")
    check(p,c);check(captured[1],captured[2])
    captured[1][1].d[1]=123456
    assert(tostring(p[1])~="123456")
    nested=nested+1;outer=outer+1
end
assert(Permutation.execute==oldPerm and B.mul==oldMul)
assert(nested==8 and outer==8)
print("PASS Stage 18 reentrance: 8 nested, 8 outer, kontèks endepandan")
