local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")

local function explicitCompositions(total,slots,lo,hi)
    local out={}
    local row={}
    local function rec(pos,rem)
        if pos>slots then
            if rem==0 then
                local c={}; for i=1,slots do c[i]=row[i] end
                out[#out+1]=c
            end
            return
        end
        for x=lo,hi do
            if rem-x>=0 then row[pos]=x; rec(pos+1,rem-x) end
        end
    end
    rec(1,total)
    return out
end

for total=6,12 do
    local slots,lo,hi=3,1,5
    local explicit=explicitCompositions(total,slots,lo,hi)
    local fam=O.makeBoundedCompositionFamily(total,slots,lo,hi)
    assert(tostring(fam.count())==tostring(#explicit))
    for rank=1,#explicit do
        assert(table.concat(fam.unrank1(B.from(rank)),",")==table.concat(explicit[rank],","))
    end
end

local function explicitLegalWeavings(lengths)
    local out,row={},{ }
    local m=#lengths
    local remaining={}; for i=1,m do remaining[i]=lengths[i] end
    local openedUpTo,closedUpTo=0,0
    local total=0; for i=1,m do total=total+lengths[i] end
    local function rec(pos,a,b)
        if pos>total then
            local c={}; for i=1,total do c[i]=row[i] end
            out[#out+1]=c
            return
        end
        for j=1,m do
            if remaining[j]>0 then
                local alreadyOpened=remaining[j]<lengths[j]
                local willClose=remaining[j]==1
                if (alreadyOpened or j==a+1) and (not willClose or j==b+1) then
                    local old=remaining[j]
                    local na,nb=a,b
                    if old==lengths[j] then na=j end
                    remaining[j]=old-1
                    if remaining[j]==0 then nb=j end
                    row[pos]=j
                    rec(pos+1,na,nb)
                    remaining[j]=old
                end
            end
        end
    end
    rec(1,openedUpTo,closedUpTo)
    return out
end

local cases={{2,2},{2,1,1},{3,2}}
for _,lengths in ipairs(cases) do
    local explicit=explicitLegalWeavings(lengths)
    local fam=O.makeWeavingCounter(lengths)
    assert(tostring(fam.count())==tostring(#explicit))
    for rank=1,#explicit do
        assert(table.concat(fam.unrank1(B.from(rank)),",")==table.concat(explicit[rank],","))
    end
end

print("PASS verifikasyon brute force pou fanmi vityèl")
