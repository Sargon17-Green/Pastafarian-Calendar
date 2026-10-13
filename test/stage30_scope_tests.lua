local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_gate_question_adapter.lua")
local facade=read("src/spaghetti.lua")
assert(old:find("local distance=B.abs(step)",1,true))
assert(old:find("return B.add(FOUNDATION_DAY_OLD,nonnegative)",1,true))
assert(old:find('manager.dispatcher:register("LEGACY_SIGNED_GATE_STEP"',1,true))
assert(old:find('manager.dispatcher:register("LEGACY_ABSOLUTE_GATE_QUERY"',1,true))
assert(facade:find("function S.legacyGateQuestionProbe(",1,true))
assert(facade:find("function S.gateQuestionDaySpaghetti(",1,true))
for _,s in ipairs({old,facade}) do
 for _,bad in ipairs({"normative_oracle","gateQuestionPatch","correctNegativeGate","postStir12","PATCH_15_NEGATIVE_GATE"}) do
  assert(not s:find(bad,1,true),"Stage 31+ entèdi: "..bad)
 end
end
print("PASS Stage 30 scope: original negative sign-losing query, two commits and no PATCH 15")
