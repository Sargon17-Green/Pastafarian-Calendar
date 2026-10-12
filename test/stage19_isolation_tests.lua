local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local B=require("bigint")
local Legacy=require("legacy_fixed_pours")
local oldExecute=Legacy.execute
local bowls={10,20,30,40,50,60}
local stones={w=2,b=3,s=5,m=7,r=11}
local calls=0
for _,drop in ipairs({1,121,241,720}) do
    local guard=false
    local nested
    Legacy.execute=function(...)
        if not guard then
            guard=true
            local answer,ctx=S.pourPatchProbe(17,4,bowls,stones)
            nested={answer,ctx}
            guard=false
        end
        return oldExecute(...)
    end
    local ok,result,ctx=pcall(S.pourPatchProbe,drop,4,bowls,stones)
    Legacy.execute=oldExecute
    assert(ok and nested)
    assert(ctx.commitToken==2 and nested[2].commitToken==2)
    nested[1][1].d[1]=123
    nested[2].semanticState.usedBowlIds[1]=99
    assert(ctx.semanticState.usedBowlIds[1]~=99)
    assert(ctx.pendingSemanticState==nil and nested[2].pendingSemanticState==nil)
    calls=calls+1
end
local first,ctx1=S.pourPatchProbe(241,4,bowls,stones)
local baseline={tostring(first[1]),tostring(first[2]),tostring(first[3])}
first[1].d[1]=424242
ctx1.semanticState.usedBowlIds[1]=99
ctx1.diagnostics[2].correctedIds[1]=99
ctx1.branchTrace[1]="FALSIFIKASYON"
local another,ctx2=S.pourPatchProbe(241,4,bowls,stones)
for p=1,3 do assert(tostring(another[p])==baseline[p]) end
assert(ctx2.semanticState.usedBowlIds[1]~=99)
assert(ctx2.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS")
assert(ctx2.diagnostics[2].correctedIds[1]~=99)
assert(Legacy.execute==oldExecute and calls==4)
print("PASS Stage 19 isolation: 4 nested, kopi BigInt ak kontèks endepandan")
