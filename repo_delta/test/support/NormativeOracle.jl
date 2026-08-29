module NormativeOracle

export M,
       TABLETS_DAY,
       FOUNDATION_DAY,
       regularMod,
       SAVE,
       dayCount,
       workCounts,
       buildStones,
       permutationUnrank1,
       bowlOrderFromNumber,
       bowlOrderFromDrop,
       fallingFactorial,
       countBoundedCompositions,
       unrankBoundedComposition,
       countWeavings,
       unrankWeaving,
       calendarDateCanonical,
       calendarDate

const M = BigInt(2)^127 - 1
const TABLETS_DAY = BigInt(-278522)
const FOUNDATION_DAY = BigInt(-15055671)
const GATE_GAP_MIN = 42
const GATE_GAP_MAX = 963
const YEAR_MIN_DAYS = 252
const YEAR_MAX_DAYS = 5778
const MIN_GATE_GAPS_PER_YEAR = 6
const MIN_CUTLETS = 6
const MAX_CUTLETS = 17
const MIN_MONTHS = 3
const MAX_MONTHS = 47
const MIN_MONTH_DAYS = 4
const MAX_MONTH_DAYS = 123

const SEAL_GATE_GAP = 1
const SEAL_YEAR_5000 = 10
const SEAL_NEXT_YEAR = 11
const SEAL_PREVIOUS_YEAR = 12
const SEAL_CUTLET_COUNT = 20
const SEAL_CUTLET_PARTITION = 21
const SEAL_CUTLET_NAMES = 22
const SEAL_MONTH_COUNT = 30
const SEAL_MONTH_LENGTHS = 31
const SEAL_MONTH_WEAVING = 32
const SEAL_MONTH_NAMES = 33

const WHEAT = 1
const BARLEY = 2
const SALT = 3
const BITTER = 4
const RED = 5

regularMod(x::Integer, d::Integer) = mod(x, d)
SAVE(x::Integer) = BigInt(1) + regularMod(BigInt(x) - 1, M)
square(x::Integer) = BigInt(x) * BigInt(x)
ceilDiv(a::Integer, b::Integer) = cld(a, b)
wrap1(position::Integer, size::Integer) = 1 + regularMod(position - 1, size)

function dayCount(day::Integer)
    d = BigInt(day)
    if d == FOUNDATION_DAY
        return BigInt(1)
    elseif d > FOUNDATION_DAY
        return 2 * (d - FOUNDATION_DAY) + 1
    else
        return 2 * (FOUNDATION_DAY - d)
    end
end

struct WorkCounts
    action::BigInt
    target::BigInt
    distance::BigInt
    connection::BigInt
    direction::Int
end

function workCounts(calculationDay::Integer, targetDay::Integer)
    c = dayCount(calculationDay)
    t = dayCount(targetDay)
    distance = abs(BigInt(targetDay) - BigInt(calculationDay)) + 1
    connection = c + t
    direction = targetDay < calculationDay ? 1 : (targetDay == calculationDay ? 2 : 3)
    return WorkCounts(c, t, distance, connection, direction)
end

function buildStones()
    stones = Vector{NTuple{5, BigInt}}(undef, 46)
    stones[1] = (BigInt(17), BigInt(29), BigInt(43), BigInt(71), BigInt(101))
    for i in 2:46
        old = stones[i - 1]
        nextWheat = SAVE(square(old[WHEAT]) + 3 * old[BARLEY] + i)
        nextBarley = SAVE(square(old[BARLEY]) + 5 * old[SALT] + old[WHEAT])
        nextSalt = SAVE(square(old[SALT]) + 7 * old[BITTER] + old[BARLEY])
        nextBitter = SAVE(square(old[BITTER]) + 11 * old[RED] + old[SALT])
        nextRed = SAVE(square(old[RED]) + 13 * old[WHEAT] + old[BITTER])
        stones[i] = (nextWheat, nextBarley, nextSalt, nextBitter, nextRed)
    end
    return stones
end

const STONES = buildStones()

