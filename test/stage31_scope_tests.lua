local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"));local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_gate_question_adapter.lua")
local patch=read("src/gate_question_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find("local distance=B.abs(step)",1,true))
assert(legacy:find("return B.add(FOUNDATION_DAY_OLD,nonnegative)",1,true))
assert(not legacy:find("SIGNED_GATE_QUESTION_PATCH",1,true))
assert(patch:find('local wrong,ctx=Old.execute(step)',1,true))
assert(patch:find('local distance,isNegative=validate(wrong,ctx,step)',1,true))
assert(patch:find('ctx.legacyGateSemanticState=clone(ctx.semanticState)',1,true))
assert(patch:find('manager.dispatcher:register("SIGNED_GATE_QUESTION_PATCH"',1,true))
assert(patch:find('corrected=B.sub(old,B.mulSmall(distance,2))',1,true))
assert(patch:find('B.compare(corrected,B.add(F,step))',1,true))
assert(facade:find('function S.legacyGateQuestionProbe(',1,true))
assert(facade:find('local right=GateQuestionPatch.execute(signedStep)',1,true))
for _,s in ipairs({legacy,patch,facade}) do
 for _,forbidden in ipairs({"normative_oracle","postStir12","calendarDateOracle"}) do
  assert(not s:find(forbidden,1,true),"Oracle/final entèdi: "..forbidden)
 end
end
print("PASS Stage 31 scope: Stage 30 legacy preserved, third correction commit, no future final integration")
