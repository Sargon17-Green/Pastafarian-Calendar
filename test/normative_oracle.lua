local B = require("bigint")
local Catalog = require("source_language_catalog")
local O = {}

local function bi(x) return B.from(x) end
local function nbi(x)
    local n = B.toNumber(x)
    assert(n ~= nil, "Valè BigInt la twò gwo pou yon endis Lua")
    return n
end
local function bcmp(a,b) return B.compare(a,b) end
local function bmin(a,b) return bcmp(a,b) <= 0 and B.from(a) or B.from(b) end

O.TABLETS_DAY = -278522
O.FOUNDATION_DAY = -15055671
O.M = bi("170141183460469231731687303715884105727")
O.GATE_GAP_MIN = 42
O.GATE_GAP_MAX = 963
O.YEAR_MIN_DAYS = 252
O.YEAR_MAX_DAYS = 5778
O.MIN_CUTLETS = 6
O.MAX_CUTLETS = 17
O.MIN_MONTHS = 3
O.MAX_MONTHS = 47
O.MIN_MONTH_DAYS = 4
O.MAX_MONTH_DAYS = 123

O.SEAL_GATE_GAP = 1
O.SEAL_YEAR_5000 = 10
O.SEAL_NEXT_YEAR = 11
O.SEAL_PREVIOUS_YEAR = 12
O.SEAL_CUTLET_COUNT = 20
O.SEAL_CUTLET_PARTITION = 21
O.SEAL_CUTLET_NAMES = 22
O.SEAL_MONTH_COUNT = 30
O.SEAL_MONTH_LENGTHS = 31
O.SEAL_MONTH_WEAVING = 32
O.SEAL_MONTH_NAMES = 33

local WHEAT, BARLEY, SALT, BITTER, RED = 1,2,3,4,5

function O.regularMod(x, d)
    return B.mod(bi(x), bi(d))
end

function O.SAVE(x)
    return bi(1) + O.regularMod(bi(x) - bi(1), O.M)
end

local function square(x) return bi(x) * bi(x) end
local function ceilDivNumber(a,b) return (a + b - 1) // b end
local function wrap1(position,size) return ((position - 1) % size) + 1 end

function O.dayCount(day)
    assert(type(day) == "number" and math.type(day) == "integer", "Jou a dwe yon nonb antye Lua")
    if day == O.FOUNDATION_DAY then return 1 end
    if day > O.FOUNDATION_DAY then return 2 * (day - O.FOUNDATION_DAY) + 1 end
    return 2 * (O.FOUNDATION_DAY - day)
end

function O.workCounts(calculationDay, targetDay)
    local direction = 2
    if targetDay < calculationDay then direction = 1 elseif targetDay > calculationDay then direction = 3 end
    return {
        action = O.dayCount(calculationDay),
        target = O.dayCount(targetDay),
        distance = math.abs(targetDay - calculationDay) + 1,
        connection = O.dayCount(calculationDay) + O.dayCount(targetDay),
        direction = direction
    }
end

function O.buildStones()
    local stone = {}
    stone[1] = {bi(17),bi(29),bi(43),bi(71),bi(101)}
    for i = 2,46 do
        local old = stone[i-1]
        stone[i] = {
            O.SAVE(square(old[WHEAT])  + bi(3)  * old[BARLEY] + bi(i)),
            O.SAVE(square(old[BARLEY]) + bi(5)  * old[SALT]   + old[WHEAT]),
            O.SAVE(square(old[SALT])   + bi(7)  * old[BITTER] + old[BARLEY]),
            O.SAVE(square(old[BITTER]) + bi(11) * old[RED]    + old[SALT]),
            O.SAVE(square(old[RED])    + bi(13) * old[WHEAT]  + old[BITTER])
        }
    end
    return stone
end

O.STONES = O.buildStones()

local HIDDEN_COEFF = {
    {3,4,6,8},{5,7,10,12},{7,10,14,16},{9,13,18,20},
    {11,16,22,24},{13,19,26,28},{15,22,30,32}
}
local HIDDEN_GRIND_STONE = {WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY}