const HIDDEN_COEFF = (
    (3, 4, 6, 8),
    (5, 7, 10, 12),
    (7, 10, 14, 16),
    (9, 13, 18, 20),
    (11, 16, 22, 24),
    (13, 19, 26, 28),
    (15, 22, 30, 32),
)

const HIDDEN_GRIND_STONE = (WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY)

function buildHiddenDrops(counts::WorkCounts, stones)
    hidden = Vector{BigInt}(undef, 7)
    for k in 1:7
        a, b, c, d = HIDDEN_COEFF[k]
        x = counts.action + a * counts.target + b * counts.distance + c * counts.connection + d * counts.direction
        x += sum(stones[k])
        x = SAVE(x)
        for grind in 1:7
            oldX = x
            x = SAVE(square(oldX) + 3 * oldX + stones[k][HIDDEN_GRIND_STONE[grind]] + grind)
        end
        hidden[k] = x
    end
    return hidden
end

const VISIBLE_GRINDS = (
    (3, 5, 7, 11, WHEAT),
    (5, 7, 11, 13, BARLEY),
    (7, 11, 13, 17, SALT),
    (11, 13, 17, 19, BITTER),
    (13, 17, 19, 23, RED),
    (17, 19, 23, 29, WHEAT),
    (19, 23, 29, 31, BARLEY),
    (23, 29, 31, 37, SALT),
    (29, 31, 37, 41, BITTER),
    (31, 37, 41, 43, RED),
    (37, 41, 43, 47, WHEAT),
)

function buildVisibleDrops(counts::WorkCounts, stones, hidden)
    timeline = Dict{Int, BigInt}()
    for k in 1:7
        timeline[1 - k] = hidden[k]
    end
    visible = Vector{BigInt}(undef, 46)
    for i in 1:46
        prev1 = timeline[i - 1]
        prev3 = timeline[i - 3]
        prev7 = timeline[i - 7]
        x = SAVE(
            stones[i][WHEAT] * counts.action +
            stones[i][BARLEY] * counts.target +
            stones[i][SALT] * counts.distance +
            stones[i][BITTER] * counts.connection +
            stones[i][RED] * counts.direction +
            prev1 + 3 * prev3 + 5 * prev7 + i
        )
        for grind in 1:11
            a, b, c, d, kind = VISIBLE_GRINDS[grind]
            oldX = x
            x = SAVE(square(oldX) + a * oldX + b * prev1 + c * prev3 + d * prev7 + stones[i][kind])
        end
        timeline[i] = x
        visible[i] = x
    end
    return visible
end

function permutationUnrank1(rank1::Integer, itemsAscending::AbstractVector{<:Integer})
    n = length(itemsAscending)
    total = factorial(big(n))
    1 <= rank1 <= total || throw(ArgumentError("RANK_OUT_OF_RANGE_PERMUTATION"))
    rank0 = BigInt(rank1) - 1
    remaining = Int.(itemsAscending)
    result = Int[]
    while !isempty(remaining)
        slotsLeft = length(remaining)
        block = factorial(big(slotsLeft - 1))
        q, rank0 = divrem(rank0, block)
        idx = Int(q) + 1
        push!(result, remaining[idx])
        deleteat!(remaining, idx)
    end
    return result
end

bowlOrderFromNumber(orderNumber::Integer) = permutationUnrank1(orderNumber, collect(1:6))
bowlOrderFromDrop(dropValue::Integer) = bowlOrderFromNumber(regularMod(dropValue - 1, 720) + 1)

const BOWL_PRIME = (17, 19, 23, 29, 31, 37)
const BOWL_STIR_STONE_BY_POSITION = (WHEAT, BARLEY, SALT, BITTER, RED, WHEAT)

function initialBowls(counts::WorkCounts)
    bowls = Vector{BigInt}(undef, 6)
    for bowlId in 1:6
        s = counts.action + counts.target * bowlId + counts.distance + counts.connection + counts.direction + square(BOWL_PRIME[bowlId])
        bowls[bowlId] = SAVE(square(s) + bowlId)
    end
    return bowls
end

