local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local Legacy=require("legacy_permutation")
local S=require("spaghetti")
local B=require("bigint")
local originalUnrank=Legacy.oldPermutationUnrank0
local originalMod=B.mod
local errors,afterFailures=0,0

-- Defe pcall nan dezyèm handler la, aprè commit rank la; lòt apèl dwe pwòp.
for rank=1,6 do
    local marker="INJECTED_PERM_RANK_"..rank
    Legacy.oldPermutationUnrank0=function(g)
        if g==rank then error(marker,0) end
        return originalUnrank(g)
    end
    local ok,err=pcall(S.legacyPermutationProbe,rank)
    Legacy.oldPermutationUnrank0=originalUnrank
    assert(not ok and tostring(err):find(marker,1,true),
           "Pa dwe kache echèk unrank kòm yon rang 720 ki manke")
    local nextOrder,nextCtx=S.legacyPermutationProbe(1)
    assert(nextOrder~=nil and nextCtx.commitToken==2)
    assert(nextCtx.status=="LEGACY_PERM_SHIFTED")
    assert(nextCtx.metrics["legacy.permutation.rank720Rejected"]==nil)
    errors=errors+1;afterFailures=afterFailures+1
end

-- Menm lè rang lan se 720, yon erè ki pa erè validasyon 0..719
-- pa dwe parèt kòm mank istorik la. Sinon audit la ka bay fo PASS.
do
    local marker="INJECTED_UNRANK_720_NOT_VALIDATION"
    Legacy.oldPermutationUnrank0=function() error(marker,0) end
    local ok,err=pcall(S.legacyPermutationProbe,720)
    Legacy.oldPermutationUnrank0=originalUnrank
    assert(not ok and tostring(err):find(marker,1,true),
           "Rang 720 pa gen dwa kache okenn erè sof validasyon legacy la")
    local result,ctx=S.legacyPermutationProbe(720)
    assert(result==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
    assert(ctx.metrics["legacy.permutation.rank720Rejected"]==1)
    errors=errors+1;afterFailures=afterFailures+1
end

-- Echèk nan konvèsyon rank la pa dwe tounen yon rès modil envante.
for i=1,6 do
    local marker="INJECTED_BIGINT_MOD_"..i
    B.mod=function() error(marker,0) end
    local ok,msg=pcall(S.legacyPermutationProbe,i)
    B.mod=originalMod
    assert(not ok and tostring(msg):find(marker,1,true),"Echèk mod pa pwopaje")
    local order,ctx=S.legacyPermutationProbe(i)
    assert(order~=nil and ctx.commitToken==2 and ctx.status=="LEGACY_PERM_SHIFTED")
    errors=errors+1;afterFailures=afterFailures+1
end

-- Kòd istorik la pa dwe aksepte rang ki pa antye ni done ki pa desimal.
for _,bad in ipairs({"pa-yon-antye",true,{},"3.14"}) do
    assert(not pcall(S.permutationSpaghetti,bad))
end
assert(Legacy.oldPermutationUnrank0==originalUnrank and B.mod==originalMod)
assert(errors==13 and afterFailures==13)
print("PASS rezilyans Stage 16: 13 piki erè, 13 nouvo invocation pwòp")
