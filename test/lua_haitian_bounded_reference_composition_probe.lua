-- PC-BRANCH-LUA-HAITIAN: read-only, abortable reference-composition probe.
-- Independent guard implementation of the two normative recurrences.
-- Not a production calendar calculation and not an F0 full-year run.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local DEFAULT={memo=20000,heapKiB=128*1024,cpu=60}
local function budget(overrides)
    overrides=overrides or {}
    local cap={}
    for k,v in pairs(DEFAULT) do cap[k]=math.min(v,overrides[k] or v) end
    local start=os.clock()
    local state={entries=0,peakHeapKiB=0,calls=0}
    function state.check()
        state.calls=state.calls+1
        local heap=collectgarbage("count")
        if heap>state.peakHeapKiB then state.peakHeapKiB=heap end
        if heap>cap.heapKiB then error("ABORT_HEAP",0) end
        if os.clock()-start>cap.cpu then error("ABORT_CPU",0) end
    end
    function state.reserve()
        state.check()
        if state.entries>=cap.memo then error("ABORT_MEMO",0) end
        state.entries=state.entries+1
    end
    function state.finish()
        state.check()
        return state
    end
    return state
end
local function composition(total,slots,lo,hi,limits)
    assert(math.type(total)=="integer" and total>=0)
    assert(math.type(slots)=="integer" and slots>=1 and slots<=47)
    assert(math.type(lo)=="integer" and math.type(hi)=="integer" and lo>=1 and hi>=lo)
    local b=budget(limits)
    local memo={}
    local function count(rem,k)
        b.check()
        if k==0 then return B.from(rem==0 and 1 or 0) end
        if rem<k*lo or rem>k*hi then return B.from(0) end
        local key=rem..":"..k
        if memo[key]~=nil then return memo[key] end
        b.reserve()
        memo[key]=B.from(0)
        local sum=B.from(0)
        for x=lo,hi do
            b.check()
            sum=sum+count(rem-x,k-1)
        end
        memo[key]=sum
        return sum
    end
    local result=count(total,slots)
    return result,b.finish()
end
local function weave(lengths,limits)
    assert(type(lengths)=="table" and #lengths>=1 and #lengths<=47)
    for i=1,#lengths do
        assert(math.type(lengths[i])=="integer" and lengths[i]>=1 and lengths[i]<=123)
    end
    local b=budget(limits)
    local m=#lengths
    local memo={}
    local function copy(t)
        local o={}
        for i=1,#t do o[i]=t[i] end
        return o
    end
    local function count(remaining,opened,closed)
        b.check()
        local done=true
        for i=1,m do if remaining[i]~=0 then done=false break end end
        if done then return B.from(1) end
        local key=table.concat(remaining,",").."|"..opened.."|"..closed
        if memo[key]~=nil then return memo[key] end
        b.reserve()
        memo[key]=B.from(0)
        local sum=B.from(0)
        for j=1,m do
            b.check()
            if remaining[j]>0 then
                local wasOpened=remaining[j]<lengths[j]
                local willClose=remaining[j]==1
                if (wasOpened or j==opened+1) and (not willClose or j==closed+1) then
                    local nxt=copy(remaining)
                    local newOpened=opened
                    if not wasOpened then newOpened=j end
                    nxt[j]=nxt[j]-1
                    local newClosed=closed
                    if nxt[j]==0 then newClosed=j end
                    sum=sum+count(nxt,newOpened,newClosed)
                end
            end
        end
        memo[key]=sum
        return sum
    end
    local result=count(copy(lengths),0,0)
    return result,b.finish()
end
local tests=0
local records={}
local function test(name,fn)
    local stats=fn()
    tests=tests+1
    if stats then
        assert(stats.entries<=DEFAULT.memo)
        assert(stats.peakHeapKiB<=DEFAULT.heapKiB)
        records[#records+1]=name..":states="..stats.entries..":peakLuaKiB="..math.ceil(stats.peakHeapKiB)
    end
end
local function agrees(actual,expected,label)
    assert(tostring(actual)==tostring(expected),label.." reference mismatch")
end
test("composition_252_3",function()
    local n,s=composition(252,3,4,123)
    agrees(n,O.makeBoundedCompositionFamily(252,3,4,123).count(),"composition 252/3")
    return s
end)
test("composition_12_3",function()
    local n,s=composition(12,3,4,123)
    agrees(n,O.makeBoundedCompositionFamily(12,3,4,123).count(),"composition 12/3")
    assert(tostring(n)=="1")
    return s
end)
test("composition_11_3",function()
    local n,s=composition(11,3,4,123)
    agrees(n,O.makeBoundedCompositionFamily(11,3,4,123).count(),"composition 11/3")
    assert(tostring(n)=="0")
    return s
end)
test("weave_4_4_4",function()
    local a={4,4,4}
    local n,s=weave(a)
    agrees(n,O.makeWeavingCounter(a).count(),"weave 4/4/4")
    return s
end)
test("weave_4_5_6",function()
    local a={4,5,6}
    local n,s=weave(a)
    agrees(n,O.makeWeavingCounter(a).count(),"weave 4/5/6")
    return s
end)
local function mustAbort(label,marker,fn)
    local ok,e=pcall(fn)
    assert(not ok and tostring(e):find(marker,1,true),label.." must abort with "..marker.."; got "..tostring(e))
end
test("composition_state_abort",function()
    mustAbort("composition","ABORT_MEMO",function() composition(252,3,4,123,{memo=1}) end)
end)
test("weave_state_abort",function()
    mustAbort("weave","ABORT_MEMO",function() weave({4,5,6},{memo=1}) end)
end)
test("heap_abort",function()
    mustAbort("heap","ABORT_HEAP",function() composition(12,3,4,123,{heapKiB=-1}) end)
end)
test("cpu_abort",function()
    mustAbort("cpu","ABORT_CPU",function() composition(12,3,4,123,{cpu=-1}) end)
end)
test("f0_preflight_no_reference_call",function()
    local checked=0
    for _,L in ipairs({4244,4358}) do
        local minMonths=math.max(3,(L+122)//123)
        assert(minMonths>8,"F0 should be preflight-rejected")
        checked=checked+1
    end
    assert(checked==2)
end)
assert(tests==10,"self-test count mismatch")
for _,line in ipairs(records) do print("BOUNDED_REFERENCE_METRIC|"..line) end
print("REFERENCE_COMPOSITION_BOUNDED_SELFTEST_PASS: 10/10")
print("F0_PROFILES_NOT_EXECUTED: 2/2")
print("SCOPE=BOUNDED_LUA_REFERENCE_COMPOSITION_QA_ONLY; FULL_DATE=NOT_RUN")
