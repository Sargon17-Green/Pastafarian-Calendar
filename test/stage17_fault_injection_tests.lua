local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local Legacy=require("legacy_permutation")
local S=require("spaghetti")
local originalUnrank=Legacy.oldPermutationUnrank0
local originalMod=B.mod
local failures=0
local function recover()
    local a,c=S.permutationPatchProbe(720)
    assert(table.concat(a,",")=="6,5,4,3,2,1")
    assert(c.commitToken==3 and c.status=="PATCH_PERM_RETURNED")
end
-- Piki erè nan rank0 korije a, apa de apèl rank1 istorik la.
for drop=1,6 do
    local marker="PATCH08_FAILED_UNRANK_"..drop
    Legacy.oldPermutationUnrank0=function(rank0)
        if rank0==drop-1 then error(marker,0) end
        return originalUnrank(rank0)
    end
    local ok,err=pcall(S.permutationPatchProbe,drop)
    Legacy.oldPermutationUnrank0=originalUnrank
    assert(not ok and tostring(err):find(marker,1,true))
    recover()
    failures=failures+1
end
-- PATCH 08 pa aksepte yon unrank kòripsyon menm san eksepsyon.
for _,mutation in ipairs({
    {1,1,3,4,5,6}, {6,5,4,3,2,1}, {1,2,3,4,5,7}
}) do
    Legacy.oldPermutationUnrank0=function(rank0)
        if rank0==0 then return mutation end
        return originalUnrank(rank0)
    end
    local ok=pcall(S.permutationPatchProbe,1)
    Legacy.oldPermutationUnrank0=originalUnrank
    assert(not ok,"PATCH 08 aksepte permutation falsifye")
    recover()
    failures=failures+1
end
for i=1,6 do
    local marker="PATCH08_BIGINT_MOD_"..i
    B.mod=function() error(marker,0) end
    local ok,err=pcall(S.permutationPatchProbe,i)
    B.mod=originalMod
    assert(not ok and tostring(err):find(marker,1,true))
    recover()
    failures=failures+1
end
for _,bad in ipairs({"not-a-number",false,{},"1.5"}) do
    assert(not pcall(S.permutationSpaghetti,bad))
end
assert(Legacy.oldPermutationUnrank0==originalUnrank and B.mod==originalMod)
assert(failures==15)
print("PASS Stage 17 fail-closed: 15 injections, 15 clean recoveries")
