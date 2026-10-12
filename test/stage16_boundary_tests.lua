local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local BigInt=require("bigint")
local Legacy=require("legacy_permutation")
local S=require("spaghetti")
local O=require("normative_oracle")
local samples={
    "0","1","2","6","119","120","121","718","719","720","721","722","1439","1440","1441",
    "-1","-2","-719","-720","-721","-1440","-1441",
    "170141183460469231731687303715884105727",
    "170141183460469231731687303715884105728",
    "-170141183460469231731687303715884105727",
    "1"..string.rep("0",110), "-"..string.rep("9",129)
}
local state=2026
local function nextDigit()
    state=(state*48271)%2147483647
    return tostring(state%10)
end
for i=1,120 do
    local chars={tostring(1+((state+i)%9))}
    for j=1,80+(i%95) do chars[#chars+1]=nextDigit() end
    samples[#samples+1]=(i%3==0 and "-" or "")..table.concat(chars)
end
local function mod720(decimal)
    local sign=1
    if decimal:sub(1,1)=="-" then sign=-1;decimal=decimal:sub(2) end
    local rem=0
    for d in decimal:gmatch("%d") do rem=(rem*10+tonumber(d))%720 end
    return (sign*rem)%720
end
local function equals(a,b)
    if a==nil or b==nil then return a==b end
    for i=1,6 do if a[i]~=b[i] then return false end end
    return true
end
local mismatch,invalid=0,0
for _,raw in ipairs(samples) do
    -- Rezidi a kalkile ak chif yo, endepandan de runtime BigInt.
    local rank=((mod720(raw)-1)%720)+1
    local value=BigInt.from(raw)
    assert(Legacy.oldOneBasedRank(value)==rank,"Ran one-based pou gwo antye: "..raw)
    local actual,context=S.legacyPermutationProbe(value)
    local normative=O.bowlOrderFromDrop(value)
    assert(context.semanticState.rankActuallyPassed==rank)
    assert(context.commitToken==2)
    if rank==720 then
        assert(actual==nil and context.status=="LEGACY_PERM_RANK_OUT_OF_RANGE")
        invalid=invalid+1
    else
        assert(equals(actual,Legacy.oldPermutationUnrank0(rank)))
        assert(not equals(actual,normative))
        mismatch=mismatch+1
    end
end
assert(mismatch+invalid==#samples and #samples==147)
assert(invalid>0 and mismatch>0)
print("PASS Stage 16 baryè: "..mismatch.." rang deplase, "..invalid.." valè 720 rejte; 147 ka, >256 bit")
