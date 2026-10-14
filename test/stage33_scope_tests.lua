local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_gate_gap.lua")
local patch=read("src/gate_gap_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find('manager.dispatcher:register("LEGACY_GATE_GAP_PLUS_ONE"',1,true))
assert(legacy:find('local wrong=Legacy.oldGateGapFromRank(rank)',1,true))
assert(not legacy:find('require("gate_gap_patch")',1,true))
assert(patch:find('local oldGap,ctx=Old.execute(step,seed,direction)',1,true))
assert(patch:find('ctx.legacyGapSemanticState=clone(ctx.semanticState)',1,true))
assert(patch:find('manager.dispatcher:register("GATE_GAP_OFFSET_PATCH"',1,true))
assert(patch:find('local repaired=B.sub(old,ONE)',1,true))
assert(patch:find('B.add(NEW_OFFSET,selected)',1,true))
assert(facade:find('function S.legacyGateGapProbe(',1,true))
assert(facade:find('local corrected=GateGapPatch.execute(signedStep,first,direction)',1,true))
for _,src in ipairs({legacy,patch,facade}) do
 assert(not src:find('normative_oracle',1,true)
  and not src:find('postStir12',1,true)
  and not src:find('calendarDateOracle',1,true))
end
print("PASS Stage 33 scope: four authentic legacy commits then fifth gate gap correction; no future gates")