function applyVisibleDropsToBowls(bowls, visible, stones)
    working = copy(bowls)
    orderAtDrop46 = Int[]
    for i in 1:46
        drop = visible[i]
        order = bowlOrderFromDrop(drop)
        old = copy(working)
        firstBowl, secondBowl, thirdBowl = order[1], order[2], order[3]
        pour = fill(BigInt(0), 6)
        pour[1] = SAVE(square(drop) + stones[i][WHEAT] * old[firstBowl] + 3 * i)
        pour[2] = SAVE(square(drop) + stones[i][BARLEY] * old[secondBowl] + 5 * i)
        pour[3] = SAVE(square(drop) + stones[i][SALT] * old[thirdBowl] + 7 * i)
        nextBowls = Vector{BigInt}(undef, 6)
        for position in 1:6
            bowlId = order[position]
            prevId = order[wrap1(position - 1, 6)]
            nextId = order[wrap1(position + 1, 6)]
            stoneKind = BOWL_STIR_STONE_BY_POSITION[position]
            s = old[bowlId] + 2 * old[prevId] + 3 * old[nextId] + pour[position] + drop + stones[i][stoneKind]
            nextBowls[bowlId] = SAVE(square(s) + 5 * old[prevId] * old[nextId] + i * position)
        end
        working = nextBowls
        if i == 46
            orderAtDrop46 = copy(order)
        end
    end
    return working, orderAtDrop46
end

function postStir12(bowls)
    working = copy(bowls)
    for stir in 1:12
        old = copy(working)
        savedBowlSum = SAVE(sum(old) + 149 * stir)
        orderNumber = regularMod(savedBowlSum - 1, 720) + 1
        order = bowlOrderFromNumber(orderNumber)
        nextBowls = Vector{BigInt}(undef, 6)
        for position in 1:6
            bowlId = order[position]
            prevId = order[wrap1(position - 1, 6)]
            nextId = order[wrap1(position + 1, 6)]
            s = old[bowlId] + 3 * old[prevId] + 5 * old[nextId] + savedBowlSum + stir + square(position)
            nextBowls[bowlId] = SAVE(square(s) + 7 * old[prevId] * old[nextId])
        end
        working = nextBowls
    end
    return working
end

struct SauceResult
    bowls::Vector{BigInt}
    orderAtDrop46::Vector{Int}
end

function sauce(calculationDay::Integer, targetDay::Integer)
    counts = workCounts(calculationDay, targetDay)
    hidden = buildHiddenDrops(counts, STONES)
    visible = buildVisibleDrops(counts, STONES, hidden)
    bowls = initialBowls(counts)
    bowlsAfterDrops, orderAtDrop46 = applyVisibleDropsToBowls(bowls, visible, STONES)
    finalBowls = postStir12(bowlsAfterDrops)
    return SauceResult(finalBowls, orderAtDrop46)
end

struct AnswerStream
    first::BigInt
    directionStep::Int
end

function nextBowlInDrop46Order(result::SauceResult, queriedBowlId::Integer)
    p = findfirst(==(Int(queriedBowlId)), result.orderAtDrop46)
    p === nothing && throw(ArgumentError("INVALID_BOWL_ID"))
    return result.orderAtDrop46[wrap1(p + 1, 6)]
end

function askBowl(result::SauceResult, queriedBowlId::Integer, seal::Integer)
    nextId = nextBowlInDrop46Order(result, queriedBowlId)
    first = SAVE(square(result.bowls[queriedBowlId] + seal + 181) + 179 * result.bowls[nextId] + seal)
    directionNumber = SAVE(square(first + seal + 1 + 193) + 193 * first + 197 * result.bowls[6])
    step = regularMod(directionNumber, 2) == 1 ? 1 : -1
    return AnswerStream(first, step)
end

answerAt(stream::AnswerStream, k::Integer) = 1 + regularMod(stream.first - 1 + stream.directionStep * BigInt(k), M)

function chooseRankShort(stream::AnswerStream, N::Integer)
    1 <= N <= M || throw(ArgumentError("INVALID_SHORT_SELECTION_SIZE"))
    acceptanceLimit = fld(M, N) * N
    k = BigInt(0)
    while true
        x = answerAt(stream, k)
        if x <= acceptanceLimit
            return regularMod(x - 1, N) + 1
        end
        k += 1
    end
