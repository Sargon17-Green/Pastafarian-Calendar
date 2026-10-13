local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
for _,distance in ipairs({B.pow(2,64),B.pow(10,100),B.pow(10,256)}) do
 for _,step in ipairs({B.neg(distance),distance}) do
  local right,ctx=S.gateQuestionPatchProbe(step)
  local wrong=B.add(F,distance)
  local want=B.add(F,step)
  local core,proof=S.gateQuestionCoreProbe(step,wrong)
  assert(B.compare(right,want)==0 and B.compare(core,want)==0
   and B.compare(ctx.legacyGateQuestionDay,wrong)==0
   and B.compare(proof.correctedDay,want)==0
   and proof.changedNegative==(B.compare(step,0)<0))
 end
end
assert(not pcall(S.gateQuestionCoreProbe,-1,F))
assert(not pcall(S.gateQuestionCoreProbe,1,B.sub(F,1)))
for _,bad in ipairs({false,{},1.5,"not-an-integer"}) do
 assert(not pcall(S.gateQuestionPatchProbe,bad))
end
print("PASS Stage 31 BigInt: three positive/negative huge distances, exact signed repair and invalid proofs")
