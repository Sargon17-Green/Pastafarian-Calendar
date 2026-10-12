local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local Legacy=require("legacy_permutation")
local S=require("spaghetti")
local O=require("normative_oracle")
local oldUnrank=Legacy.oldPermutationUnrank0
local oldMod=B.mod
local nested,outer,failures=0,0,0

local function check(order,ctx,drop)
    local norm=O.bowlOrderFromDrop(B.from(drop))
    assert(table.concat(order,",")==table.concat(norm,","))
    assert(ctx.mode=="STAGE_17_PATCH_08" and ctx.status=="PATCH_PERM_RETURNED")
    assert(ctx.commitToken==3 and #ctx.branchTrace==3 and #ctx.diagnostics==2)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.semanticState.rankZeroBased==((drop-1)%720))
    assert(ctx.metrics["permutation.patch.calls"]==1)
end

-- Yon apèl nested nan konvèsyon BigInt la, anvan premye commit outer la.
for _,rank in ipairs({1,5,719,720}) do
    local guard=false
    local captured
    B.mod=function(...)
        if not guard then
            guard=true
            local result,ctx=S.permutationPatchProbe(17)
            captured={result,ctx}
            guard=false
        end
        return oldMod(...)
    end
    local ok,result,ctx=pcall(S.permutationPatchProbe,rank)
    B.mod=oldMod
    assert(ok and captured,"Rank outer echwe pandan reentrance BigInt")
    check(captured[1],captured[2],17)
    check(result,ctx,rank)
    captured[2].semanticState.rankZeroBased=999
    assert(ctx.semanticState.rankZeroBased==((rank-1)%720))
    nested=nested+1;outer=outer+1
end

-- Apèl nested pandan twazyèm handler la ap rele unrank0 korije a.
for _,rank in ipairs({1,5,19,719}) do
    local guard=false
    local captured
    Legacy.oldPermutationUnrank0=function(r)
        if r==rank-1 and not guard then
            guard=true
            local result,ctx=S.permutationPatchProbe(23)
            captured={result,ctx}
            guard=false
        end
        return oldUnrank(r)
    end
    local ok,result,ctx=pcall(S.permutationPatchProbe,rank)
    Legacy.oldPermutationUnrank0=oldUnrank
    assert(ok and captured,"Rank outer echwe pandan reentrance unrank0")
    check(captured[1],captured[2],23)
    check(result,ctx,rank)
    captured[1][1]=999
    assert(table.concat(result,",")==table.concat(O.bowlOrderFromDrop(B.from(rank)),","))
    nested=nested+1;outer=outer+1
end

-- Panik injected pa dwe tounen yon rejè legacy rank720.
for _,rank in ipairs({1,720}) do
    local marker="NESTED_PATCH_FAILURE_"..rank
    B.mod=function() error(marker,0) end
    local ok,err=pcall(S.permutationPatchProbe,rank)
    B.mod=oldMod
    assert(not ok and tostring(err)==marker)
    local result,ctx=S.permutationPatchProbe(rank)
    check(result,ctx,rank)
    failures=failures+1
end
assert(Legacy.oldPermutationUnrank0==oldUnrank and B.mod==oldMod)
assert(nested==8 and outer==8 and failures==2)
print("PASS Stage 17 reentrance: 8 nested, 8 outer, 2 panik ak rekiperasyon")
