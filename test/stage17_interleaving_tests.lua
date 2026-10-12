local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local O=require("normative_oracle")
local seed=17847
local function digit()
    seed=(seed*48271)%2147483647
    return tostring(seed%10)
end
local total=180
for n=1,total do
    local chars={tostring((seed%9)+1)}
    for j=1,85+(n%140) do chars[#chars+1]=digit() end
    local decimal=(n%3==0 and "-" or "")..table.concat(chars)
    local value=B.from(decimal)
    local a,ctx=S.permutationPatchProbe(value)
    local expected=O.bowlOrderFromDrop(value)
    assert(table.concat(a,",")==table.concat(expected,","))
    assert(ctx.status=="PATCH_PERM_RETURNED" and ctx.commitToken==3)
    assert(ctx.metrics["legacy.permutation.unrankCalls"]==1
           and ctx.metrics["permutation.patch.calls"]==1)
    assert(#ctx.branchTrace==3 and #ctx.diagnostics==2)
    local second,secondCtx=S.permutationPatchProbe(value)
    assert(table.concat(second,",")==table.concat(a,","))
    assert(secondCtx.commitToken==3)
    a[1]=777
    ctx.semanticState.rankZeroBased=777
    ctx.branchTrace[1]="KORIPSYON"
    ctx.metrics["permutation.patch.calls"]=999
    ctx.diagnostics[2].code="KORIPSYON"
    assert(table.concat(second,",")==table.concat(expected,","))
    assert(secondCtx.semanticState.rankZeroBased~=777)
    assert(secondCtx.branchTrace[1]=="LEGACY_ONE_BASED_RANK")
    assert(secondCtx.metrics["permutation.patch.calls"]==1)
    assert(secondCtx.diagnostics[2].code=="PATCH_08_SHIFT_ONE_BASED_RANK_DOWN_ONE")
end
print("PASS Stage 17 entèlasman: 180 BigInt, 360 apèl, kopi ak kontèks posede")
