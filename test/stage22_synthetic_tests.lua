local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stone={w=2,b=3,s=5,m=7,r=11}
local original={10,20,30,40,50,60}
local factors={3,5,7}
local rocks={2,3,5,7,11,2}
local function norm(drops,stoneRows,bowls)
 local active={}
 for id=1,6 do active[id]=B.from(bowls[id]) end
 local snapshots={}
 for i,drop in ipairs(drops) do
   local old={}
   for id=1,6 do old[id]=B.from(active[id]) end
   local order=O.bowlOrderFromDrop(B.from(drop))
   local stoneRow=stoneRows[i]
   local rs={stoneRow.w,stoneRow.b,stoneRow.s,stoneRow.m,stoneRow.r,stoneRow.w}
   local pours={}
   for p=1,3 do pours[p]=O.SAVE(B.from(drop)*B.from(drop)+rs[p]*old[order[p]]+B.from(factors[p]*i)) end
   local after={}
   for p=1,6 do
      local id=order[p]
      local prev=order[(p+4)%6+1]
      local nxt=order[p%6+1]
      local s=old[id]+B.from(2)*old[prev]+B.from(3)*old[nxt]
       +(p<=3 and pours[p] or B.from(0))+B.from(drop)+rs[p]
      after[id]=O.SAVE(s*s+B.from(5)*old[prev]*old[nxt]+B.from(i*p))
   end
   active=after
   snapshots[i]=after
 end
 return active,snapshots
end
local samples={{1},{1,2},{121,241},{1,121,241},{720,719,718,717,716},
 {1,121,241,720,0,-37,500},{11,22,33,44,55,66,77,88}}
local resets=0
for _,drops in ipairs(samples) do
 local stones={}
 for i=1,#drops do stones[i]=stone end
 local output,ctx=S.legacyResetBowlsProbe(drops,stones,original)
 local correct,byStep=norm(drops,stones,original)
 assert(ctx.mode=="STAGE_22_DISCOVERY_11" and ctx.status=="LEGACY_RESET_COMPLETE"
    and ctx.commitToken==1 and #ctx.branchTrace==1
    and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
    and ctx.currentHandler=="LEGACY_BOWL_STATE_RESET"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.metrics["legacy.reset.calls"]==1)
 assert(ctx.semanticState.completedDropCount==#drops)
 assert(ctx.semanticState.ignoredPreviousOutputs==#drops-1)
 assert(#ctx.childContexts==#drops)
 for i=1,#drops do
   local row=ctx.semanticState.perDrop[i]
   local child=ctx.childContexts[i]
   assert(row.index==i and row.restartedFromInitial
       and child.commitToken==4 and child.mode=="STAGE_21_PATCH_10"
       and child.status=="PATCH_STIR_RETURNED")
   assert(row.priorOutputIgnored==(i>1))
   for id=1,6 do
     assert(row.inputBowls[id]==tostring(original[id]))
     if i>1 then
       assert(row.previousDropOutput[id]==row.prevOut or
           row.previousDropOutput[id]==ctx.semanticState.perDrop[i-1].outputBowls[id])
     end
   end
 end
 local mismatches=0
 for id=1,6 do
   if B.compare(output[id],correct[id])~=0 then mismatches=mismatches+1 end
 end
 if #drops==1 then assert(mismatches==0)
 else assert(mismatches>=1) end
 resets=resets+#drops-1
 for id=1,6 do assert(original[id]==id*10) end
end
assert(resets>0)
local count=S.resetBowlsSpaghetti({1,2},{stone,stone},original)
local direct=S.legacyResetBowlsProbe({1,2},{stone,stone},original)
for id=1,6 do assert(B.compare(count[id],direct[id])==0) end
assert(select("#",S.resetBowlsSpaghetti({1},{stone},original))==1)
print("PASS Stage 22 synthetic: 7 sekans, premye gout kòrèk, eta gout 2+ pèdi")
