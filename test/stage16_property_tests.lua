local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local Legacy=require("legacy_permutation")
local S=require("spaghetti")
local O=require("normative_oracle")
local BigInt=require("bigint")
local function same(a,b)
    if a==nil or b==nil then return a==b end
    if #a~=6 or #b~=6 then return false end
    for k=1,6 do if a[k]~=b[k] then return false end end
    return true
end
local shifted,missing=0,0
for drop=1,720 do
    local actual,ctx=S.legacyPermutationProbe(drop)
    local norm=O.bowlOrderFromDrop(BigInt.from(drop))
    local rank=Legacy.oldOneBasedRank(drop)
    assert(rank==drop,"One-based rank pa swiv gout la")
    assert(ctx.mode=="STAGE_16_DISCOVERY_08" and ctx.commitToken==2)
    assert(ctx.phase=="LEGACY_PERM_UNRANK" and ctx.currentHandler=="LEGACY_PERM_UNRANK0")
    assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_ONE_BASED_RANK" and
           ctx.branchTrace[2]=="LEGACY_PERM_UNRANK0")
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.semanticState.rankOneBased==rank and ctx.semanticState.rankActuallyPassed==rank)
    assert(ctx.semanticState.requiredUnrankBase==0)
    assert(ctx.metrics["legacy.permutation.oneBasedRanks"]==1)
    assert(ctx.metrics["legacy.permutation.unrankCalls"]==1)
    assert(ctx.metrics["legacy.permutation.rank"][1]==tostring(rank))
    assert(ctx.metrics["legacy.permutation.lastRank"][1]==tostring(rank))
    assert(#ctx.diagnostics==1 and ctx.diagnostics[1].rankBaseMismatch==true)
    if drop==720 then
        assert(actual==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        assert(ctx.semanticState.missing==true and ctx.semanticState.permutation=="MISSING")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==1)
        assert(ctx.diagnostics[1].code=="ONE_BASED_720_INVALID_FOR_UNRANK0")
        missing=missing+1
    else
        local legacyExpected=Legacy.oldPermutationUnrank0(drop)
        assert(same(actual,legacyExpected),"Rang legacy pa pase antre one-based la")
        assert(not same(actual,norm),"Rang ansyen an korije twò bonè: "..drop)
        assert(ctx.status=="LEGACY_PERM_SHIFTED")
        assert(ctx.semanticState.missing==false)
        assert(ctx.diagnostics[1].code=="ONE_BASED_OFF_BY_ONE_RANK")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==nil)
        shifted=shifted+1
    end
end
assert(shifted==719 and missing==1)
local first,ctx1=S.legacyPermutationProbe(1)
first[1]=99;ctx1.semanticState.rankActuallyPassed=999
ctx1.diagnostics[1].code="CHANJE";ctx1.branchTrace[1]="CHANJE"
ctx1.metrics["legacy.permutation.unrankCalls"]=999
local second,ctx2=S.legacyPermutationProbe(1)
assert(second[1]~=99 and ctx2.semanticState.rankActuallyPassed==1)
assert(ctx2.diagnostics[1].code=="ONE_BASED_OFF_BY_ONE_RANK")
assert(ctx2.branchTrace[1]=="LEGACY_ONE_BASED_RANK")
assert(ctx2.metrics["legacy.permutation.unrankCalls"]==1)
assert(select("#",S.permutationSpaghetti(1))==1)
assert(select("#",S.legacyPermutationProbe(1))==2)
print("PASS Stage 16 pwopriyete: 719 rang deplase, rang 720 manke, de commit, eta posede")