end

function smallestPowerCount(base::Integer, N::Integer)
    k = 1
    space = BigInt(base)
    while space < N
        k += 1
        space *= base
    end
    return k, space
end

function chooseRankWide(stream::AnswerStream, N::Integer)
    N > M || throw(ArgumentError("INVALID_WIDE_SELECTION_SIZE"))
    k, space = smallestPowerCount(M, N)
    wide = BigInt(1)
    weight = BigInt(1)
    for j in 0:(k - 1)
        digit = answerAt(stream, j) - 1
        wide += digit * weight
        weight *= M
    end
    acceptanceLimit = fld(space, N) * N
    while wide > acceptanceLimit
        wide = 1 + regularMod(wide - 1 + stream.directionStep, space)
    end
    return regularMod(wide - 1, N) + 1
end

chooseRank(stream::AnswerStream, N::Integer) = N <= M ? chooseRankShort(stream, N) : chooseRankWide(stream, N)

function fallingFactorial(n::Integer, k::Integer)
    0 <= k <= n || return BigInt(0)
    r = BigInt(1)
    for j in 0:(k - 1)
        r *= n - j
    end
    return r
end

function unrankDistinctIndices(n::Integer, k::Integer, rank1::Integer)
    total = fallingFactorial(n, k)
    1 <= rank1 <= total || throw(ArgumentError("RANK_OUT_OF_RANGE_NAMES"))
    remaining = collect(1:Int(n))
    out = Int[]
    r = BigInt(rank1)
    for position in 1:Int(k)
        suffixLength = Int(k) - position
        block = fallingFactorial(length(remaining) - 1, suffixLength)
        for candidateIndex in eachindex(remaining)
            if r > block
                r -= block
            else
                push!(out, remaining[candidateIndex])
                deleteat!(remaining, candidateIndex)
                break
            end
        end
    end
    return out
end

function makeBoundedCompositionCounter(total::Integer, slots::Integer, lo::Integer, hi::Integer)
    memo = Dict{Tuple{Int, Int}, BigInt}()
    function countSuffix(rem::Int, k::Int)
        if k == 0
            return rem == 0 ? BigInt(1) : BigInt(0)
        end
        if rem < k * lo || rem > k * hi
            return BigInt(0)
        end
        key = (rem, k)
        if haskey(memo, key)
            return memo[key]
        end
        s = BigInt(0)
        for x in lo:hi
            s += countSuffix(rem - x, k - 1)
        end
        memo[key] = s
        return s
    end
    return countSuffix
end

function countBoundedCompositions(total::Integer, slots::Integer, lo::Integer, hi::Integer)
    counter = makeBoundedCompositionCounter(total, slots, lo, hi)
    return counter(Int(total), Int(slots))
end

function unrankBoundedComposition(total::Integer, slots::Integer, lo::Integer, hi::Integer, rank1::Integer)
    counter = makeBoundedCompositionCounter(total, slots, lo, hi)
    allCount = counter(Int(total), Int(slots))
    1 <= rank1 <= allCount || throw(ArgumentError("RANK_OUT_OF_RANGE_COMPOSITION"))
    r = BigInt(rank1)
    rem = Int(total)
    out = Int[]
    for position in 1:Int(slots)
        for x in lo:hi
            count = counter(rem - x, Int(slots) - position)
            if r > count
                r -= count
            else
                push!(out, x)
                rem -= x
                break
            end
        end
    end
    return out
end

mutable struct GateState
    gate::Dict{BigInt, BigInt}
    minKnownGateIndex::BigInt
    maxKnownGateIndex::BigInt
end

GateState() = GateState(Dict{BigInt, BigInt}(BigInt(0) => FOUNDATION_DAY), BigInt(0), BigInt(0))

function positiveGateGap(n::Integer)
    result = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n)
    stream = askBowl(result, 1, SEAL_GATE_GAP)
    chosen = chooseRank(stream, 922)
    return BigInt(41) + chosen
end

