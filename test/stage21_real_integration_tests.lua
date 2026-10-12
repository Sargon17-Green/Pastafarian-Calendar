local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local cases={{F,F},{F+1,F-1},{F-5,F+9}}
local checked=0
for _,pair in ipairs(cases) do
 local c,t=pair[1],pair[2]
 local old=O.initialBowls(O.workCounts(c,t))
 local drops={}
 for i=1,3 do
   local drop,visible=S.visibleDropSpaghetti(c,t,i,drops)
   assert(visible.status=="PATCH_VISIBLE_COMPLETE" and visible.completedGrinds==11)
   local rock=O.STONES[i]
   local stoneRow={w=rock[1],b=rock[2],s=rock[3],m=rock[4],r=rock[5]}
   local corrected,ctx=S.stirPatchProbe(drop,i,old,stoneRow)
   local order=O.bowlOrderFromDrop(drop)
   local pours={}
   for p=1,3 do pours[p]=O.SAVE(drop*drop+rock[p]*old[order[p]]
                          +B.from(({3,5,7})[p]*i)) end
   for p=1,6 do
     local id=order[p]
     local prev=order[(p+4)%6+1]
     local nxt=order[p%6+1]
     local total=old[id]+B.from(2)*old[prev]+B.from(3)*old[nxt]
        +(p<=3 and pours[p] or B.from(0))+drop+rock[({1,2,3,4,5,1})[p]]
     local expected=O.SAVE(total*total+B.from(5)*old[prev]*old[nxt]+B.from(i*p))
     assert(B.compare(corrected[id],expected)==0)
     checked=checked+1
   end
   assert(ctx.commitToken==4 and ctx.status=="PATCH_STIR_RETURNED")
   drops[i]=B.from(drop)
 end
end
assert(checked==54)
local corrected,ctx=S.openingStirPatchProbe(F,F)
assert(ctx.mode=="STAGE_21_PATCH_10" and ctx.metrics["patch10.opening.probes"]==1
   and ctx.visibleContext.status=="PATCH_VISIBLE_COMPLETE")
local normal=S.openingStirSpaghetti(F,F)
for id=1,6 do assert(B.compare(normal[id],corrected[id])==0) end
local historical=S.openingStirProbe(F,F)
local mismatch=0
for id=1,6 do if B.compare(normal[id],historical[id])~=0 then mismatch=mismatch+1 end end
assert(mismatch>=1)
print("PASS Stage 21 real: 9 gout, 54 bòl korije, premye brase piblik vèt")
