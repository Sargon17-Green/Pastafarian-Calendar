local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local Legacy=require("legacy_permutation")
local function equal(a,b)
    if not a or not b or #a~=6 or #b~=6 then return false end
    for i=1,6 do if a[i]~=b[i] then return false end end
    return true
end

local corrected,shifted,missing=0,0,0
for rank=1,720 do
    local actual,context=S.permutationPatchProbe(B.from(rank))
    local expected=O.bowlOrderFromDrop(B.from(rank))
    assert(equal(actual,expected),"PATCH 08 echwe pou rank "..rank)
    assert(equal(S.permutationSpaghetti(rank),expected))
    assert(context.phase=="PATCH_PERM_UNRANK" and context.mode=="STAGE_17_PATCH_08")
    assert(context.status=="PATCH_PERM_RETURNED" and context.commitToken==3)
    assert(context.currentHandler=="PERMUTATION_PATCH")
    assert(context.previousHandler=="LEGACY_PERM_UNRANK0")
    assert(#context.branchTrace==3
           and context.branchTrace[1]=="LEGACY_ONE_BASED_RANK"
           and context.branchTrace[2]=="LEGACY_PERM_UNRANK0"
           and context.branchTrace[3]=="PERMUTATION_PATCH")
    assert(context.pendingSemanticState==nil and context.rollbackSnapshot==nil)
    local st=context.semanticState
    assert(st.rankOneBased==rank and st.rankZeroBased==rank-1)
    assert(st.legacyRankActuallyPassed==rank and st.rankActuallyPassed==rank-1)
    assert(st.requiredUnrankBase==0 and st.source=="PATCH_08_ONE_BASED_TO_ZERO_BASED")
    assert(st.legacyCallPreserved and st.corrected and not st.missing)
    assert(st.permutation==table.concat(expected,","))
    assert(context.metrics["legacy.permutation.oneBasedRanks"]==1)
    assert(context.metrics["legacy.permutation.unrankCalls"]==1)
    assert(context.metrics["permutation.patch.calls"]==1)
    assert(context.metrics["permutation.patch.correctedRanks"]==1)
    assert(context.metrics["permutation.patch.zeroBasedRank"][1]==tostring(rank-1))
    assert(#context.diagnostics==2 and
           context.diagnostics[2].code=="PATCH_08_SHIFT_ONE_BASED_RANK_DOWN_ONE")
    if rank==720 then
        assert(st.legacyMissing and st.legacyPermutation=="MISSING")
        assert(context.metrics["legacy.permutation.rank720Rejected"]==1)
        assert(context.diagnostics[1].code=="ONE_BASED_720_INVALID_FOR_UNRANK0")
        local bad,badContext=S.legacyPermutationProbe(rank)
        assert(bad==nil and badContext.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        missing=missing+1
    else
        assert(not st.legacyMissing)
        local old=Legacy.oldPermutationUnrank0(rank)
        assert(st.legacyPermutation==table.concat(old,","))
        assert(not equal(old,expected))
        local bad,badContext=S.legacyPermutationProbe(rank)
        assert(equal(bad,old) and badContext.status=="LEGACY_PERM_SHIFTED")
        shifted=shifted+1
    end
    corrected=corrected+1
end
assert(corrected==720 and shifted==719 and missing==1)
local original=S.permutationPatchProbe(1)
original[1]=100
assert(equal(S.permutationSpaghetti(1),{1,2,3,4,5,6}))
local a,c1=S.permutationPatchProbe(720)
a[1]=42;c1.semanticState.rankZeroBased=-1
c1.diagnostics[2].correctedRank=-1;c1.branchTrace[1]="FAKE"
local b,c2=S.permutationPatchProbe(720)
assert(equal(b,{6,5,4,3,2,1}) and c2.semanticState.rankZeroBased==719)
assert(c2.diagnostics[2].correctedRank==719 and c2.branchTrace[1]=="LEGACY_ONE_BASED_RANK")
assert(select("#",S.permutationSpaghetti(1))==1)
assert(select("#",S.permutationPatchProbe(1))==2)
print("PASS Stage 17: 720/720 rank korije; 719 legacy deplase, 1 rejè konsève; 3 commit")