function negativeGateGap(n::Integer)
    result = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n)
    stream = askBowl(result, 1, SEAL_GATE_GAP)
    chosen = chooseRank(stream, 922)
    return BigInt(41) + chosen
end

function ensureGateIndex!(state::GateState, k::Integer)
    target = BigInt(k)
    if target > state.maxKnownGateIndex
        n = state.maxKnownGateIndex + 1
        while n <= target
            state.gate[n] = state.gate[n - 1] + positiveGateGap(n)
            state.maxKnownGateIndex = n
            n += 1
        end
    elseif target < state.minKnownGateIndex
        n = state.minKnownGateIndex - 1
        while n >= target
            state.gate[n] = state.gate[n + 1] - negativeGateGap(abs(n))
            state.minKnownGateIndex = n
            n -= 1
        end
    end
    return state.gate[target]
end

function ensureGatesCover!(state::GateState, lowDay::Integer, highDay::Integer)
    while state.gate[state.minKnownGateIndex] > lowDay
        ensureGateIndex!(state, state.minKnownGateIndex - 1)
    end
    while state.gate[state.maxKnownGateIndex] < highDay
        ensureGateIndex!(state, state.maxKnownGateIndex + 1)
    end
    return nothing
end

function gateIndexAtOrBefore(state::GateState, day::Integer)
    ensureGatesCover!(state, day, day)
    lo = state.minKnownGateIndex
    hi = state.maxKnownGateIndex
    while lo < hi
        mid = lo + fld(hi - lo + 1, 2)
        if state.gate[mid] <= day
            lo = mid
        else
            hi = mid - 1
        end
    end
    return lo
end

function exactGateIndex(state::GateState, day::Integer)
    i = gateIndexAtOrBefore(state, day)
    return state.gate[i] == day ? i : nothing
end

struct Year
    number::BigInt
    openGateIndex::BigInt
    closeGateIndex::BigInt
    openGateDay::BigInt
    closeGateDay::BigInt
end

function validYearPair(state::GateState, openIndex::Integer, closeIndex::Integer)
    closeIndex - openIndex >= MIN_GATE_GAPS_PER_YEAR || return false
    length = state.gate[BigInt(closeIndex)] - state.gate[BigInt(openIndex)]
    return YEAR_MIN_DAYS <= length <= YEAR_MAX_DAYS
end

function year5000(calculationDay::Integer, state::GateState)
    c = BigInt(calculationDay)
    ensureGatesCover!(state, c - YEAR_MAX_DAYS, c + YEAR_MAX_DAYS)
    candidates = Tuple{BigInt, BigInt}[]
    for i in state.minKnownGateIndex:(state.maxKnownGateIndex - 1)
        state.gate[i] < c || continue
        for j in (i + 1):state.maxKnownGateIndex
            state.gate[j] >= c || continue
            length = state.gate[j] - state.gate[i]
            length > YEAR_MAX_DAYS && break
            validYearPair(state, i, j) || continue
            push!(candidates, (i, j))
        end
    end
    isempty(candidates) && error("NO_YEAR_5000_CANDIDATE")
    sort!(candidates, by = pair -> (state.gate[pair[2]] - state.gate[pair[1]], state.gate[pair[1]]))
    result = sauce(c, c)
    stream = askBowl(result, 1, SEAL_YEAR_5000)
    rank = Int(chooseRank(stream, length(candidates)))
    i, j = candidates[rank]
    return Year(BigInt(5000), i, j, state.gate[i], state.gate[j])
end

function nextYear(calculationDay::Integer, knownYear::Year, state::GateState)
    openIndex = knownYear.closeGateIndex
    ensureGatesCover!(state, state.gate[openIndex], state.gate[openIndex] + YEAR_MAX_DAYS)
    candidates = BigInt[]
    closeIndex = openIndex + 1
    while true
        ensureGateIndex!(state, closeIndex)
        state.gate[closeIndex] - state.gate[openIndex] > YEAR_MAX_DAYS && break
        validYearPair(state, openIndex, closeIndex) && push!(candidates, closeIndex)
        closeIndex += 1
    end
    sort!(candidates, by = j -> state.gate[j] - state.gate[openIndex])
    result = sauce(calculationDay, state.gate[openIndex])
    stream = askBowl(result, 1, SEAL_NEXT_YEAR)
    chosenClose = candidates[Int(chooseRank(stream, length(candidates)))]
    return Year(knownYear.number + 1, openIndex, chosenClose, state.gate[openIndex], state.gate[chosenClose])
