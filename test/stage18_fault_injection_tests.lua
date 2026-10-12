local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Permutation=require("permutation_patch")
local Save=require("save_patch")
local stone={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local savedPerm=Permutation.execute
local savedSave=Save.savePatch
local savedMul=B.mul
local failures,recoveries=0,0

local function recovery()
    local out,ctx=S.legacyFixedBowlPoursProbe(121,4,bowls,stone)
    assert(ctx.mode=="STAGE_18_DISCOVERY_09" and ctx.commitToken==1)
    assert(ctx.metrics["legacy.fixedPour.calls"]==1)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.permutationContext.commitToken==3)
    assert(#out==3)
    recoveries=recoveries+1
end

for i=1,4 do
    local mark="FAIL_PATCH08_"..i
    Permutation.execute=function() error(mark,0) end
    local ok,err=pcall(S.legacyFixedBowlPoursProbe,120+i,4,bowls,stone)
    Permutation.execute=savedPerm
    assert(not ok and tostring(err)==mark)
    failures=failures+1
    recovery()
end

for i=1,4 do
    local mark="FAIL_SAVE_"..i
    Save.savePatch=function() error(mark,0) end
    local ok,err=pcall(S.legacyFixedBowlPoursProbe,120+i,4,bowls,stone)
    Save.savePatch=savedSave
    assert(not ok and tostring(err)==mark)
    failures=failures+1
    recovery()
end

for i=1,4 do
    local mark="FAIL_BIGINT_MUL_"..i
    B.mul=function() error(mark,0) end
    local ok,err=pcall(S.legacyFixedBowlPoursProbe,120+i,4,bowls,stone)
    B.mul=savedMul
    assert(not ok and tostring(err)==mark)
    failures=failures+1
    recovery()
end

for i=1,4 do
    Permutation.execute=function(drop)
        local order,context=savedPerm(drop)
        if i==1 then order[1]=7
        elseif i==2 then order[2]=order[1]
        elseif i==3 then order[1],order[2]=order[2],order[1]
        else context.semanticState.permutation="FALSIFIKASYON" end
        return order,context
    end
    local ok=pcall(S.legacyFixedBowlPoursProbe,121,4,bowls,stone)
    Permutation.execute=savedPerm
    assert(not ok,"DISCOVERY 09 te aksepte permutation falsifye "..i)
    failures=failures+1
    recovery()
end
assert(Permutation.execute==savedPerm and Save.savePatch==savedSave and B.mul==savedMul)
assert(failures==16 and recoveries==16)
print("PASS Stage 18 fail-closed: 16 piki, 16 rekiperasyon, 4 permutation falsifye")
