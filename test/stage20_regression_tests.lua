local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stones={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local samples={1,2,121,241,720}
local badCases=0
for _,drop in ipairs(samples) do
    local actual,ctx=S.legacyAliasedStirProbe(drop,4,bowls,stones)
    local order=O.bowlOrderFromDrop(drop)
    local pour={}
    for position=1,3 do
      local rock=({2,3,5})[position]
      pour[position]=O.SAVE(B.from(drop)*B.from(drop)+B.from(rock)*B.from(bowls[order[position]])
                       +B.from(({3,5,7})[position]*4))
    end
    local expected={}
    for p=1,6 do
        local id=order[p]
        local prev=order[(p+4)%6+1]
        local nxt=order[p%6+1]
        local saved=B.from(bowls[id])+B.from(2)*B.from(bowls[prev])+B.from(3)*B.from(bowls[nxt])
             +(p<=3 and pour[p] or B.from(0))+B.from(drop)
             +B.from(({2,3,5,7,11,2})[p])
        expected[id]=O.SAVE(saved*saved+B.from(5)*B.from(bowls[prev])*B.from(bowls[nxt])+B.from(4*p))
    end
    local changed=0
    for id=1,6 do if B.compare(expected[id],actual[id])~=0 then changed=changed+1 end end
    assert(changed>=1 and ctx.semanticState.localAliasing)
    badCases=badCases+1
end
assert(badCases==5)
error("EXPECTED_RED Stage 20 DISCOVERY 10: ansyen bòl yo vin alias ak nouvo bòl",0)