end

function previousYear(calculationDay::Integer, knownYear::Year, state::GateState)
    closeIndex = knownYear.openGateIndex
    ensureGatesCover!(state, state.gate[closeIndex] - YEAR_MAX_DAYS, state.gate[closeIndex])
    candidates = BigInt[]
    openIndex = closeIndex - 1
    while true
        ensureGateIndex!(state, openIndex)
        state.gate[closeIndex] - state.gate[openIndex] > YEAR_MAX_DAYS && break
        validYearPair(state, openIndex, closeIndex) && push!(candidates, openIndex)
        openIndex -= 1
    end
    sort!(candidates, by = i -> state.gate[closeIndex] - state.gate[i])
    result = sauce(calculationDay, state.gate[closeIndex])
    stream = askBowl(result, 1, SEAL_PREVIOUS_YEAR)
    chosenOpen = candidates[Int(chooseRank(stream, length(candidates)))]
    return Year(knownYear.number - 1, chosenOpen, closeIndex, state.gate[chosenOpen], state.gate[closeIndex])
end

function findTargetYear(calculationDay::Integer, targetDay::Integer, state::GateState)
    y = year5000(calculationDay, state)
    while targetDay > y.closeGateDay
        y = nextYear(calculationDay, y, state)
    end
    while targetDay <= y.openGateDay
        y = previousYear(calculationDay, y, state)
    end
    return y
end

function chooseCutletCount(structureSauce::SauceResult, year::Year)
    gateGaps = Int(year.closeGateIndex - year.openGateIndex)
    candidates = [k for k in MIN_CUTLETS:MAX_CUTLETS if k <= gateGaps]
    stream = askBowl(structureSauce, 2, SEAL_CUTLET_COUNT)
    return candidates[Int(chooseRank(stream, length(candidates)))]
end

function makeCutletPartitionFamily(G::Int, K::Int, requiredBoundary::Union{Nothing, Int})
    memo = Dict{Tuple{Int, Int, Int, Bool}, BigInt}()
    function countState(rem::Int, slots::Int, cumulative::Int, hitBoundary::Bool)
        if slots == 0
            rem == 0 || return BigInt(0)
            return requiredBoundary === nothing ? BigInt(1) : (hitBoundary ? BigInt(1) : BigInt(0))
        end
        rem < slots && return BigInt(0)
        key = (rem, slots, cumulative, hitBoundary)
        haskey(memo, key) && return memo[key]
        total = BigInt(0)
        maxX = rem - (slots - 1)
        for x in 1:maxX
            nextCumulative = cumulative + x
            nextHit = hitBoundary
            if requiredBoundary !== nothing && !hitBoundary
                if nextCumulative == requiredBoundary
                    nextHit = true
                elseif nextCumulative > requiredBoundary
                    continue
                end
            end
            total += countState(rem - x, slots - 1, nextCumulative, nextHit)
        end
        memo[key] = total
        return total
    end
    countAll() = countState(G, K, 0, false)
    function unrank1(rank1::Integer)
        1 <= rank1 <= countAll() || throw(ArgumentError("RANK_OUT_OF_RANGE_CUTLET_PARTITION"))
        r = BigInt(rank1)
        rem = G
        slots = K
        cumulative = 0
        hit = false
        out = Int[]
        while slots > 0
            maxX = rem - (slots - 1)
            chosen = false
            for x in 1:maxX
                nextCumulative = cumulative + x
                nextHit = hit
                if requiredBoundary !== nothing && !hit
                    if nextCumulative == requiredBoundary
                        nextHit = true
                    elseif nextCumulative > requiredBoundary
                        continue
                    end
                end
                block = countState(rem - x, slots - 1, nextCumulative, nextHit)
                if r > block
                    r -= block
                else
                    push!(out, x)
                    rem -= x
                    slots -= 1
                    cumulative = nextCumulative
                    hit = nextHit
                    chosen = true
                    break
                end
            end
            chosen || error("CUTLET_PARTITION_UNRANK_FAILED")
        end
        return out
    end
    return countAll, unrank1
