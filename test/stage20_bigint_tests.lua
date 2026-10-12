local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stones={w=B.from("1"..string.rep("0",73)),b=B.from("2"..string.rep("3",82)),
 s=B.from("4"..string.rep("5",74)),m=B.from("7"..string.rep("9",63)),r=B.from("9"..string.rep("8",65))}
local bowls={}
for id=1,6 do bowls[id]=B.add(B.mulSmall(B.from("1"..string.rep("0",87)),id),id*7) end
local cases={"0","1","2","720","721","-1","-720","-721",
 "1"..string.rep("0",185),"-"..string.rep("9",231)}
local seed=2010
for i=1,90 do
   local chars={tostring(i%9+1)}
   for j=1,75+i do seed=(seed*48271)%2147483647;chars[#chars+1]=tostring(seed%10) end
   cases[#cases+1]=(i%3==0 and "-" or "")..table.concat(chars)
end
local differences=0
for _,str in ipairs(cases) do
    local drop=B.from(str)
    local actual,ctx=S.legacyAliasedStirProbe(drop,46,bowls,stones)
    assert(ctx.commitToken==3 and ctx.metrics["legacy.stir.aliasCalls"]==1)
    local order=O.bowlOrderFromDrop(drop)
    assert(table.concat(order,",")==table.concat(ctx.semanticState.correctedOrder,","))
    local pours={}
    for p,name in ipairs({"w","b","s"}) do
      pours[p]=O.SAVE(drop*drop+stones[name]*bowls[order[p]]+B.from(({3,5,7})[p]*46))
      assert(ctx.semanticState.correctedPours[p]==tostring(pours[p]))
    end
    local working={}
    for j=1,6 do working[j]=B.from(bowls[j]) end
    for p=1,6 do
        local id=order[p]
        local prev=order[(p+4)%6+1]
        local nxt=order[p%6+1]
        local s=working[id]+B.from(2)*working[prev]+B.from(3)*working[nxt]
          +(p<=3 and pours[p] or B.from(0))+drop+stones[({"w","b","s","m","r","w"})[p]]
        working[id]=O.SAVE(s*s+B.from(5)*working[prev]*working[nxt]+B.from(46*p))
    end
    for id=1,6 do assert(B.compare(actual[id],working[id])==0) end
    differences=differences+1
end
assert(differences==100)
print("PASS Stage 20 BigInt: 100 gout laj, negatif, etap 46, alias otantik")
