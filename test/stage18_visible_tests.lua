local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local c,t=F,F
local fixed,ctx=S.openingPoursProbe(c,t)
assert(ctx.mode=="STAGE_18_DISCOVERY_09" and ctx.commitToken==1)
assert(ctx.visibleContext.status=="PATCH_VISIBLE_COMPLETE")
assert(ctx.visibleContext.completedGrinds==11)
assert(ctx.metrics["legacy.fixedPour.calls"]==1 and ctx.metrics["discovery09.opening.probes"]==1)
assert(ctx.permutationContext.commitToken==3)
local drop=S.visibleDropSpaghetti(c,t,1,{})
assert(B.compare(ctx.firstVisibleDrop,drop)==0)
local bowls=O.initialBowls(O.workCounts(c,t))
for p=1,6 do assert(B.compare(ctx.initialBowls[p],bowls[p])==0) end
local order=O.bowlOrderFromDrop(drop)
assert(table.concat(ctx.semanticState.correctedOrder,",")==table.concat(order,","))
local stones=O.STONES[1]
local mismatches=0
for p=1,3 do
    local selector=({1,2,3})[p]
    local factor=({3,5,7})[p]
    local historical=O.SAVE(B.from(drop)*B.from(drop)+stones[p]*bowls[selector]+B.from(factor))
    local correct=O.SAVE(B.from(drop)*B.from(drop)+stones[p]*bowls[order[p]]+B.from(factor))
    assert(B.compare(fixed[p],historical)==0)
    if B.compare(fixed[p],correct)~=0 then mismatches=mismatches+1 end
end
assert(mismatches==3,"Premye gout fondasyon an pa montre twa defo yo")
local repeated=S.openingPoursProbe(c,t)
for p=1,3 do assert(B.compare(fixed[p],repeated[p])==0) end
print("PASS entegrasyon Stage 18: gout vizib reyèl i=1, 11 grind, 3 vide kòripsyon")
