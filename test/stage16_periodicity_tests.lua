local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local BigInt=require("bigint")
local Legacy=require("legacy_permutation")
local Spaghetti=require("spaghetti")

-- Endepandan de modulo BigInt: yon kalkil sou chif desimal yo menm.
local function decimalMod(raw, divisor)
    assert(type(raw)=="string" and raw:match("^%-?%d+$"))
    local sign=raw:sub(1,1)=="-" and -1 or 1
    local digits=sign==-1 and raw:sub(2) or raw
    local remainder=0
    for i=1,#digits do
        remainder=(10*remainder+tonumber(digits:sub(i,i)))%divisor
    end
    return (sign*remainder)%divisor
end

local function addPositiveDecimal(raw, extra)
    assert(raw:match("^%d+$") and type(extra)=="number" and extra>=0)
    local carry=extra
    local result={}
    for index=#raw,1,-1 do
        local sum=tonumber(raw:sub(index,index))+carry
        result[#result+1]=tostring(sum%10)
        carry=sum//10
    end
    while carry>0 do
        result[#result+1]=tostring(carry%10)
        carry=carry//10
    end
    local digits={}
    for index=#result,1,-1 do digits[#digits+1]=result[index] end
    return table.concat(digits)
end

local function equals(a,b)
    if a==nil or b==nil then return a==b end
    if #a~=6 or #b~=6 then return false end
    for i=1,6 do if a[i]~=b[i] then return false end end
    return true
end

local checks,shifted,rejected=0,0,0
local function verify(raw)
    local expectedRank=((decimalMod(raw,720)-1)%720)+1
    local original=BigInt.from(raw)
    assert(Legacy.oldOneBasedRank(original)==expectedRank,
           "Ran mod 720 pa kòrèk pou "..raw)
    local actual,ctx=Spaghetti.legacyPermutationProbe(original)
    assert(ctx.commitToken==2 and ctx.semanticState.rankActuallyPassed==expectedRank)
    assert(ctx.semanticState.requiredUnrankBase==0)
    assert(#ctx.branchTrace==2 and ctx.pendingSemanticState==nil)
    if expectedRank==720 then
        assert(actual==nil and ctx.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==1)
        rejected=rejected+1
    else
        assert(equals(actual,Legacy.oldPermutationUnrank0(expectedRank)))
        assert(ctx.status=="LEGACY_PERM_SHIFTED")
        assert(ctx.metrics["legacy.permutation.rank720Rejected"]==nil)
        shifted=shifted+1
    end
    checks=checks+1
end

-- Pou tout 720 klas rezidi yo, ajoute/retire 720 san chanje ran legacy.
for rank=1,720 do
    verify(tostring(rank))
    verify(tostring(rank+720))
    verify(tostring(rank-720))
end

-- Plizyè gwosè depase tout longè antye Lua. +720 ak -720 dwe
-- retounen menm ran; pa gen pèt presizyon pandan BigInt/modulo.
local unsigned={
    "0", "1", "720", "719", "721", "10000000000000000000000000000000000000000000000000000000000001",
    string.rep("9",72), "1"..string.rep("0",128),
    string.rep("8",255), "1"..string.rep("0",511)
}
for _,raw in ipairs(unsigned) do
    local plus=addPositiveDecimal(raw,720)
    assert(decimalMod(raw,720)==decimalMod(plus,720),"Erè nan oracle desimal +720")
    verify(raw)
    verify(plus)
    if raw~="0" then verify("-"..raw) end
    verify("-"..plus)
end
assert(checks==2199 and checks==shifted+rejected)
assert(rejected>0 and shifted>0)
print("PASS peryodisite Stage 16: "..checks.." apèl, +720/-720, gwo antye, "..
      shifted.." rang deplase, "..rejected.." rang 720 rejte")
