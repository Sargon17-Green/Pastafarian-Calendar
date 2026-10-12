local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local pairs={{F,F},{F+1,F-1},{F-5,F+9}}
local expectedChecks=0
for _,pair in ipairs(pairs) do
    local c,t=pair[1],pair[2]
    local bowls=O.initialBowls(O.workCounts(c,t))
    local store={}
    for i=1,3 do
        local drop,visibleContext=S.visibleDropSpaghetti(c,t,i,store)
        assert(visibleContext.status=="PATCH_VISIBLE_COMPLETE")
        local stone=O.STONES[i]
        local stoneRow={w=stone[1],b=stone[2],s=stone[3],m=stone[4],r=stone[5]}
        local order=O.bowlOrderFromDrop(drop)
        local pours,ctx=S.pourPatchProbe(drop,i,bowls,stoneRow)
        assert(ctx.commitToken==2 and ctx.status=="PATCH_POUR_RETURNED")
        assert(table.concat(ctx.semanticState.correctedOrder,",")==table.concat(order,","))
        for p=1,3 do
            local expected=O.SAVE(B.from(drop)*B.from(drop)
              + stone[p]*bowls[order[p]]
              + B.from(({3,5,7})[p]*i))
            assert(B.compare(pours[p],expected)==0,"Gout "..i.." vide "..p)
            expectedChecks=expectedChecks+1
        end
        store[i]=B.from(drop)
    end
end
assert(expectedChecks==27)
local corrected,ctx=S.openingPoursPatchProbe(F,F)
assert(ctx.status=="PATCH_POUR_RETURNED" and ctx.metrics["patch09.opening.probes"]==1)
assert(ctx.visibleContext.status=="PATCH_VISIBLE_COMPLETE")
local order=O.bowlOrderFromDrop(ctx.firstVisibleDrop)
local bowls=O.initialBowls(O.workCounts(F,F))
for p=1,3 do
    local expected=O.SAVE(ctx.firstVisibleDrop*ctx.firstVisibleDrop
      + O.STONES[1][p]*bowls[order[p]]
      + B.from(({3,5,7})[p]))
    assert(B.compare(corrected[p],expected)==0)
end
local public=S.openingPoursSpaghetti(F,F)
for p=1,3 do assert(B.compare(corrected[p],public[p])==0) end
print("PASS Stage 19: 9 gout vizib reyèl, 27 vide, premye gout piblik korije")
