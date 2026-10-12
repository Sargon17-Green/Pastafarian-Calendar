local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local changed,matched=0,0
local allMatches=0
for rank=1,720 do
 local order=O.bowlOrderFromDrop(B.from(rank))
 local oneMatch=true
 for id=1,6 do
  local fixed=S.oldNextBowlFixedNameProbe(id)
  local correct=O.nextBowlInDrop46Order({orderAtDrop46=order},id)
  assert(fixed==id%6+1,"Non siklik istorik la chanje")
  if fixed==correct then matched=matched+1
  else changed=changed+1;oneMatch=false end
 end
 if oneMatch then allMatches=allMatches+1 end
end
assert(changed==3456 and matched==864 and allMatches==6,
   "720 permutation yo pa bay kantite diferans istorik egzije yo")
local rank1=O.bowlOrderFromDrop(B.from(1))
for id=1,6 do assert(S.oldNextBowlFixedNameProbe(id)
   ==O.nextBowlInDrop46Order({orderAtDrop46=rank1},id)) end
local rank720=O.bowlOrderFromDrop(B.from(720))
for id=1,6 do assert(S.oldNextBowlFixedNameProbe(id)
   ~=O.nextBowlInDrop46Order({orderAtDrop46=rank720},id)) end
for _,x in ipairs({0,-1,7,1.5,"2",{},false}) do
 assert(not pcall(S.oldNextBowlFixedNameProbe,x))
end
print("PASS Stage 24 exhaustive: 720 lòd, 4320 vwazen, 3456 move, 864 matche")
