local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Pour=require("pour_patch")
local Save=require("save_patch")
local initial={10,20,30,40,50,60}
local rock={w=2,b=3,s=5,m=7,r=11}
local oldPour=Pour.execute
local oldSave=Save.savePatch
local faults,recoveries=0,0
local function good()
    local result,context=S.legacyAliasedStirProbe(241,4,initial,rock)
    assert(#result==6 and context.commitToken==3)
    assert(context.pendingSemanticState==nil and context.rollbackSnapshot==nil)
    assert(context.status=="LEGACY_STIR_ALIASED_RETURNED")
    recoveries=recoveries+1
end
for i=1,4 do
    local mark="FAIL_POUR_STAGE20_"..i
    Pour.execute=function() error(mark,0) end
    local ok,err=pcall(S.legacyAliasedStirProbe,241,4,initial,rock)
    Pour.execute=oldPour
    assert(not ok and err==mark)
    faults=faults+1;good()
end
for i=1,4 do
    local mark="FAIL_STIR_SAVE_"..i
    local count=0
    Save.savePatch=function(...)
        count=count+1
        if count==6+i then error(mark,0) end
        return oldSave(...)
    end
    local ok,err=pcall(S.legacyAliasedStirProbe,241,4,initial,rock)
    Save.savePatch=oldSave
    assert(not ok and err==mark,"Pa t enjekte SAVE nan pozisyon "..i)
    faults=faults+1;good()
end
for i=1,4 do
    Pour.execute=function(...)
        local pours,ctx=oldPour(...)
        if i==1 then ctx.semanticState.correctedOrder[1]=7
        elseif i==2 then ctx.semanticState.initialBowlDecimals[1]="777"
        elseif i==3 then ctx.semanticState.correctedPours[1]="777"
        else ctx.permutationContext.semanticState.permutation="FALSIFIKASYON" end
        return pours,ctx
    end
    local ok=pcall(S.legacyAliasedStirProbe,241,4,initial,rock)
    Pour.execute=oldPour
    assert(not ok,"Tras falsifye pa rejte: "..i)
    faults=faults+1;good()
end
assert(faults==12 and recoveries==12)
assert(Pour.execute==oldPour and Save.savePatch==oldSave)
local once,context=S.legacyAliasedStirProbe(241,4,initial,rock)
local saved={}
for id=1,6 do saved[id]=tostring(once[id]) end
once[1].d[1]=555555
context.semanticState.historicalAliasedBowls[1]="FALSE"
context.diagnostics[3].samePhysicalWorkingTable=false
local twice,other=S.legacyAliasedStirProbe(241,4,initial,rock)
for id=1,6 do assert(tostring(twice[id])==saved[id] and initial[id]==id*10) end
assert(other.diagnostics[3].samePhysicalWorkingTable)
print("PASS Stage 20: 12 injections, 12 rekiperasyon, ownership pa pataje")
