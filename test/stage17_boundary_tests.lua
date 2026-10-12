local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local cases={"0","1","2","719","720","721","1440","1441","-1","-2","-719","-720","-721",
 "170141183460469231731687303715884105727",
 "170141183460469231731687303715884105728",
 "1"..string.rep("0",200),"-"..string.rep("9",257)}
local seed=20261012
for i=1,220 do
    seed=(seed*48271)%2147483647
    local digits={tostring(seed%9+1)}
    for j=1,60+(i%180) do
        seed=(seed*48271)%2147483647
        digits[#digits+1]=tostring(seed%10)
    end
    cases[#cases+1]=(i%4==0 and "-" or "")..table.concat(digits)
end
local function mod720(str)
    local negative=str:sub(1,1)=="-"
    local rem=0
    for d in str:gmatch("%d") do rem=(rem*10+tonumber(d))%720 end
    if negative then rem=(-rem)%720 end
    return rem
end
for _,raw in ipairs(cases) do
    local b=B.from(raw)
    local expected=O.bowlOrderFromDrop(b)
    local actual,ctx=S.permutationPatchProbe(b)
    local rank0=(mod720(raw)-1)%720
    assert(ctx.semanticState.rankZeroBased==rank0)
    assert(table.concat(actual,",")==table.concat(expected,","),"BigInt boundary "..raw)
    local shifted=B.add(b,B.from(720))
    local periodic=S.permutationSpaghetti(shifted)
    assert(table.concat(periodic,",")==table.concat(expected,","))
end
assert(#cases==237)
print("PASS Stage 17 BigInt boundary: 237 cases, >256 bit, negative, +/-720")
