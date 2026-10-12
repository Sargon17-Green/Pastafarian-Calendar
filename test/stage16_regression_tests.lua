local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local O=require("normative_oracle")
local BigInt=require("bigint")
local shifted,missing=0,0
local function same(a,b)
    if a==nil or b==nil then return a==b end
    if #a~=#b then return false end
    for k=1,6 do if a[k]~=b[k] then return false end end
    return true
end
for drop=1,720 do
    local result=S.permutationSpaghetti(BigInt.from(drop))
    local normative=O.bowlOrderFromDrop(BigInt.from(drop))
    if result==nil then
        assert(drop==720,"Gout ki manke a pa sèl endis 720")
        missing=missing+1
    elseif not same(result,normative) then
        shifted=shifted+1
    end
end
assert(shifted==719 and missing==1,
    "Pa gen egzakteman 719 rang deplase ak yon endis 720 ki manke")
error("EXPECTED_RED Stage 16 DISCOVERY 08: 719 rang deplase, rang 720 rejte",0)
