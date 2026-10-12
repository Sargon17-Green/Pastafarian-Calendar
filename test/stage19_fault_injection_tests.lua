local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_fixed_pours")
local Save=require("save_patch")
local oldExecute=Legacy.execute
local oldSave=Save.savePatch
local oldMul=B.mul
local stones={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local faults,recovered=0,0
local function recovery()
    local result,ctx=S.pourPatchProbe(121,4,bowls,stones)
    assert(#result==3 and ctx.commitToken==2 and ctx.status=="PATCH_POUR_RETURNED")
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    recovered=recovered+1
end
for i=1,4 do
    local tag="LEGACY_EXECUTE_FAIL_"..i
    Legacy.execute=function() error(tag,0) end
    local ok,err=pcall(S.pourPatchProbe,121,4,bowls,stones)
    Legacy.execute=oldExecute
    assert(not ok and err==tag)
    faults=faults+1;recovery()
end
for i=1,4 do
    local tag="PATCH_SAVE_FAIL_"..i
    local hits=0
    Save.savePatch=function(...)
        hits=hits+1
        if hits==3+i then error(tag,0) end
        return oldSave(...)
    end
    local ok,err=pcall(S.pourPatchProbe,121,4,bowls,stones)
    Save.savePatch=oldSave
    assert(not ok and err==tag,"PATCH Save dependency failure hidden: "..i)
    faults=faults+1;recovery()
end
for i=1,4 do
    local tag="PATCH_MUL_FAIL_"..i
    local hits=0
    B.mul=function(...)
        hits=hits+1
        if hits==1+i then error(tag,0) end
        return oldMul(...)
    end
    local ok,err=pcall(S.pourPatchProbe,121,4,bowls,stones)
    B.mul=oldMul
    assert(not ok and err==tag,"PATCH BigInt failure hidden: "..i)
    faults=faults+1;recovery()
end
for i=1,4 do
    Legacy.execute=function(...)
        local wrong,ctx=oldExecute(...)
        if i==1 then ctx.semanticState.correctedOrder[1]=7
        elseif i==2 then ctx.semanticState.correctedOrder[2]=ctx.semanticState.correctedOrder[1]
        elseif i==3 then ctx.semanticState.initialBowlDecimals[1]="999"
        else ctx.semanticState.historicalWrongPours[1]="0" end
        return wrong,ctx
    end
    local ok=pcall(S.pourPatchProbe,121,4,bowls,stones)
    Legacy.execute=oldExecute
    assert(not ok,"PATCH 09 pa rejte falsifikasyon "..i)
    faults=faults+1;recovery()
end
assert(Legacy.execute==oldExecute and Save.savePatch==oldSave and B.mul==oldMul)
assert(faults==16 and recovered==16)
print("PASS Stage 19 fault: 16 echèk, 16 rekiperasyon, panik pa maske")