function O.buildHiddenDrops(counts, stones)
    local hidden = {}
    for k = 1,7 do
        local coeff = HIDDEN_COEFF[k]
        local x = bi(counts.action)
            + bi(coeff[1]) * bi(counts.target)
            + bi(coeff[2]) * bi(counts.distance)
            + bi(coeff[3]) * bi(counts.connection)
            + bi(coeff[4]) * bi(counts.direction)
        for kind = 1,5 do x = x + stones[k][kind] end
        x = O.SAVE(x)
        for grind = 1,7 do
            local oldX = x
            x = O.SAVE(square(oldX) + bi(3)*oldX + stones[k][HIDDEN_GRIND_STONE[grind]] + bi(grind))
        end
        hidden[k] = x
    end
    return hidden
end

local VISIBLE_GRINDS = {
    {3,5,7,11,WHEAT},{5,7,11,13,BARLEY},{7,11,13,17,SALT},
    {11,13,17,19,BITTER},{13,17,19,23,RED},{17,19,23,29,WHEAT},
    {19,23,29,31,BARLEY},{23,29,31,37,SALT},{29,31,37,41,BITTER},
    {31,37,41,43,RED},{37,41,43,47,WHEAT}
}

function O.buildVisibleDrops(counts, stones, hidden)
    local timeline = {}
    for k = 1,7 do timeline[1-k] = hidden[k] end
    local visible = {}
    for i = 1,46 do
        local p1,p3,p7 = timeline[i-1],timeline[i-3],timeline[i-7]
        local x = O.SAVE(
            stones[i][WHEAT] * bi(counts.action)
            + stones[i][BARLEY] * bi(counts.target)
            + stones[i][SALT] * bi(counts.distance)
            + stones[i][BITTER] * bi(counts.connection)
            + stones[i][RED] * bi(counts.direction)
            + p1 + bi(3)*p3 + bi(5)*p7 + bi(i)
        )
        for grind = 1,11 do
            local oldX = x
            local row = VISIBLE_GRINDS[grind]
            x = O.SAVE(square(oldX)
                + bi(row[1])*oldX + bi(row[2])*p1 + bi(row[3])*p3 + bi(row[4])*p7
                + stones[i][row[5]])
        end
        timeline[i] = x
        visible[i] = x
    end
    return visible
end

local function factorial(n)
    local r = 1
    for i = 2,n do r = r*i end
    return r
end

