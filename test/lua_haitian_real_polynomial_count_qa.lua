-- QA ONLY: independent exact-count DP; no normative calendar API calls.
-- Project PC-BRANCH-LUA-HAITIAN; attested vector run 44948262844/job 136980280634.
-- Lua 5.3 stock interpreter. Base 10^7 limbs; products stay below 2^53.
local ACTUAL={123,92,119,123,121,120,116,116,95,114,120,121,115,116,104,113,121,120,119,117,123,86,123,117,115,108,81,116,120,112,120,116,115,120,123,114,123,89,122,116,115,79,117,123,92,122,82}
local BASE=10000000
local function add(a,b)
  local out,carry={},0
  for i=1,math.max(#a,#b) do
    local v=(a[i] or 0)+(b[i] or 0)+carry
    if v>=BASE then out[i]=v-BASE;carry=1 else out[i]=v;carry=0 end
  end
  if carry>0 then out[#out+1]=carry end
  return out
end
local function mul(a,b)
  local out={}
  for j=1,#a+#b do out[j]=0 end
  for i=1,#a do
    local ai=a[i];local carry=0
    for j=1,#b do
      local k=i+j-1
      local v=out[k]+ai*b[j]+carry
      local q=math.floor(v/BASE)
      out[k]=v-q*BASE;carry=q
    end
    local k=i+#b
    while carry>0 do
      local v=out[k]+carry
      local q=math.floor(v/BASE)
      out[k]=v-q*BASE;carry=q;k=k+1
    end
  end
  while #out>1 and out[#out]==0 do out[#out]=nil end
  return out
end
local function mulsmall(a,z)
  local out,carry={},0
  for i=1,#a do
    local v=a[i]*z+carry
    local q=math.floor(v/BASE)
    out[i]=v-q*BASE;carry=q
  end
  while carry>0 do
    out[#out+1]=carry%BASE;carry=math.floor(carry/BASE)
  end
  return out
end
local function divsmall(a,z)
  local out,rem={},0
  for i=#a,1,-1 do
    local v=rem*BASE+a[i]
    local q=math.floor(v/z)
    out[i]=q;rem=v-q*z
  end
  assert(rem==0,"nonexact binomial update division")
  while #out>1 and out[#out]==0 do out[#out]=nil end
  return out
end
local function dec(a)
  local out=tostring(a[#a])
  for i=#a-1,1,-1 do out=out..string.format("%07d",a[i]) end
  return out
end
local function total(n)
  assert(#n>=1 and #n<=47,"invalid number of labels")
  local p={0}
  for _,v in ipairs(n) do
    assert(type(v)=="number" and v==math.floor(v) and v>=2,"invalid multiplicity")
    p[#p+1]=p[#p]+v
  end
  assert(p[#p]<=6000,"QA_TABLE_CAP, not calendar invalidity")
  return p
end
local function exact_count(n)
  local p=total(n)
  local nextrow={}
  for q=0,p[#p] do nextrow[q]={1} end
  local cells=0
  for a=#n,1,-1 do
    local row={};local z=n[a];local choose={1}
    row[0]=nextrow[z-1]
    for q=1,p[a] do
      -- T(a,q)=T(a,q-1)+C(q+n[a]-2,n[a]-2)*T(a+1,q+n[a]-1).
      choose=divsmall(mulsmall(choose,q+z-2),q)
      row[q]=add(row[q-1],mul(choose,nextrow[q+z-1]))
      cells=cells+1
    end
    nextrow=row
    collectgarbage("collect")
  end
  return dec(nextrow[0]),cells
end
local witnesses={{{2,2},"2"},{{3,2},"3"},{{2,2,2},"5"}}
for _,v in ipairs(witnesses) do
  assert(exact_count(v[1])==v[2],"independently enumerated tiny witness mismatch")
end
print("SMALL_RECURRENCE_WITNESSES=3/3")
local rejects={{},{1},{2,2.5},{6001}}
for _,bad in ipairs(rejects) do
  local ok=pcall(total,bad)
  assert(not ok,"invalid vector accepted")
end
print("VECTOR_GUARDS=4/4")
local mode=(arg and arg[1]) or "small"
assert(mode=="small" or mode=="real","unsupported mode")
if mode=="real" then
  local t=os.clock()
  local val,cells=exact_count(ACTUAL)
  assert(cells==123326,"DP cell accounting mismatch")
  print("ATTESTED_VECTOR=47/5294")
  print("DP_RECURSION_CELLS="..cells)
  print("TOTAL_DECIMAL="..val)
  print("TOTAL_DIGITS="..#val)
  print("LUA_CPU_S="..string.format("%.2f",os.clock()-t))
end
print("QA_ONLY=PASS NORMATIVE_WEAVING_NOT_RUN=1 FULL_DATE_NOT_RUN=1")
