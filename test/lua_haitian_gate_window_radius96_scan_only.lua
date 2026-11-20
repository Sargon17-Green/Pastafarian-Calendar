-- PROJECT_ID=PC-BRANCH-LUA-HAITIAN. Bounded radius96 gate-only scan.
-- No year5000, full-date conversion, or month composition is invoked.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local O=require("normative_oracle")
local MIN,MAX,CORE_MIN,CORE_MAX=-96,96,-64,64
local MAX_GAP_EVALS,MAX_CPU,MAX_HEAP_KIB=200,110,128*1024
local begun,evals=os.clock(),0
local function budget()
  if os.clock()-begun>MAX_CPU then error("ABORT_CPU",0) end
  if collectgarbage("count")>MAX_HEAP_KIB then error("ABORT_HEAP",0) end
end
local positive,negative=O.positiveGateGap,O.negativeGateGap
O.positiveGateGap=function(n)
  evals=evals+1
  if evals>MAX_GAP_EVALS then error("ABORT_GAP_CAP",0) end
  budget()
  return positive(n)
end
O.negativeGateGap=function(n)
  evals=evals+1
  if evals>MAX_GAP_EVALS then error("ABORT_GAP_CAP",0) end
  budget()
  return negative(n)
end
local gates,seed,count={},{},0
local f=assert(io.open(root.."/test/lua_haitian_gate_window_radius64_v5_1_seed.tsv","r"))
for line in f:lines() do
  if line~="" and line:sub(1,1)~="#" then
    local a,b=line:match("^(-?%d+)%s+(-?%d+)$")
    assert(a and b,"malformed seed row")
    local i,d=tonumber(a),tonumber(b)
    assert(i>=CORE_MIN and i<=CORE_MAX and seed[i]==nil,"bad seed index")
    gates[i]=d; seed[i]=d; count=count+1
  end
end
f:close()
assert(count==129 and seed[0]==O.FOUNDATION_DAY,"seed cardinality/foundation")
for i=CORE_MIN,CORE_MAX do
  assert(seed[i]~=nil,"missing seed row")
  if i>CORE_MIN then
    local delta=seed[i]-seed[i-1]
    assert(delta>=O.GATE_GAP_MIN and delta<=O.GATE_GAP_MAX,"bad seed gap")
  end
end
O.resetGateCache()
debug.sethook(budget,"",10000)
for i=CORE_MIN-1,MIN,-1 do
  budget()
  gates[i]=gates[i+1]-O.negativeGateGap(-i)
end
for i=CORE_MAX+1,MAX do
  budget()
  gates[i]=gates[i-1]+O.positiveGateGap(i)
end
assert(evals==64,"exactly 64 new outer gap calls required")
print("GATE_CORE_SEED: -64/64")
print("GATE_CORE_VERIFIED_RUN: 44800290037")
print("GATE_CORE_NATIVE_JOB: 136510368350")
print("GATE_CORE_ARTIFACT_SHA256: e96a51238c81a201a88798c9541909082632fda2422931623b0bf18ea0a6203e")
print("GATE_CORE_SEED_BLOB: 95e77bc49a4c9e944bbac72b744ae0b3628043e5")
for i=MIN,MAX do
  budget()
  if i>MIN then
    local delta=gates[i]-gates[i-1]
    assert(delta>=O.GATE_GAP_MIN and delta<=O.GATE_GAP_MAX,"bad output gap")
  end
  print("GATE_INDEX|index="..i.."|day="..gates[i])
end
local smallest,short=nil,0
for i=MIN,MAX-6 do
  budget()
  local len=gates[i+6]-gates[i]
  if smallest==nil or len<smallest then smallest=len end
  if len>=O.YEAR_MIN_DAYS and len<=16*123 then short=short+1 end
  print("GATE_WINDOW|i="..i.."|j="..(i+6).."|first="..gates[i].."|last="..gates[i+6].."|length="..len)
end
debug.sethook()
print("GATE_WINDOW_SCAN: -96/96")
print("GATE_WINDOWS_TOTAL: 187")
print("MIN_SIX_GAP_WINDOW: "..smallest)
print("SHORT_SIX_GAP_WINDOWS: "..short)
print("GATE_GAP_EVALUATIONS: "..evals)
print("SCAN_ONLY: YES")
print("COMPOSITION_NOT_INVOKED: YES")
print("SCOPE=RADIUS96_GATE_WINDOW_SCAN_ONLY; YEAR5000=NOT_RUN; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN")