function O.permutationUnrank1(rank1, itemsAscending)
    local rank0 = rank1 - 1
    local remaining, result = {}, {}
    for i = 1,#itemsAscending do remaining[i] = itemsAscending[i] end
    for slotsLeft = #remaining,1,-1 do
        local block = factorial(slotsLeft-1)
        local q = rank0 // block
        rank0 = rank0 % block
        result[#result+1] = remaining[q+1]
        table.remove(remaining,q+1)
    end
    return result
end

function O.bowlOrderFromDrop(dropValue)
    local orderNumber = nbi(O.regularMod(bi(dropValue)-bi(1), bi(720))) + 1
    return O.permutationUnrank1(orderNumber,{1,2,3,4,5,6})
end

local BOWL_PRIME = {17,19,23,29,31,37}
local BOWL_STIR_STONE = {WHEAT,BARLEY,SALT,BITTER,RED,WHEAT}

function O.initialBowls(counts)
    local bowls = {}
    for id = 1,6 do
        local s = bi(counts.action) + bi(counts.target)*bi(id) + bi(counts.distance)
            + bi(counts.connection) + bi(counts.direction) + bi(BOWL_PRIME[id]*BOWL_PRIME[id])
        bowls[id] = O.SAVE(square(s) + bi(id))
    end
    return bowls
end

local function cloneArray(a)
    local out = {}
    for i = 1,#a do out[i] = a[i] end
    return out
end

function O.applyVisibleDropsToBowls(bowls, visible, stones)
    local orderAt46
    for i = 1,46 do
        local drop = visible[i]
        local order = O.bowlOrderFromDrop(drop)
        local old = cloneArray(bowls)
        local pour = {bi(0),bi(0),bi(0),bi(0),bi(0),bi(0)}
        pour[1] = O.SAVE(square(drop) + stones[i][WHEAT] * old[order[1]] + bi(3*i))
        pour[2] = O.SAVE(square(drop) + stones[i][BARLEY] * old[order[2]] + bi(5*i))
        pour[3] = O.SAVE(square(drop) + stones[i][SALT] * old[order[3]] + bi(7*i))
        local nextBowls = {}
        for position = 1,6 do
            local id = order[position]
            local prev = order[wrap1(position-1,6)]
            local nxt = order[wrap1(position+1,6)]
            local s = old[id] + bi(2)*old[prev] + bi(3)*old[nxt] + pour[position] + drop + stones[i][BOWL_STIR_STONE[position]]
            nextBowls[id] = O.SAVE(square(s) + bi(5)*old[prev]*old[nxt] + bi(i*position))
        end
        bowls = nextBowls
        if i == 46 then orderAt46 = cloneArray(order) end
    end
    return bowls, orderAt46
end

function O.postStir12(bowls)
    for stir = 1,12 do
        local old = cloneArray(bowls)
        local saved = bi(0)
        for id = 1,6 do saved = saved + old[id] end
        saved = O.SAVE(saved + bi(149*stir))
        local orderNumber = nbi(O.regularMod(saved-bi(1),bi(720))) + 1
        local order = O.permutationUnrank1(orderNumber,{1,2,3,4,5,6})
        local nextBowls = {}
        for position = 1,6 do
            local id = order[position]
            local prev = order[wrap1(position-1,6)]
            local nxt = order[wrap1(position+1,6)]
            local s = old[id] + bi(3)*old[prev] + bi(5)*old[nxt] + saved + bi(stir) + bi(position*position)
            nextBowls[id] = O.SAVE(square(s) + bi(7)*old[prev]*old[nxt])
        end
        bowls = nextBowls
    end
    return bowls
end

function O.sauce(calculationDay,targetDay)
    local counts = O.workCounts(calculationDay,targetDay)
    local hidden = O.buildHiddenDrops(counts,O.STONES)
    local visible = O.buildVisibleDrops(counts,O.STONES,hidden)
    local bowls = O.initialBowls(counts)
    local after, order46 = O.applyVisibleDropsToBowls(bowls,visible,O.STONES)
    return {bowls=O.postStir12(after), orderAtDrop46=order46}
end

function O.nextBowlInDrop46Order(result, queriedId)
    local p
    for i = 1,6 do if result.orderAtDrop46[i] == queriedId then p=i break end end
    assert(p, "Yo pa jwenn bòl yo mande a")
    return result.orderAtDrop46[(p % 6)+1]
end

function O.askBowl(result,queriedId,seal)
    local nextId = O.nextBowlInDrop46Order(result,queriedId)
    local first = O.SAVE(square(result.bowls[queriedId] + bi(seal+181)) + bi(179)*result.bowls[nextId] + bi(seal))
    local directionNumber = O.SAVE(square(first + bi(seal+194)) + bi(193)*first + bi(197)*result.bowls[6])
    local step = nbi(O.regularMod(directionNumber,bi(2))) == 1 and 1 or -1
    return {first=first,directionStep=step}
end

function O.answerAt(stream,k)
    return bi(1) + O.regularMod(stream.first - bi(1) + bi(stream.directionStep*k), O.M)
end

local function asBigPositiveN(N)
    local n = bi(N)
    assert(bcmp(n,bi(1)) >= 0, "Kantite chwa a dwe pozitif")
    return n
end

function O.chooseRankShort(stream,N)
    N = asBigPositiveN(N)
    assert(bcmp(N,O.M) <= 0, "Chemen kout la mande N <= M")
    local limit = (O.M // N) * N
    local k = 0
    while true do
        local x = O.answerAt(stream,k)
        if bcmp(x,limit) <= 0 then return O.regularMod(x-bi(1),N)+bi(1) end
        k = k + 1
    end
end

function O.chooseRankWide(stream,N)
    N = asBigPositiveN(N)
    assert(bcmp(N,O.M) > 0, "Detou laj la mande N > M")
    local k,space = 1,bi(O.M)
    while bcmp(space,N) < 0 do k=k+1; space=space*O.M end
    local wide,weight = bi(1),bi(1)
    for j=0,k-1 do
        wide = wide + (O.answerAt(stream,j)-bi(1))*weight
        weight = weight*O.M
    end
    local limit = (space // N) * N
    while bcmp(wide,limit) > 0 do
        wide = bi(1) + O.regularMod(wide-bi(1)+bi(stream.directionStep),space)
    end
    return O.regularMod(wide-bi(1),N)+bi(1)
end

function O.chooseRank(stream,N)
    N = asBigPositiveN(N)
    if bcmp(N,O.M) <= 0 then return O.chooseRankShort(stream,N) end
    return O.chooseRankWide(stream,N)
end

function O.fallingFactorial(n,k)
    local r = bi(1)
    for j=0,k-1 do r = r * bi(n-j) end
    return r
end

function O.unrankDistinctIndices(n,k,rank1)
    local remaining,out = {},{}
    for i=1,n do remaining[i]=i end
    local r = bi(rank1)
    for position=1,k do
        local suffixLength = k-position
        local block = O.fallingFactorial(#remaining-1,suffixLength)
        local chosen
        for candidate=1,#remaining do
            if bcmp(r,block)>0 then r=r-block else chosen=candidate break end
        end
        assert(chosen,"Unrank non diferan pa jwenn blòk la")
        out[#out+1]=remaining[chosen]
        table.remove(remaining,chosen)
    end
    return out
end

function O.makeBoundedCompositionFamily(total,slots,lo,hi)
    local memo={}
    local function key(rem,k) return rem..":"..k end
    local function C(rem,k)
        if k==0 then return rem==0 and bi(1) or bi(0) end
        if rem<k*lo or rem>k*hi then return bi(0) end
        local kk=key(rem,k); if memo[kk] then return memo[kk] end
        local s=bi(0)
        for x=lo,hi do s=s+C(rem-x,k-1) end
        memo[kk]=s; return s
    end
    return {
        count=function() return C(total,slots) end,
        unrank1=function(rank1)
            local r,rem,out=bi(rank1),total,{}
            for position=1,slots do
                local selected
                for x=lo,hi do
                    local count=C(rem-x,slots-position)
                    if bcmp(r,count)>0 then r=r-count else selected=x break end
                end
                assert(selected,"Unrank konpozisyon limite pa jwenn blòk la")
                out[#out+1]=selected; rem=rem-selected
            end
            return out
        end
    }
end

local gate={ [0]=O.FOUNDATION_DAY }
local minKnown,maxKnown=0,0

function O.resetGateCache()
    gate={ [0]=O.FOUNDATION_DAY }; minKnown,maxKnown=0,0
end

function O.positiveGateGap(n)
    local r=O.sauce(O.FOUNDATION_DAY,O.FOUNDATION_DAY+n)
    local stream=O.askBowl(r,1,O.SEAL_GATE_GAP)
    return 41+nbi(O.chooseRank(stream,bi(922)))
end

function O.negativeGateGap(n)
    local r=O.sauce(O.FOUNDATION_DAY,O.FOUNDATION_DAY-n)
    local stream=O.askBowl(r,1,O.SEAL_GATE_GAP)
    return 41+nbi(O.chooseRank(stream,bi(922)))
end

function O.ensureGateIndex(k)
    if k>maxKnown then
        for n=maxKnown+1,k do gate[n]=gate[n-1]+O.positiveGateGap(n) end
        maxKnown=k
    end
    if k<minKnown then
        local n=minKnown-1
        while n>=k do gate[n]=gate[n+1]-O.negativeGateGap(math.abs(n)); n=n-1 end
        minKnown=k
    end
    return gate[k]
end

function O.ensureGatesCover(lowDay,highDay)
    assert(lowDay<=highDay,"Limit pòtay yo ranvèse")
    while gate[minKnown]>lowDay do O.ensureGateIndex(minKnown-1) end
    while gate[maxKnown]<highDay do O.ensureGateIndex(maxKnown+1) end
end

function O.gateIndexAtOrBefore(day)
    O.ensureGatesCover(day,day)
    local lo,hi=minKnown,maxKnown
    while lo<hi do
        local mid=lo+((hi-lo+1)//2)
        if gate[mid]<=day then lo=mid else hi=mid-1 end
    end
    return lo
end

function O.exactGateIndex(day)
    local i=O.gateIndexAtOrBefore(day)
    if gate[i]==day then return i end
    return nil
end

local function yearLength(openIndex,closeIndex) return gate[closeIndex]-gate[openIndex] end
local function validYearPair(openIndex,closeIndex)
    if closeIndex-openIndex<6 then return false end
    local L=yearLength(openIndex,closeIndex)
    return O.YEAR_MIN_DAYS<=L and L<=O.YEAR_MAX_DAYS
end
local function makeYear(number,i,j)
    return {number=number,openGateIndex=i,closeGateIndex=j,openGateDay=gate[i],closeGateDay=gate[j]}
end

function O.year5000(calculationDay)
    O.ensureGatesCover(calculationDay-O.YEAR_MAX_DAYS,calculationDay+O.YEAR_MAX_DAYS)
    local candidates={}
    for i=minKnown,maxKnown-1 do
        for j=i+1,maxKnown do
            if validYearPair(i,j) and gate[i]<calculationDay and calculationDay<=gate[j] then
                candidates[#candidates+1]={i=i,j=j,L=gate[j]-gate[i]}
            end
        end
    end
    table.sort(candidates,function(a,b) if a.L~=b.L then return a.L<b.L end return gate[a.i]<gate[b.i] end)
    assert(#candidates>0,"Pa gen kandida pou ane 5000")
    local r=O.sauce(calculationDay,calculationDay)
    local rank=nbi(O.chooseRank(O.askBowl(r,1,O.SEAL_YEAR_5000),bi(#candidates)))
    local c=candidates[rank]
    return makeYear(5000,c.i,c.j)
end

function O.nextYear(calculationDay,knownYear)
    local openIndex=knownYear.closeGateIndex
    O.ensureGatesCover(gate[minKnown],gate[openIndex]+O.YEAR_MAX_DAYS)
    local candidates={}
    local j=openIndex+1
    while true do
        O.ensureGateIndex(j)
        if gate[j]-gate[openIndex]>O.YEAR_MAX_DAYS then break end
        if validYearPair(openIndex,j) then candidates[#candidates+1]=j end
        j=j+1
    end
    table.sort(candidates,function(a,b) return (gate[a]-gate[openIndex]) < (gate[b]-gate[openIndex]) end)
    local r=O.sauce(calculationDay,gate[openIndex])
    local rank=nbi(O.chooseRank(O.askBowl(r,1,O.SEAL_NEXT_YEAR),bi(#candidates)))
    return makeYear(knownYear.number+1,openIndex,candidates[rank])
end

function O.previousYear(calculationDay,knownYear)
    local closeIndex=knownYear.openGateIndex
    O.ensureGatesCover(gate[closeIndex]-O.YEAR_MAX_DAYS,gate[maxKnown])
    local candidates={}
    local i=closeIndex-1
    while true do
        O.ensureGateIndex(i)
        if gate[closeIndex]-gate[i]>O.YEAR_MAX_DAYS then break end
        if validYearPair(i,closeIndex) then candidates[#candidates+1]=i end
        i=i-1
    end
    table.sort(candidates,function(a,b) return (gate[closeIndex]-gate[a]) < (gate[closeIndex]-gate[b]) end)
    local r=O.sauce(calculationDay,gate[closeIndex])
    local rank=nbi(O.chooseRank(O.askBowl(r,1,O.SEAL_PREVIOUS_YEAR),bi(#candidates)))
    return makeYear(knownYear.number-1,candidates[rank],closeIndex)
end

function O.findTargetYear(calculationDay,targetDay)
    local y=O.year5000(calculationDay)
    while targetDay>y.closeGateDay do y=O.nextYear(calculationDay,y) end
    while targetDay<=y.openGateDay do y=O.previousYear(calculationDay,y) end
    assert(y.openGateDay<targetDay and targetDay<=y.closeGateDay,"Jou sib la pa nan entèval ane a")
    return y
end

function O.makeCutletPartitionFamily(G,K,required)
    local memo={}
    local function key(rem,slots,cumulative,hit)
        return rem..":"..slots..":"..cumulative..":"..(hit and "1" or "0")
    end
    local function C(rem,slots,cumulative,hit)
        if slots==0 then
            if rem~=0 then return bi(0) end
            if required==nil then return bi(1) end
            return hit and bi(1) or bi(0)
        end
        if rem<slots then return bi(0) end
        local k=key(rem,slots,cumulative,hit); if memo[k] then return memo[k] end
        local total=bi(0)
        local maxX=rem-(slots-1)
        for x=1,maxX do
            local nc=cumulative+x
            local nh=hit
            local legal=true
            if required~=nil and not hit then
                if nc==required then nh=true elseif nc>required then legal=false end
            end
            if legal then total=total+C(rem-x,slots-1,nc,nh) end
        end
        memo[k]=total; return total
    end
    local function CountAll() return C(G,K,0,false) end
    local function Unrank1(rank1)
        local r,rem,slots,cumulative,hit=bi(rank1),G,K,0,false
        local out={}
        while slots>0 do
            local selected
            local maxX=rem-(slots-1)
            for x=1,maxX do
                local nc=cumulative+x
                local nh=hit
                local legal=true
                if required~=nil and not hit then
                    if nc==required then nh=true elseif nc>required then legal=false end
                end
                if legal then
                    local block=C(rem-x,slots-1,nc,nh)
                    if bcmp(r,block)>0 then r=r-block else selected={x,nc,nh}; break end
                end
            end
            assert(selected,"Unrank patisyon kotlèt pa jwenn blòk la")
            out[#out+1]=selected[1]; rem=rem-selected[1]; slots=slots-1; cumulative=selected[2]; hit=selected[3]
        end
        return out
    end
    return {count=CountAll,unrank1=Unrank1}
end

function O.buildYearStructure(calculationDay,year)
    local firstDay=year.openGateDay+1
    local r=O.sauce(calculationDay,firstDay)
    local gateGaps=year.closeGateIndex-year.openGateIndex
    local cutletCandidates={}
    for k=6,17 do if k<=gateGaps then cutletCandidates[#cutletCandidates+1]=k end end
    local cutletCount=cutletCandidates[nbi(O.chooseRank(O.askBowl(r,2,O.SEAL_CUTLET_COUNT),bi(#cutletCandidates)))]

    local g=O.exactGateIndex(calculationDay)
    local required=nil
    if g and year.openGateIndex<g and g<year.closeGateIndex then required=g-year.openGateIndex end
    local pf=O.makeCutletPartitionFamily(gateGaps,cutletCount,required)
    local partition=pf.unrank1(O.chooseRank(O.askBowl(r,2,O.SEAL_CUTLET_PARTITION),pf.count()))
    local cutletNameRank=O.chooseRank(O.askBowl(r,5,O.SEAL_CUTLET_NAMES),O.fallingFactorial(17,cutletCount))
    local cutletNames=O.unrankDistinctIndices(17,cutletCount,cutletNameRank)
    local cutlets={}
    local cursor=year.openGateIndex
    for k=1,cutletCount do
        local close=cursor+partition[k]
        cutlets[k]={nameIndex=cutletNames[k],openGateIndex=cursor,closeGateIndex=close,firstDay=gate[cursor]+1,lastDay=gate[close]}
        cursor=close
    end

    local L=year.closeGateDay-year.openGateDay
    local minMonths=ceilDivNumber(L,123)
    local maxMonths=math.min(47,L//4)
    assert(3<=minMonths and minMonths<=maxMonths and maxMonths<=47,"Limit kantite mwa yo pa valab")
    local monthCount=minMonths+nbi(O.chooseRank(O.askBowl(r,3,O.SEAL_MONTH_COUNT),bi(maxMonths-minMonths+1)))-1
    local mf=O.makeBoundedCompositionFamily(L,monthCount,4,123)
    local monthLengths=mf.unrank1(O.chooseRank(O.askBowl(r,3,O.SEAL_MONTH_LENGTHS),mf.count()))
    local monthWeaving=O.chooseMonthWeaving(r,monthLengths)
    local monthNameRank=O.chooseRank(O.askBowl(r,5,O.SEAL_MONTH_NAMES),O.fallingFactorial(47,monthCount))
    local monthNames=O.unrankDistinctIndices(47,monthCount,monthNameRank)
    return {
        cutletCount=cutletCount,cutletPartition=partition,cutletNames=cutletNames,cutlets=cutlets,
        monthCount=monthCount,monthLengths=monthLengths,monthWeaving=monthWeaving,monthNames=monthNames
    }
end

local function copyNumbers(a)
    local b={}; for i=1,#a do b[i]=a[i] end; return b
end

function O.makeWeavingCounter(lengths)
    local m=#lengths
    local memo={}
    local function stateKey(remaining,a,b)
        return table.concat(remaining,",").."|"..a.."|"..b
    end
    local function legal(remaining,a,b,j)
        if remaining[j]==0 then return false end
        local alreadyOpened=remaining[j]<lengths[j]
        if not alreadyOpened and j~=a+1 then return false end
        local willClose=remaining[j]==1
        if willClose and j~=b+1 then return false end
        return true
    end
    local function apply(remaining,a,b,j)
        local nextR=copyNumbers(remaining)
        local na,nb=a,b
        if nextR[j]==lengths[j] then na=j end
        nextR[j]=nextR[j]-1
        if nextR[j]==0 then nb=j end
        return nextR,na,nb
    end
    local function Count(remaining,a,b)
        local done=true
        for j=1,m do if remaining[j]~=0 then done=false break end end
        if done then return bi(1) end
        local key=stateKey(remaining,a,b); if memo[key] then return memo[key] end
        local total=bi(0)
        for j=1,m do
            if legal(remaining,a,b,j) then
                local nr,na,nb=apply(remaining,a,b,j)
                total=total+Count(nr,na,nb)
            end
        end
        memo[key]=total; return total
    end
    local initial=copyNumbers(lengths)
    return {
        count=function() return Count(initial,0,0) end,
        unrank1=function(rank1)
            local remaining=copyNumbers(lengths)
            local a,b=0,0
            local r=bi(rank1)
            local out={}
            local totalDays=0; for j=1,m do totalDays=totalDays+lengths[j] end
            while #out<totalDays do
                local selected
                for j=1,m do
                    if legal(remaining,a,b,j) then
                        local nr,na,nb=apply(remaining,a,b,j)
                        local block=Count(nr,na,nb)
                        if bcmp(r,block)>0 then r=r-block else selected={j,nr,na,nb}; break end
                    end
                end
                assert(selected,"Unrank tise mwa pa jwenn blòk la")
                out[#out+1]=selected[1]; remaining=selected[2]; a=selected[3]; b=selected[4]
            end
            return out
        end
    }
end

function O.chooseMonthWeaving(structureSauce,monthLengths)
    local family=O.makeWeavingCounter(monthLengths)
    local rank=O.chooseRank(O.askBowl(structureSauce,4,O.SEAL_MONTH_WEAVING),family.count())
    return family.unrank1(rank)
end

function O.calendarDateIds(calculationDay,targetDay)
    local year=O.findTargetYear(calculationDay,targetDay)
    local structure=O.buildYearStructure(calculationDay,year)
    local chosenCutlet
    for i=1,#structure.cutlets do
        local c=structure.cutlets[i]
        if c.firstDay<=targetDay and targetDay<=c.lastDay then chosenCutlet=c break end
    end
    assert(chosenCutlet,"Yo pa jwenn kotlèt jou sib la")
    local dayInCutlet=targetDay-chosenCutlet.firstDay+1
    local yearOffset0=targetDay-(year.openGateDay+1)
    local monthId=structure.monthWeaving[yearOffset0+1]
    local dayInMonth=0
    for p=1,yearOffset0+1 do if structure.monthWeaving[p]==monthId then dayInMonth=dayInMonth+1 end end
    return {year.number,chosenCutlet.nameIndex,dayInCutlet,structure.monthNames[monthId],dayInMonth}
end

function O.calendarDate(calculationDay,targetDay)
    local ids=O.calendarDateIds(calculationDay,targetDay)
    return {ids[1],Catalog.cutlet(ids[2]),ids[3],Catalog.month(ids[4]),ids[5]}
end

return O