end

function chooseCutletPartition(calculationDay::Integer, structureSauce::SauceResult, year::Year, cutletCount::Int, state::GateState)
    G = Int(year.closeGateIndex - year.openGateIndex)
    g = exactGateIndex(state, calculationDay)
    required = g !== nothing && year.openGateIndex < g < year.closeGateIndex ? Int(g - year.openGateIndex) : nothing
    countAll, unrank1 = makeCutletPartitionFamily(G, cutletCount, required)
    stream = askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION)
    rank = chooseRank(stream, countAll())
    return unrank1(rank)
end

function chooseCutletNames(structureSauce::SauceResult, cutletCount::Int)
    N = fallingFactorial(17, cutletCount)
    stream = askBowl(structureSauce, 5, SEAL_CUTLET_NAMES)
    rank = chooseRank(stream, N)
    return unrankDistinctIndices(17, cutletCount, rank)
end

struct Cutlet
    nameIndex::Int
    openGateIndex::BigInt
    closeGateIndex::BigInt
    firstDay::BigInt
    lastDay::BigInt
end

function materializeCutlets(year::Year, partition, names, state::GateState)
    cutlets = Cutlet[]
    cursorGate = year.openGateIndex
    for k in eachindex(partition)
        openGateIndex = cursorGate
        closeGateIndex = cursorGate + partition[k]
        ensureGateIndex!(state, closeGateIndex)
        push!(cutlets, Cutlet(names[k], openGateIndex, closeGateIndex, state.gate[openGateIndex] + 1, state.gate[closeGateIndex]))
        cursorGate = closeGateIndex
    end
    return cutlets
end

function chooseMonthCount(structureSauce::SauceResult, year::Year)
    L = Int(year.closeGateDay - year.openGateDay)
    minMonths = ceilDiv(L, 123)
    maxMonths = min(47, fld(L, 4))
    candidates = collect(minMonths:maxMonths)
    stream = askBowl(structureSauce, 3, SEAL_MONTH_COUNT)
    return candidates[Int(chooseRank(stream, length(candidates)))]
end

function chooseMonthLengths(structureSauce::SauceResult, year::Year, monthCount::Int)
    L = Int(year.closeGateDay - year.openGateDay)
    counter = makeBoundedCompositionCounter(L, monthCount, 4, 123)
    countAll = counter(L, monthCount)
    stream = askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS)
    rank = chooseRank(stream, countAll)
    return unrankBoundedComposition(L, monthCount, 4, 123, rank)
end

struct WeaveState
    remaining::Tuple{Vararg{Int}}
    openedUpTo::Int
    closedUpTo::Int
end

function legalWeaveMove(state::WeaveState, j::Int, originalLengths)
    state.remaining[j] == 0 && return false
    alreadyOpened = state.remaining[j] < originalLengths[j]
    !alreadyOpened && j != state.openedUpTo + 1 && return false
    willClose = state.remaining[j] == 1
    willClose && j != state.closedUpTo + 1 && return false
    return true
end

function applyWeaveMove(state::WeaveState, j::Int, originalLengths)
    values = collect(state.remaining)
    opened = state.openedUpTo
    closed = state.closedUpTo
    if values[j] == originalLengths[j]
        opened = j
    end
    values[j] -= 1
    if values[j] == 0
        closed = j
    end
    return WeaveState(Tuple(values), opened, closed)
end

function makeWeavingCounter(lengths)
    original = Int.(lengths)
    memo = Dict{WeaveState, BigInt}()
    function countState(state::WeaveState)
        all(==(0), state.remaining) && return BigInt(1)
        haskey(memo, state) && return memo[state]
        total = BigInt(0)
        for j in eachindex(original)
            legalWeaveMove(state, j, original) || continue
            total += countState(applyWeaveMove(state, j, original))
        end
        memo[state] = total
        return total
    end
    initial = WeaveState(Tuple(original), 0, 0)
    return countState, initial
