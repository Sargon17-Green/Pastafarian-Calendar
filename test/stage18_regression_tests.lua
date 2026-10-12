local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local c,t=F,F
local old=O.initialBowls(O.workCounts(c,t))
local store={}
local wrongIndices,wrongPours=0,0
for i=1,3 do
    local drop,visibleContext=S.visibleDropSpaghetti(c,t,i,store)
    assert(visibleContext.status=="PATCH_VISIBLE_COMPLETE")
    local stones=O.STONES[i]
    local order=O.bowlOrderFromDrop(drop)
    local fixed,ctx=S.legacyFixedBowlPoursProbe(drop,i,old,{
        w=stones[1],b=stones[2],s=stones[3],m=stones[4],r=stones[5]
    })
    assert(ctx.semanticState.visibleIndex==i and ctx.commitToken==1)
    assert(table.concat(ctx.semanticState.correctedOrder,",")==table.concat(order,","))
    local mismatch=0
    for position=1,3 do
        local correct=O.SAVE(B.from(drop)*B.from(drop)+stones[position]*old[order[position]]
                       +B.from(({3,5,7})[position]*i))
        if B.compare(fixed[position],correct)~=0 then mismatch=mismatch+1 end
    end
    assert(mismatch>=1, "Prematireman PATCH 09 antre pou gout "..i)
    wrongIndices=wrongIndices+1
    wrongPours=wrongPours+mismatch
    store[i]=B.from(drop)
end
assert(wrongIndices==3 and wrongPours>=3)
error("EXPECTED_RED Stage 18 DISCOVERY 09: 3 gout, vide id fiks kont lòd korije",0)
