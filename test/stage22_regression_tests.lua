local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local drops={1,121,241,720,0}
local row={w=2,b=3,s=5,m=7,r=11}
local stoneRows={row,row,row,row,row}
local original={10,20,30,40,50,60}
local wrong,ctx=S.legacyResetBowlsProbe(drops,stoneRows,original)
local properly={}
for id=1,6 do properly[id]=B.from(original[id]) end
for i=1,#drops do properly=S.stirPatchProbe(drops[i],i,properly,row) end
local mismatches=0
for id=1,6 do if B.compare(wrong[id],properly[id])~=0 then mismatches=mismatches+1 end end
assert(ctx.semanticState.ignoredPreviousOutputs==4 and mismatches>=1)
assert(#ctx.childContexts==5 and ctx.semanticState.perDrop[1].priorOutputIgnored==false)
assert(ctx.semanticState.perDrop[2].priorOutputIgnored==true)
error("EXPECTED_RED Stage 22 DISCOVERY 11: chak gout rekòmanse ak bòl inisyal",0)
