local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
-- Envestigasyon native: bay yon tras konplè si BigInt refize yon valè.
local savedFrom=B.from
B.from=function(value)
  if value==nil or (type(value)~="string" and type(value)~="number"
      and not (type(value)=="table" and getmetatable(value)==B)) then
    error("STAGE20_BAD_BIGINT_ARGUMENT type="..type(value)..
        " value="..tostring(value).."\n"..debug.traceback("",2),0)
  end
  return savedFrom(value)
end
local pairs={{F,F},{F+1,F-1},{F-5,F+9}}
local count,bad=0,0
local names={"w","b","s","m","r","w"}
for _,pair in ipairs(pairs) do
  local c,t=pair[1],pair[2]
  local old=O.initialBowls(O.workCounts(c,t))
  local drops={}
  for i=1,3 do
    local drop,visibleCtx=S.visibleDropSpaghetti(c,t,i,drops)
    assert(visibleCtx.status=="PATCH_VISIBLE_COMPLETE" and visibleCtx.completedGrinds==11)
    local rock=O.STONES[i]
    local stones={w=rock[1],b=rock[2],s=rock[3],m=rock[4],r=rock[5]}
    local result,ctx=S.legacyAliasedStirProbe(drop,i,old,stones)
    local order=O.bowlOrderFromDrop(drop)
    local pours={}
    for p=1,3 do
        pours[p]=O.SAVE(drop*drop+rock[p]*old[order[p]]+B.from(({3,5,7})[p]*i))
        assert(ctx.semanticState.correctedPours[p]==tostring(pours[p]))
    end
    local expected={}
    for p=1,6 do
        local id=order[p]
        local prev=order[(p+4)%6+1]
        local nextId=order[p%6+1]
        local s=old[id]+B.from(2)*old[prev]+B.from(3)*old[nextId]
          +(p<=3 and pours[p] or B.from(0))+drop+rock[({1,2,3,4,5,1})[p]]
        expected[id]=O.SAVE(s*s+B.from(5)*old[prev]*old[nextId]+B.from(i*p))
    end
    local mismatches=0
    for id=1,6 do
        if B.compare(result[id],expected[id])~=0 then mismatches=mismatches+1 end
    end
    assert(B.compare(result[order[1]],expected[order[1]])==0)
    assert(mismatches>=1,"Premye brase pa demontre alias")
    count=count+1;bad=bad+mismatches
    drops[i]=B.from(drop)
  end
end
assert(count==9 and bad>=9)
local first,ctx=S.openingStirProbe(F,F)
assert(ctx.mode=="STAGE_20_DISCOVERY_10" and ctx.commitToken==3)
assert(ctx.visibleContext.status=="PATCH_VISIBLE_COMPLETE")
assert(ctx.metrics["discovery10.opening.probes"]==1)
local again=S.openingStirSpaghetti(F,F)
for id=1,6 do assert(B.compare(first[id],again[id])==0) end
print("PASS Stage 20 real: 9 gout, brase 6 bòl, alias vizib san modifye antre")
