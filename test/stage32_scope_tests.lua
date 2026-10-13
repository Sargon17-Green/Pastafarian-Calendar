local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_gate_gap.lua")
local facade=read("src/spaghetti.lua")
assert(old:find("OLD_OFFSET=B.from(42)",1,true)
 and old:find("RANK_COUNT=B.from(922)",1,true)
 and old:find("GateQuestion.execute(step)",1,true)
 and old:find("ShortChoice.execute(first,direction,RANK_COUNT)",1,true)
 and old:find('manager.dispatcher:register("LEGACY_GATE_GAP_PLUS_ONE"',1,true)
 and old:find('B.compare(wrong,B.add(OLD_OFFSET,rank))',1,true))
assert(facade:find("function S.legacyGateGapProbe(",1,true)
 and facade:find("function S.gateGapSpaghetti(",1,true))
for _,code in ipairs({old,facade}) do
 assert(not code:find("normative_oracle",1,true)
 and not code:find("postStir12",1,true))
end
assert(not old:find('require("gate_gap_patch")',1,true))
print("PASS Stage 32 scope: authentic PATCH 13/15, historical 42+rank, no PATCH 16")
