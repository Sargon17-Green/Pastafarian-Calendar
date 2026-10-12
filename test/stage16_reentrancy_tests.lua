local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local Legacy=require("legacy_permutation")
local S=require("spaghetti")

-- Nan reentrance, chak dispatcher dwe kenbe pwòp kontèks ak commit li.
-- Nou pa chanje fòmil rank istorik la ni ekri okenn PATCH 08.
local oldMod=B.mod
local oldUnrank=Legacy.oldPermutationUnrank0
local nestedCalls, outerCalls, injectedErrors=0,0,0
local function checkFresh(order,ctx,rank)
    assert(ctx.mode=="STAGE_16_DISCOVERY_08" and ctx.commitToken==2)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.semanticState.rankActuallyPassed==rank)
    assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_ONE_BASED_RANK")
    assert(ctx.branchTrace[2]=="LEGACY_PERM_UNRANK0")
    assert(ctx.metrics["legacy.permutation.oneBasedRanks"]==1)
    assert(ctx.metrics["legacy.permutation.unrankCalls"]==1)
    assert(#ctx.diagnostics==1)
    if rank==720 then
        assert(order==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==1)
    else
        assert(type(order)=="table" and #order==6)
        assert(ctx.status=="LEGACY_PERM_SHIFTED")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==nil)
        local expected=oldUnrank(rank)
        assert(table.concat(order,",")==table.concat(expected,","))
    end
end

-- Reentrance nan premye handler la, anvan commit rank outer la.
for _,rank in ipairs({1,5,719,720}) do
    local inside=false
    local captured
    B.mod=function(...)
        if not inside then
            inside=true
            local result,ctx=S.legacyPermutationProbe(17)
            captured={result,ctx}
            inside=false
        end
        return oldMod(...)
    end
    local ok,result,ctx=pcall(S.legacyPermutationProbe,rank)
    B.mod=oldMod
    assert(ok and captured,"Pa gen reentrance nan premye handler la")
    checkFresh(captured[1],captured[2],17)
    checkFresh(result,ctx,rank)
    -- Domaje yon kontèks, verifye lòt la rete endepandan.
    captured[2].semanticState.rankActuallyPassed=999
    assert(ctx.semanticState.rankActuallyPassed==rank)
    nestedCalls=nestedCalls+1;outerCalls=outerCalls+1
end

-- Reentrance pandan dezyèm handler la ap kalkile permutation la.
for _,rank in ipairs({1,5,19,719}) do
    local inside=false
    local captured
    Legacy.oldPermutationUnrank0=function(x)
        if not inside then
            inside=true
            local result,ctx=S.legacyPermutationProbe(23)
            captured={result,ctx}
            inside=false
        end
        return oldUnrank(x)
    end
    local ok,result,ctx=pcall(S.legacyPermutationProbe,rank)
    Legacy.oldPermutationUnrank0=oldUnrank
    assert(ok and captured,"Pa gen reentrance nan dezyèm handler la")
    checkFresh(captured[1],captured[2],23)
    checkFresh(result,ctx,rank)
    nestedCalls=nestedCalls+1;outerCalls=outerCalls+1
end

-- Yon echèk nested pa dwe tounen yon erè expected-red, menm lè
-- travay ekstèn nan t ap kalkile rank 720. Apre li, nouvo travay pwòp.
for _,rank in ipairs({1,720}) do
    local inside=false
    local marker="NESTED_FAILURE_"..rank
    B.mod=function(...)
        if not inside then
            inside=true
            error(marker,0)
        end
        return oldMod(...)
    end
    local ok,err=pcall(S.legacyPermutationProbe,rank)
    B.mod=oldMod
    assert(not ok and tostring(err)==marker,
           "Echèk nested la te kache kòm validasyon rank720")
    local result,ctx=S.legacyPermutationProbe(rank)
    checkFresh(result,ctx,rank)
    injectedErrors=injectedErrors+1
end
assert(B.mod==oldMod and Legacy.oldPermutationUnrank0==oldUnrank)
assert(nestedCalls==8 and outerCalls==8 and injectedErrors==2)
print("PASS reentrance Stage 16: 8 apèl nested, 8 outer, 2 panik klè, 2 rekiperasyon")
