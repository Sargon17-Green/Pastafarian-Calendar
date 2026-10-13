local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local O=require("normative_oracle")
local B=require("bigint")
local changed,matched,allMatches,positions=0,0,0,0
for rank=1,720 do
 local order=O.bowlOrderFromDrop(B.from(rank))
 local all=true
 for id=1,6 do
  local nextId,position=S.nextInDrop46OrderProbe(order,id)
  local expected=O.nextBowlInDrop46Order({orderAtDrop46=order},id)
  assert(nextId==expected and order[position]==id
     and order[(position%6)+1]==nextId,"Order mismatch "..rank..":"..id)
  local old=S.oldNextBowlFixedNameProbe(id)
  if old~=nextId then changed=changed+1;all=false else matched=matched+1 end
  positions=positions+1
 end
 if all then allMatches=allMatches+1 end
end
assert(changed==3456 and matched==864 and allMatches==6 and positions==4320)
for id=1,6 do
 local nextId=S.nextInDrop46OrderProbe({6,5,4,3,2,1},id)
 assert(nextId==(id==1 and 6 or id-1))
end
local badOrders={
 {},{1,2,3,4,5},{1,2,3,4,5,6,7},{1,1,3,4,5,6},
 {0,2,3,4,5,6},{1,2,3,4,5,7},{1,2,3,4,5,2.5},
 {"1",2,3,4,5,6},{true,2,3,4,5,6}
}
for _,wrong in ipairs(badOrders) do
 assert(not pcall(S.nextInDrop46OrderProbe,wrong,1))
end
for _,bad in ipairs({-1,0,7,"1",false,1.5}) do
 assert(not pcall(S.nextInDrop46OrderProbe,{1,2,3,4,5,6},bad))
end
local old={6,5,4,3,2,1}
local n,p=S.nextInDrop46OrderProbe(old,1)
assert(n==6 and p==6 and old[1]==6 and old[6]==1)
print("PASS Stage 25 exhaustive: 720 permutations, 4320 positions, 3456 corrected, 864 matches")