end

function countWeavings(lengths)
    counter, initial = makeWeavingCounter(lengths)
    return counter(initial)
end

function unrankWeaving(lengths, rank1::Integer)
    original = Int.(lengths)
    counter, state = makeWeavingCounter(original)
    total = counter(state)
    1 <= rank1 <= total || throw(ArgumentError("RANK_OUT_OF_RANGE_WEAVING"))
    r = BigInt(rank1)
    out = Int[]
    while length(out) < sum(original)
        chosen = false
        for j in eachindex(original)
            legalWeaveMove(state, j, original) || continue
            nextState = applyWeaveMove(state, j, original)
            block = counter(nextState)
            if r > block
                r -= block
            else
                push!(out, j)
                state = nextState
                chosen = true
                break
            end
        end
        chosen || error("WEAVING_UNRANK_FAILED")
    end
    return out
end

function chooseMonthWeaving(structureSauce::SauceResult, monthLengths)
    familyCount = countWeavings(monthLengths)
    stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING)
    rank = chooseRank(stream, familyCount)
    return unrankWeaving(monthLengths, rank)
end

function chooseMonthNames(structureSauce::SauceResult, monthCount::Int)
    N = fallingFactorial(47, monthCount)
    stream = askBowl(structureSauce, 5, SEAL_MONTH_NAMES)
    rank = chooseRank(stream, N)
    return unrankDistinctIndices(47, monthCount, rank)
end

struct YearStructure
    cutletCount::Int
    cutletPartition::Vector{Int}
    cutletNames::Vector{Int}
    cutlets::Vector{Cutlet}
    monthCount::Int
    monthLengths::Vector{Int}
    monthWeaving::Vector{Int}
    monthNames::Vector{Int}
end

function buildYearStructure(calculationDay::Integer, year::Year, state::GateState)
    firstDay = year.openGateDay + 1
    result = sauce(calculationDay, firstDay)
    cutletCount = chooseCutletCount(result, year)
    cutletPartition = chooseCutletPartition(calculationDay, result, year, cutletCount, state)
    cutletNames = chooseCutletNames(result, cutletCount)
    cutlets = materializeCutlets(year, cutletPartition, cutletNames, state)
    monthCount = chooseMonthCount(result, year)
    monthLengths = chooseMonthLengths(result, year, monthCount)
    monthWeaving = chooseMonthWeaving(result, monthLengths)
    monthNames = chooseMonthNames(result, monthCount)
    return YearStructure(cutletCount, cutletPartition, cutletNames, cutlets, monthCount, monthLengths, monthWeaving, monthNames)
end

function calendarDateCanonical(calculationDay::Integer, targetDay::Integer)
    state = GateState()
    year = findTargetYear(calculationDay, targetDay, state)
    structure = buildYearStructure(calculationDay, year, state)
    chosenCutletIndex = findfirst(c -> c.firstDay <= targetDay <= c.lastDay, structure.cutlets)
    chosenCutletIndex === nothing && error("TARGET_DAY_NOT_IN_CUTLET")
    chosenCutlet = structure.cutlets[chosenCutletIndex]
    dayInCutlet = BigInt(targetDay) - chosenCutlet.firstDay + 1
    yearOffset0 = Int(BigInt(targetDay) - (year.openGateDay + 1))
    monthId = structure.monthWeaving[yearOffset0 + 1]
    monthNameIndex = structure.monthNames[monthId]
    dayInMonth = count(==(monthId), structure.monthWeaving[1:(yearOffset0 + 1)])
    return (year.number, chosenCutlet.nameIndex, dayInCutlet, monthNameIndex, dayInMonth)
end

function calendarDate(calculationDay::Integer, targetDay::Integer, cutletResolver::Function, monthResolver::Function)
    yearNumber, cutletIndex, dayInCutlet, monthIndex, dayInMonth = calendarDateCanonical(calculationDay, targetDay)
    return (yearNumber, cutletResolver(cutletIndex), dayInCutlet, monthResolver(monthIndex), dayInMonth)
end

end
