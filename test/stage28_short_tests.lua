local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local total=0
for _,n in ipairs({1,2,3,5,7,11,97}) do
 for _,first in ipairs({B.from(1),B.from(2),B.sub(M,1),B.from(M)}) do
  for _,step in ipairs({-1,1}) do
    local result,ctx=S.legacyShortOnlyChoiceProbe(first,step,n)
    local oracle=O.chooseRankShort({first=first,directionStep=step},n)
    assert(B.compare(result,oracle)==0
      and ctx.mode=="STAGE_27_PATCH_13"
      and ctx.status=="PATCH_SHORT_CHOICE_COMPLETE"
      and ctx.commitToken==3 and #ctx.branchTrace==3)
    local public=S.choiceSpaghetti(first,step,n)
    assert(B.compare(public,oracle)==0)
    total=total+1
  end
 end
end
for _,n in ipairs({B.from(M),B.sub(M,1),B.add(B.floorDiv(M,2),1)}) do
 local got,ctx=S.legacyShortOnlyChoiceProbe(1,-1,n)
 assert(B.compare(got,1)==0 and ctx.commitToken==3)
 total=total+1
end
assert(total==59)
print("PASS Stage 28 short path: "..total.." correct PATCH 13 choices remain unchanged")
