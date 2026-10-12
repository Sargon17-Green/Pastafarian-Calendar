local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local B=require("bigint")
local Pour=require("pour_patch")
local Save=require("save_patch")
local oldPour=Pour.execute
local oldSave=Save.savePatch
local oldBowls={10,20,30,40,50,60}
local stone={w=2,b=3,s=5,m=7,r=11}
local nested,outer=0,0
local function verify(result,ctx)
    assert(#result==6 and ctx.commitToken==3
        and ctx.mode=="STAGE_20_DISCOVERY_10"
        and ctx.status=="LEGACY_STIR_ALIASED_RETURNED"
        and #ctx.branchTrace==3 and #ctx.diagnostics==3
        and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
end
for _,drop in ipairs({1,121,241,720}) do
    local active=false
    local inner
    Pour.execute=function(...)
        if not active then
            active=true
            local result,context=S.legacyAliasedStirProbe(241,5,oldBowls,stone)
            inner={result,context}
            active=false
        end
        return oldPour(...)
    end
    local ok,result,context=pcall(S.legacyAliasedStirProbe,drop,4,oldBowls,stone)
    Pour.execute=oldPour
    assert(ok and inner,"Reentrance pandan PATCH 09 echwe")
    verify(result,context);verify(inner[1],inner[2])
    inner[2].semanticState.correctedOrder[1]=99
    inner[1][1].d[1]=99
    assert(context.semanticState.correctedOrder[1]~=99)
    nested=nested+1;outer=outer+1
end
for _,drop in ipairs({1,121,241,720}) do
    local active=false
    local inner
    Save.savePatch=function(...)
        if not active then
            active=true
            local result,context=S.legacyAliasedStirProbe(121,5,oldBowls,stone)
            inner={result,context}
            active=false
        end
        return oldSave(...)
    end
    local ok,result,context=pcall(S.legacyAliasedStirProbe,drop,4,oldBowls,stone)
    Save.savePatch=oldSave
    assert(ok and inner,"Reentrance pandan brase/SAVE echwe")
    verify(result,context);verify(inner[1],inner[2])
    inner[2].semanticState.previousBowls[1]="XXX"
    assert(context.semanticState.previousBowls[1]~="XXX")
    nested=nested+1;outer=outer+1
end
assert(Pour.execute==oldPour and Save.savePatch==oldSave)
assert(nested==8 and outer==8)
print("PASS Stage 20 reentrance: 8 nested, 8 outer, eta apa")
