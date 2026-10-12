local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local grinds={{3,5,7,11,1},{5,7,11,13,2},{7,11,13,17,3},
 {11,13,17,19,4},{13,17,19,23,5},{17,19,23,29,1},
 {19,23,29,31,2},{23,29,31,37,3},{29,31,37,41,4},
 {31,37,41,43,5},{37,41,43,47,1}}
local cases={{F,F},{F+1,F-1},{F-5,F+9}}
local reads=0
for j,case in ipairs(cases) do
 local c,t=case[1],case[2]
 local counts=O.workCounts(c,t)
 local hidden=O.buildHiddenDrops(counts,O.STONES)
 local stored={}
 local history={}
 for k=1,7 do history[1-k]=hidden[k] end
 for i=1,3 do
  local p1,p3,p7=history[i-1],history[i-3],history[i-7]
  local stone=O.STONES[i]
  local expected=O.SAVE(stone[1]*B.from(counts.action)+stone[2]*B.from(counts.target)+
     stone[3]*B.from(counts.distance)+stone[4]*B.from(counts.connection)+
     stone[5]*B.from(counts.direction)+p1+B.from(3)*p3+B.from(5)*p7+B.from(i))
  for g=1,11 do
   local row=grinds[g]
   expected=O.SAVE(expected*expected+B.from(row[1])*expected+
          B.from(row[2])*p1+B.from(row[3])*p3+B.from(row[4])*p7+stone[row[5]])
  end
  local actual,ctx=S.visibleDropSpaghetti(c,t,i,stored)
  assert(B.compare(actual,expected)==0,"Gout vizib diferan sou ka "..j..", gout "..i)
  assert(ctx.status=="PATCH_VISIBLE_COMPLETE" and ctx.completedGrinds==11)
  assert(ctx.visibleIndex==i and ctx.legacyCallsPreserved==11 and #ctx.trace==11)
  for g=1,11 do
   assert(ctx.trace[g].grind==g and ctx.trace[g].commits==2)
   assert(ctx.trace[g].phase=="PATCH_GRIND_INDEX")
   assert(ctx.trace[g].legacyMissing==(g==11))
   reads=reads+1
  end
  stored[i]=B.from(actual)
  history[i]=expected
 end
end
assert(reads==99)
local badresult,badtrace=S.legacyVisibleDropProbe(F,F,1,{})
assert(badresult==nil and badtrace.missingGrind==11)
assert(not pcall(S.visibleDropSpaghetti,F,F,0,{}))
assert(not pcall(S.visibleDropSpaghetti,F,F,47,{}))
print("PASS gout vizib PATCH 07: 9 gout normatif, 99 grind, route legacy toujou mal")
