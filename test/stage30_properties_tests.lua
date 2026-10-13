local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
for n=1,150 do
 local pos=S.legacyGateQuestionProbe(n)
 local neg=S.legacyGateQuestionProbe(-n)
 local wantPositive=B.add(F,n)
 local wantNegative=B.sub(F,n)
 assert(B.compare(pos,wantPositive)==0
  and B.compare(neg,pos)==0
  and B.compare(neg,wantNegative)~=0
  and B.compare(B.sub(neg,wantNegative),B.mulSmall(B.from(n),2))==0)
end
for _,dist in ipairs({B.pow(10,40),B.pow(10,90),B.pow(10,150)}) do
 local minus=B.neg(dist)
 local actual,ctx=S.legacyGateQuestionProbe(minus)
 local wanted=B.sub(F,dist)
 assert(B.compare(actual,B.add(F,dist))==0
  and B.compare(B.sub(actual,wanted),B.mulSmall(dist,2))==0
  and ctx.semanticState.signedStepDecimal==tostring(minus)
  and ctx.pendingSemanticState==nil)
end
for _,bad in ipairs({false,{},1.5,"not-a-day"}) do
 assert(not pcall(S.legacyGateQuestionProbe,bad))
end
assert(not pcall(S.oldGateQuestionDayProbe,-1))
print("PASS Stage 30 properties: 300 signed requests, 3 huge BigInt sign differences, invalid inputs")
