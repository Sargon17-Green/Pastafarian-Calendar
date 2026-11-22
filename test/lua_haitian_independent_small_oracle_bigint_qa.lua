-- QA ONLY. Independent exhaustive oracle and decimal BigInt feasibility for Lua 5.3.
-- Project: PC-BRANCH-LUA-HAITIAN. No production API or calendar date invocation.
-- Run: lua5.3 test/lua_haitian_independent_small_oracle_bigint_qa.lua
-- Optional: LUA_HAITIAN_QA_MAX_LENGTH=12 (range 8..12).
local BASE = 10000
local function trim(a)
  while #a > 1 and a[#a] == 0 do a[#a] = nil end
  return a
end
local function clone(a)
  local r = {}
  for i=1,#a do r[i]=a[i] end
  return r
end
local function fromdec(s)
  assert(type(s)=="string" and s:match("^%d+$"), "decimal string required")
  local a={}
  for i=#s,1,-4 do a[#a+1]=tonumber(s:sub(math.max(i-3,1),i)) end
  return trim(a)
end
local function todec(a)
  local s=tostring(a[#a])
  for i=#a-1,1,-1 do s=s..string.format("%04d", a[i]) end
  return s
end
local function cmp(a,b)
  if #a~=#b then return #a<#b and -1 or 1 end
  for i=#a,1,-1 do
    if a[i]~=b[i] then return a[i]<b[i] and -1 or 1 end
  end
  return 0
end
local function add(a,b)
  local r,carry={},0
  for i=1,math.max(#a,#b) do
    local x=(a[i] or 0)+(b[i] or 0)+carry
    r[i]=x%BASE; carry=math.floor(x/BASE)
  end
  if carry>0 then r[#r+1]=carry end
  return trim(r)
end
local function sub(a,b)
  assert(cmp(a,b)>=0,"negative arbitrary-precision subtraction")
  local r,borrow={},0
  for i=1,#a do
    local x=a[i]-(b[i] or 0)-borrow
    if x<0 then x=x+BASE; borrow=1 else borrow=0 end
    r[i]=x
  end
  assert(borrow==0)
  return trim(r)
end
local function mulsmall(a,n)
  assert(type(n)=="number" and n>=0 and n<BASE and n==math.floor(n))
  local r,carry={},0
  for i=1,#a do
    local x=a[i]*n+carry
    r[i]=x%BASE; carry=math.floor(x/BASE)
  end
  if carry>0 then r[#r+1]=carry end
  return trim(r)
end
local function mul(a,b)
  local r={}
  for i=1,#a+#b+1 do r[i]=0 end
  for i=1,#a do
    local carry=0
    for j=1,#b do
      local k=i+j-1
      local x=r[k]+a[i]*b[j]+carry
      r[k]=x%BASE; carry=math.floor(x/BASE)
    end
    local k=i+#b
    while carry>0 do
      local x=r[k]+carry
      r[k]=x%BASE; carry=math.floor(x/BASE); k=k+1
    end
  end
  return trim(r)
end
local ZERO,ONE=fromdec("0"),fromdec("1")
local function shift_base(a,digit)
  if #a==1 and a[1]==0 then return {digit} end
  local out={digit}
  for j=1,#a do out[j+1]=a[j] end
  return trim(out)
end
local function divmod(a,b)
  assert(cmp(b,ZERO)>0,"division by zero")
  local q,rem={},ZERO
  for i=#a,1,-1 do
    rem=shift_base(rem,a[i])
    local lo,hi=0,BASE-1
    while lo<hi do
      local mid=math.floor((lo+hi+1)/2)
      if cmp(mulsmall(b,mid),rem)<=0 then lo=mid else hi=mid-1 end
    end
    q[i]=lo
    if lo>0 then rem=sub(rem,mulsmall(b,lo)) end
  end
  return trim(q),trim(rem)
end
local function advance(rem,initial,opened,closed,j)
  local v=rem[j]
  if not v or v==0 then return nil end
  if v==initial[j] and j~=opened+1 then return nil end
  if v==1 and j~=closed+1 then return nil end
  local out=clone(rem)
  out[j]=v-1
  if v==initial[j] then opened=opened+1 end
  if v==1 then closed=closed+1 end
  return out,opened,closed
end
local function counter(initial)
  local memo={}
  local function count(rem,opened,closed)
    local key=table.concat(rem,",")..":"..opened..":"..closed
    if memo[key] then return memo[key] end
    local pending=0
    for j=1,#rem do pending=pending+rem[j] end
    if pending==0 then
      local v=(opened==#initial and closed==#initial) and ONE or ZERO
      memo[key]=v; return v
    end
    local total=ZERO
    for j=1,#rem do
      local r,o,c=advance(rem,initial,opened,closed,j)
      if r then total=add(total,count(r,o,c)) end
    end
    memo[key]=total
    return total
  end
  local function prefix(p)
    local rem=clone(initial)
    local opened,closed=0,0
    for i=1,#p do
      local j=tonumber(p:sub(i,i))
      if not j or j<0 or j>=#initial then return ZERO end
      local r,o,c=advance(rem,initial,opened,closed,j+1)
      if not r then return ZERO end
      rem,opened,closed=r,o,c
    end
    return count(rem,opened,closed)
  end
  local function unrank(rank)
    if cmp(rank,ZERO)<=0 then return nil end
    local rem=clone(initial)
    local opened,closed=0,0
    if cmp(rank,count(rem,opened,closed))>0 then return nil end
    local len=0
    for _,v in ipairs(initial) do len=len+v end
    local word={}
    for pos=1,len do
      local found=false
      for j=1,#initial do
        local r,o,c=advance(rem,initial,opened,closed,j)
        if r then
          local block=count(r,o,c)
          if cmp(rank,block)<=0 then
            word[#word+1]=tostring(j-1)
            rem,opened,closed=r,o,c
            found=true; break
          else rank=sub(rank,block) end
        end
      end
      assert(found,"positive block not found at "..pos)
    end
    assert(cmp(rank,ONE)==0,"terminal rank mismatch")
    return table.concat(word)
  end
  return prefix,unrank,function() local n=0;for _ in pairs(memo) do n=n+1 end;return n end
end
local function oracle(initial)
  -- Different algorithm from the memoized legal-transition counter:
  -- generate ALL distinct multiset permutations without first/last pruning;
  -- accept only after independent first-/last-position scans on the complete word.
  local rem=clone(initial)
  local len=0
  for _,v in ipairs(initial) do len=len+v end
  local words,word={},{}
  local function visit(pos)
    if pos>len then
      local first,last={},{}
      for k=1,len do
        local j=word[k]
        if not first[j] then first[j]=k end
        last[j]=k
      end
      for j=2,#initial do
        if not (first[j-1]<first[j] and last[j-1]<last[j]) then return end
      end
      local out={}
      for k=1,len do out[k]=tostring(word[k]-1) end
      words[#words+1]=table.concat(out)
      return
    end
    for j=1,#initial do
      if rem[j]>0 then
        rem[j]=rem[j]-1; word[pos]=j
        visit(pos+1)
        rem[j]=rem[j]+1
      end
    end
  end
  visit(1)
  return words  -- sorted lexicographically by generation order
end
local function check(cond,msg)
  if not cond then error(msg,2) end
end
local function bigint_tests()
  local literals={
    "0","1","9","9999","10000","10001","9007199254740991",
    "9007199254740992","9007199254740993","9223372036854775807",
    "9223372036854775808","9223372036854775809",
    "18446744073709551617","1234567890123456789012345678901234567890"
  }
  for _,s in ipairs(literals) do
    check(todec(fromdec(s))==s,"BigInt decimal roundtrip "..s)
  end
  for i=2,#literals do
    local a,b=fromdec(literals[i]),fromdec(literals[i-1])
    check(cmp(a,b)>0,"BigInt compare "..i)
    check(cmp(sub(a,b),ZERO)>=0,"BigInt subtract "..i)
    check(cmp(add(sub(a,b),b),a)==0,"BigInt add/sub "..i)
  end
  local fixtures={
    {"9007199254740993","2","4503599627370496","1"},
    {"9223372036854775808","4294967296","2147483648","0"},
    {"18446744073709551617","4294967296","4294967296","1"},
    {"1234567890123456789012345678901234567890","9876543210","124999998873437499901582031239","9681230700"}
  }
  -- Fixed decimal witnesses plus independent reconstruction/remainder checks.
  for i,f in ipairs(fixtures) do
    local a,b=fromdec(f[1]),fromdec(f[2])
    local q,r=divmod(a,b)
    check(todec(q)==f[3] and todec(r)==f[4],"fixed divmod witness "..i)
    check(cmp(r,b)<0,"divmod remainder range "..i)
    check(cmp(add(mul(q,b),r),a)==0,"divmod reconstruction "..i)
  end
  check(cmp(mul(fromdec("999999999999999999"),fromdec("999999999999999999")),fromdec("999999999999999998000000000000000001"))==0,"multiplication witness")
  local ok=pcall(function() divmod(ONE,ZERO) end)
  check(not ok,"division by zero must reject")
  ok=pcall(function() sub(ZERO,ONE) end)
  check(not ok,"negative subtraction must reject")
  print("BIGINT_ROUNDTRIPS="..#literals.." BIGINT_DIVMOD="..#fixtures.." BIGINT_BOUNDARY_2P53_2P63=PASS")
end
local function verify_vector(initial,stats)
  local words=oracle(initial)
  local prefix,unrank,states=counter(initial)
  local all={}
  for _,w in ipairs(words) do
    for i=0,#w do
      local p=w:sub(1,i)
      all[p]=(all[p] or 0)+1
    end
  end
  check(#words>0,"no valid witness")
  for p,n in pairs(all) do
    check(cmp(prefix(p),fromdec(tostring(n)))==0,"prefix mismatch vector="..table.concat(initial,",").." p="..p)
    stats.prefix=stats.prefix+1
  end
  check(cmp(prefix(""),fromdec(tostring(#words)))==0,"total count mismatch")
  local mid=math.floor((#words+1)/2)
  local candidates={1,mid,#words}
  for _,k in ipairs(candidates) do
    check(unrank(fromdec(tostring(k)))==words[k],"lex rank mismatch k="..k)
    stats.unrank=stats.unrank+1
  end
  check(unrank(ZERO)==nil and unrank(fromdec(tostring(#words+1)))==nil,"rank boundary rejection")
  check(cmp(prefix("X"),ZERO)==0,"invalid prefix rejection")
  stats.vector=stats.vector+1
  stats.words=stats.words+#words
  stats.dp_states=stats.dp_states+states()
end
local maxlen=tonumber(os.getenv("LUA_HAITIAN_QA_MAX_LENGTH") or "12")
check(maxlen and maxlen==math.floor(maxlen) and maxlen>=8 and maxlen<=12,"maxlen must be integer 8..12")
check(_VERSION=="Lua 5.3" or _VERSION=="Lua 5.4","Lua 5.3-compatible interpreter required; got "..tostring(_VERSION))
bigint_tests()
local stats={vector=0,words=0,prefix=0,unrank=0,dp_states=0}
local function domain(m,v,s)
  if #v==m then
    if s<=maxlen then verify_vector(v,stats) end
    return
  end
  for n=2,maxlen-s-2*(m-#v-1) do
    v[#v+1]=n; domain(m,v,s+n); v[#v]=nil
  end
end
for m=1,4 do domain(m,{},0) end
-- Hard anchors are independently listed in the proof contract; no Python fixture imported.
local anchors={
  {counts={2,2},words={"0011","0101"}},
  {counts={3,2},words={"00011","00101","01001"}},
  {counts={2,2,2},words={"001122","001212","010122","010212","012012"}}
}
for _,a in ipairs(anchors) do
  local observed=oracle(a.counts)
  check(table.concat(observed,"|")==table.concat(a.words,"|"),"hard anchor mismatch")
end
print(string.format("SMALL_ORACLE=PASS vectors=%d words=%d prefixes=%d unrank=%d memo_states=%d max_m=4 max_L=%d",stats.vector,stats.words,stats.prefix,stats.unrank,stats.dp_states,maxlen))
print("QA_ONLY=PASS NORMATIVE_DATE_NOT_INVOKED=1 REAL_VECTOR_NOT_TESTED=1")
