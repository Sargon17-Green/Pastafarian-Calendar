local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local BigInt=require("bigint")
local Legacy=require("legacy_permutation")
local S=require("spaghetti")

-- Plizyè invocation ak anpil BigInt; chak invocation dwe posede rezilta li.
-- Kalkil rank la fèt sou chif yo, apa de BigInt ki anba tès la.
local function decimalMod720(raw)
    local negative=raw:sub(1,1)=="-"
    local digits=negative and raw:sub(2) or raw
    local rem=0
    for i=1,#digits do
        rem=(rem*10+tonumber(digits:sub(i,i)))%720
    end
    return (negative and -rem or rem)%720
end
local function same(a,b)
    if a==nil or b==nil then return a==b end
    if #a~=6 or #b~=6 then return false end
    for j=1,6 do if a[j]~=b[j] then return false end end
    return true
end

local seed=20161012
local function nextRandom()
    seed=(seed*48271)%2147483647
    return seed
end
local complete,missing=0,0
for case=1,360 do
    local length=70+(case%177)
    local digits={tostring(1+(nextRandom()%9))}
    for j=2,length do digits[#digits+1]=tostring(nextRandom()%10) end
    local raw=(case%3==0 and "-" or "")..table.concat(digits)
    local input=BigInt.from(raw)
    local before=tostring(input)
    local expectedRank=((decimalMod720(raw)-1)%720)+1
    local order,ctx=S.legacyPermutationProbe(input)
    assert(tostring(input)==before,"Yon apèl modifye BigInt antre a")
    assert(ctx.commitToken==2 and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.semanticState.rankOneBased==expectedRank)
    assert(ctx.semanticState.rankActuallyPassed==expectedRank)
    assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_ONE_BASED_RANK" and
            ctx.branchTrace[2]=="LEGACY_PERM_UNRANK0")
    assert(ctx.metrics["legacy.permutation.oneBasedRanks"]==1)
    assert(ctx.metrics["legacy.permutation.unrankCalls"]==1)
    if expectedRank==720 then
        assert(order==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==1)
        missing=missing+1
    else
        local exact=Legacy.oldPermutationUnrank0(expectedRank)
        assert(same(order,exact) and ctx.status=="LEGACY_PERM_SHIFTED")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==nil)
        -- Nou detwi kopi rezilta ak kopi eta a: yon lòt apèl rete endepandan.
        order[1]=99
        complete=complete+1
    end
    ctx.semanticState.rankActuallyPassed=999
    ctx.branchTrace[1]="KORIPSYON"
    ctx.metrics["legacy.permutation.unrankCalls"]=999
    ctx.diagnostics[1].code="KORIPSYON"
    local nextOrder,nextCtx=S.legacyPermutationProbe(input)
    assert(nextCtx.commitToken==2 and nextCtx.semanticState.rankActuallyPassed==expectedRank)
    assert(nextCtx.branchTrace[1]=="LEGACY_ONE_BASED_RANK")
    assert(nextCtx.metrics["legacy.permutation.unrankCalls"]==1)
    assert(nextCtx.diagnostics[1].code~="KORIPSYON")
    if expectedRank==720 then assert(nextOrder==nil)
    else assert(same(nextOrder,Legacy.oldPermutationUnrank0(expectedRank))) end
    if case%30==0 then
        assert(same(S.permutationSpaghetti(input),nextOrder))
    end
end
assert(complete+missing==360)
print("PASS entèlasman Stage 16: 360 BigInt 70..246 chif, 720 invocation, "..
      complete.." deplasman, "..missing.." rejè, eta izole")
