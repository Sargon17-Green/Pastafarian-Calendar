-- Exact independent QA for month-length composition counts and lexicographic ranks.
-- Not wired into the normative oracle, production calendarDateIds or month weaving.
local B=require("bigint")
local M={}
local function isInt(x) return type(x)=="number" and math.type(x)=="integer" end
local function validate(total,m,lo,hi)
  assert(isInt(total) and isInt(m) and isInt(lo) and isInt(hi)
    and total>=0 and total<=5778 and m>=1 and m<=47
    and lo>=1 and lo<=hi and hi<=123, "QA_DOMAIN")
end
local chooseMemo={}
local function choose(n,k)
  if k<0 or k>n then return B.from(0) end
  k=math.min(k,n-k)
  if k==0 then return B.from(1) end
  local key=n..":"..k
  if chooseMemo[key] then return B.from(chooseMemo[key]) end
  local v=B.from(1)
  for i=1,k do
    local q,r=B.divmodFloor(B.mulSmall(v,n-i+1),B.from(i))
    assert(r:isZero(),"QA_NONEXACT_BINOMIAL")
    v=q
  end
  chooseMemo[key]=v
  return B.from(v)
end
local countMemo={}
function M.count(total,m,lo,hi)
  validate(total,m,lo,hi)
  local key=table.concat({total,m,lo,hi},":")
  if countMemo[key] then return B.from(countMemo[key]) end
  if total<m*lo or total>m*hi then return B.from(0) end
  local r=total-m*lo
  local d=math.min(r,m*(hi-lo)-r)
  local width=hi-lo+1
  local answer=B.from(0)
  for j=0,math.min(m,d//width) do
    local term=choose(m,j)*choose(d-j*width+m-1,m-1)
    if j%2==0 then answer=answer+term else answer=answer-term end
  end
  assert(B.compare(answer,0)>=0,"QA_NEGATIVE_COUNT")
  countMemo[key]=answer
  return B.from(answer)
end
function M.unrank1(total,m,lo,hi,rank1)
  validate(total,m,lo,hi)
  local rank=B.from(rank1)
  assert(B.compare(rank,1)>=0 and B.compare(rank,M.count(total,m,lo,hi))<=0,"QA_RANK")
  local out,remaining={},total
  for pos=1,m do
    local left=m-pos
    local low=math.max(lo,remaining-left*hi)
    local high=math.min(hi,remaining-left*lo)
    local chosen
    for x=low,high do
      local block=left==0 and B.from(x==remaining and 1 or 0)
                  or M.count(remaining-x,left,lo,hi)
      if B.compare(rank,block)>0 then rank=rank-block
      else chosen=x;break end
    end
    assert(chosen~=nil,"QA_UNRANK_NO_BLOCK")
    out[#out+1]=chosen
    remaining=remaining-chosen
  end
  assert(remaining==0 and B.compare(rank,1)==0,"QA_UNRANK_REMAINDER")
  return out
end
return M
