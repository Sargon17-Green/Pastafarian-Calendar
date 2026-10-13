local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local cases={B.from(1),B.from(2),B.from(5),B.sub(M,2),B.sub(M,1),B.from(M)}
local increments={B.from(0),B.from(1),B.from(2),B.from(5),
 B.sub(M,1),B.from(M),B.add(M,1),B.mul(M,B.from(3)),
 B.from("9"..string.rep("9",180))}
local tested=0
for _,first in ipairs(cases) do
 for _,direction in ipairs({-1,1}) do
  for _,k in ipairs(increments) do
   local actual=S.answerAtSpaghetti(first,direction,k)
   local expected=O.answerAt({first=first,directionStep=direction},k)
   assert(B.compare(actual,expected)==0,
     "Kouran SAVE pa matche oracle pou "..tostring(first).."/"..direction)
   assert(B.compare(actual,1)>=0 and B.compare(actual,M)<=0)
   tested=tested+1
  end
 end
end
for k=0,300 do
 local first=B.add(B.from(1),B.mod(B.from(k*k*17+k*127+3),M))
 local direction=k%2==0 and 1 or -1
 local actual=S.answerAtSpaghetti(first,direction,k*13)
 local expected=O.answerAt({first=first,directionStep=direction},k*13)
 assert(B.compare(actual,expected)==0)
 tested=tested+1
end
for _,wrong in ipairs({0,-1,B.add(M,1),"-2","0","",false,{}}) do
 assert(not pcall(S.answerAtSpaghetti,wrong,1,0))
end
for _,badStep in ipairs({0,2,-2,false,"1",1.5}) do
 assert(not pcall(S.answerAtSpaghetti,1,badStep,0))
end
for _,badK in ipairs({-1,"-3",true,{},1.5}) do
 assert(not pcall(S.answerAtSpaghetti,1,1,badK))
end
print("PASS Stage 26 stream: "..tested.." oracle answers, wraps, negative directions, huge k")
