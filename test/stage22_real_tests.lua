local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local pairs={{F,F},{F+1,F-1},{F-5,F+9}}
local completed,differing=0,0
for _,pair in ipairs(pairs) do
 local c,t=pair[1],pair[2]
 local initial=O.initialBowls(O.workCounts(c,t))
 local drops,stones,history={},{},{}
 for i=1,3 do
    local drop,visible=S.visibleDropSpaghetti(c,t,i,history)
    assert(visible.status=="PATCH_VISIBLE_COMPLETE" and visible.completedGrinds==11)
    drops[i]=B.from(drop)
    history[i]=B.from(drop)
    local rock=O.STONES[i]
    stones[i]={w=rock[1],b=rock[2],s=rock[3],m=rock[4],r=rock[5]}
 end
 local result,ctx=S.legacyResetBowlsProbe(drops,stones,initial)
 assert(ctx.semanticState.completedDropCount==3)
 assert(ctx.semanticState.ignoredPreviousOutputs==2)
 local latest=S.stirPatchProbe(drops[3],3,initial,stones[3])
 for id=1,6 do assert(B.compare(result[id],latest[id])==0) end
 local proper={}
 for id=1,6 do proper[id]=B.from(initial[id]) end
 for i=1,3 do proper=S.stirPatchProbe(drops[i],i,proper,stones[i]) end
 local differences=0
 for id=1,6 do if B.compare(result[id],proper[id])~=0 then differences=differences+1 end end
 assert(differences>=1)
 differing=differing+differences
 completed=completed+1
end
local first,ctx=S.visibleResetChainProbe(F,F,3)
assert(ctx.metrics["discovery11.visible.calls"]==1
    and ctx.visibleDropCount==3
    and #ctx.visibleContexts==3
    and ctx.visibleContexts[3].status=="PATCH_VISIBLE_COMPLETE")
local api=S.visibleResetChainProbe(F,F,3)
for id=1,6 do assert(B.compare(first[id],api[id])==0) end
assert(completed==3 and differing>=3)
print("PASS Stage 22 real: 3 jou, 9 gout, 3 kaskad istorik")
