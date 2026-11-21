-- Exact independent Lua QA; run with source BigInt, not a floating-point mock.
local root=(arg and arg[1]) or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local M=require("lua_haitian_exact_month_composition_qa")
local n=0
local function check(ok,msg) assert(ok,"QA_EXACT_MONTHS_"..msg);n=n+1 end
local function eq(x,v) return B.compare(x,v)==0 end
local function enumerate(m)
  local out,word={},{}
  local function visit(sum)
    if #word==m then
      out[sum]=out[sum] or {}
      out[sum][#out[sum]+1]={table.unpack(word)}
      return
    end
    for x=4,7 do
      word[#word+1]=x;visit(sum+x);word[#word]=nil
    end
  end
  visit(0)
  return out
end
for m=1,4 do
  local bySum=enumerate(m)
  for total=0,32 do
    local rows=bySum[total] or {}
    check(eq(M.count(total,m,4,7),#rows),"COUNT_"..m.."_"..total)
    for rank,expected in ipairs(rows) do
      local got=M.unrank1(total,m,4,7,rank)
      local same=#got==#expected
      for i=1,#got do if got[i]~=expected[i] then same=false end end
      check(same,"RANK_"..m.."_"..total.."_"..rank)
    end
  end
end
-- Fixed independent math.comb inclusion-exclusion receipts for L=5294.
local counts={
 [44]="2682068132845942488417085641349793384000",
 [45]="11681860485174984854736012952425411368978900826701550",
 [46]="2281207130421875155856193577687513204527478048375575910956320",
 [47]="6612803766405712700804301296246018610662237465130696779907193472680"
}
for m=44,47 do check(tostring(M.count(5294,m,4,123))==counts[m],"REAL_"..m) end
check(eq(M.count(5294,43,4,123),0),"43_INFEASIBLE")
check(eq(M.count(5778,47,4,123),18424),"MAX_YEAR")
check(eq(M.count(252,3,4,123),7021),"MIN_YEAR")
local first=M.unrank1(5294,44,4,123,1)
local last=M.unrank1(5294,44,4,123,counts[44])
local function valid(a)
  local sum=0
  if #a~=44 then return false end
  for _,x in ipairs(a) do
    if x<4 or x>123 then return false end
    sum=sum+x
  end
  return sum==5294
end
check(valid(first),"FIRST")
check(valid(last),"LAST")
check(first[1]~=last[1],"EXTREMES_DIFFER")
check(not pcall(M.unrank1,5294,44,4,123,0),"ZERO_RANK")
check(not pcall(M.unrank1,5294,44,4,123,B.from(counts[44])+1),"HIGH_RANK")
check(not pcall(M.count,5294,48,4,123),"MONTH_MAX")
check(not pcall(M.count,5294,44,4,124),"DAY_MAX")
print(("LUA_HAITIAN_EXACT_MONTHS_PASS: %d/%d"):format(n,n))
print("MONTHS_5294=44..47; QA_RESOURCE_CAP_16_NOT_NORMATIVE")
print("PRODUCTION=UNCHANGED; WEAVING=NOT_RUN; FULL_DATE=NOT_RUN")
