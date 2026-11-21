-- QA-only resource guard for PC-BRANCH-LUA-HAITIAN.
-- This is NOT part of the production oracle. No calendar validity rules change.
local A = {}

local function int(v)
    return type(v) == "number" and math.type(v) == "integer"
end

function A.preflight(year, cap, compose)
    assert(int(cap) and 1 <= cap and cap <= 47, "QA_CAP_INVALID")
    assert(compose == nil or type(compose) == "function", "QA_DOWNSTREAM_INVALID")

    if type(year) ~= "table"
        or not int(year.openGateIndex)
        or not int(year.closeGateIndex)
        or not int(year.openGateDay)
        or not int(year.closeGateDay)
        or not int(year.number)
        or year.closeGateIndex - year.openGateIndex < 6
        or year.closeGateDay <= year.openGateDay
    then
        return { status = "INVALID_YEAR_ENVELOPE", admitted = false, called = false }
    end

    local length = year.closeGateDay - year.openGateDay
    if length < 252 or length > 5778 then
        return { status = "INVALID_YEAR_LENGTH", admitted = false, called = false, length = length }
    end

    -- Normative feasibility is separate from the OPTIONAL QA resource cap.
    local minimum = math.max(3, (length + 122) // 123)
    local maximum = math.min(47, length // 4)
    if minimum > maximum then
        return { status = "NORMATIVE_INFEASIBLE", admitted = false, called = false,
                 length = length, minMonths = minimum, maxMonths = maximum }
    end

    if minimum > cap then
        return { status = "RESOURCE_REJECT", admitted = false, called = false,
                 length = length, minMonths = minimum, maxMonths = maximum, cap = cap }
    end

    local result = { status = "ADMISSIBLE_TO_NEXT_RESOURCE_GATE", admitted = true,
                     called = false, length = length, minMonths = minimum,
                     maxMonths = maximum, cap = cap }
    if compose ~= nil then
        result.downstreamResult = compose(year)
        result.called = true
    end
    return result
end

return A
