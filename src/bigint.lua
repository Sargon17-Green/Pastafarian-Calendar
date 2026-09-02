local BigInt = {}
BigInt.__index = BigInt

local BASE = 10000000
local BASE_DIGITS = 7

local function is_big(x)
    return type(x) == "table" and getmetatable(x) == BigInt
end

local function normalize(x)
    local d = x.d
    while #d > 0 and d[#d] == 0 do
        d[#d] = nil
    end
    if #d == 0 then
        x.s = 0
    end
    return x
end

local function new(sign, digits)
    return normalize(setmetatable({s = sign, d = digits}, BigInt))
end

function BigInt.from(x)
    if is_big(x) then
        local d = {}
        for i = 1, #x.d do d[i] = x.d[i] end
        return new(x.s, d)
    end
    if type(x) == "number" then
        assert(math.type(x) == "integer", "BigInt mande yon nonb antye")
        if x == 0 then return new(0, {}) end
        local sign = x < 0 and -1 or 1
        if x < 0 then x = -x end
        local d = {}
        while x > 0 do
            d[#d + 1] = x % BASE
            x = x // BASE
        end
        return new(sign, d)
    end
    if type(x) == "string" then
        local sign = 1
        if x:sub(1,1) == "-" then
            sign = -1
            x = x:sub(2)
        elseif x:sub(1,1) == "+" then
            x = x:sub(2)
        end
        assert(x:match("^%d+$"), "BigInt mande yon chèn desimal")
        x = x:gsub("^0+", "")
        if x == "" then return new(0, {}) end
        local d = {}
        local i = #x
        while i > 0 do
            local j = math.max(1, i - BASE_DIGITS + 1)
            d[#d + 1] = tonumber(x:sub(j, i))
            i = j - 1
        end
        return new(sign, d)
    end
    error("Kalite sa a pa ka vin BigInt")
end

function BigInt:clone()
    return BigInt.from(self)
end

function BigInt:isZero()
    return self.s == 0
end

local function cmp_abs(a, b)
    if #a.d ~= #b.d then
        return #a.d < #b.d and -1 or 1
    end
    for i = #a.d, 1, -1 do
        if a.d[i] ~= b.d[i] then
            return a.d[i] < b.d[i] and -1 or 1
        end
    end
    return 0
end

function BigInt.compare(a, b)
    a, b = BigInt.from(a), BigInt.from(b)
    if a.s ~= b.s then return a.s < b.s and -1 or 1 end
    if a.s == 0 then return 0 end
    local c = cmp_abs(a, b)
    return a.s > 0 and c or -c
end

local function add_abs(a, b)
    local d, carry = {}, 0
    local n = math.max(#a.d, #b.d)
    for i = 1, n do
        local v = (a.d[i] or 0) + (b.d[i] or 0) + carry
        if v >= BASE then v, carry = v - BASE, 1 else carry = 0 end
        d[i] = v
    end
    if carry ~= 0 then d[n + 1] = carry end
    return d
end

local function sub_abs(a, b)
    local d, borrow = {}, 0
    for i = 1, #a.d do
        local v = a.d[i] - (b.d[i] or 0) - borrow
        if v < 0 then v, borrow = v + BASE, 1 else borrow = 0 end
        d[i] = v
    end
    return d
end

function BigInt.add(a, b)
    a, b = BigInt.from(a), BigInt.from(b)
    if a.s == 0 then return b end
    if b.s == 0 then return a end
    if a.s == b.s then return new(a.s, add_abs(a, b)) end
    local c = cmp_abs(a, b)
    if c == 0 then return new(0, {}) end
    if c > 0 then return new(a.s, sub_abs(a, b)) end
    return new(b.s, sub_abs(b, a))
end

function BigInt.neg(a)
    a = BigInt.from(a)
    if a.s == 0 then return a end
    a.s = -a.s
    return a
end

function BigInt.sub(a, b)
    return BigInt.add(a, BigInt.neg(b))
end

function BigInt.mulSmall(a, n)
    a = BigInt.from(a)
    assert(type(n) == "number" and math.type(n) == "integer", "Miltiplikatè a dwe antye")
    if a.s == 0 or n == 0 then return new(0, {}) end
    local sign = a.s
    if n < 0 then sign, n = -sign, -n end
    local d, carry = {}, 0
    for i = 1, #a.d do
        local v = a.d[i] * n + carry
        d[i] = v % BASE
        carry = v // BASE
    end
    while carry > 0 do
        d[#d + 1] = carry % BASE
        carry = carry // BASE
    end
    return new(sign, d)
end

function BigInt.mul(a, b)
    a, b = BigInt.from(a), BigInt.from(b)
    if a.s == 0 or b.s == 0 then return new(0, {}) end
    local d = {}
    for i = 1, #a.d + #b.d do d[i] = 0 end
    for i = 1, #a.d do
        local carry = 0
        for j = 1, #b.d do
            local k = i + j - 1
            local v = d[k] + a.d[i] * b.d[j] + carry
            d[k] = v % BASE
            carry = v // BASE
        end
        local k = i + #b.d
        while carry > 0 do
            local v = (d[k] or 0) + carry
            d[k] = v % BASE
            carry = v // BASE
            k = k + 1
        end
    end
    return new(a.s * b.s, d)
end

local function abs_value(a)
    a = BigInt.from(a)
    if a.s < 0 then a.s = 1 end
    return a
end

local function shift_base_add(a, limb)
    if a.s == 0 and limb == 0 then return new(0, {}) end
    local d = {limb}
    for i = 1, #a.d do d[i + 1] = a.d[i] end
    return new(1, d)
end

local function divmod_abs(a, b)
    assert(b.s > 0, "Divizè a dwe pozitif")
    if a.s == 0 then return new(0, {}), new(0, {}) end
    if cmp_abs(a, b) < 0 then return new(0, {}), a end
    local q_be = {}
    local r = new(0, {})
    for i = #a.d, 1, -1 do
        r = shift_base_add(r, a.d[i])
        local lo, hi, best = 0, BASE - 1, 0
        while lo <= hi do
            local mid = (lo + hi) // 2
            local prod = BigInt.mulSmall(b, mid)
            local c = cmp_abs(prod, r)
            if c <= 0 then
                best = mid
                lo = mid + 1
            else
                hi = mid - 1
            end
        end
        q_be[#q_be + 1] = best
        if best ~= 0 then r = BigInt.sub(r, BigInt.mulSmall(b, best)) end
    end
    local qd = {}
    for i = #q_be, 1, -1 do qd[#qd + 1] = q_be[i] end
    return new(1, qd), normalize(r)
end

function BigInt.divmodFloor(a, b)
    a, b = BigInt.from(a), BigInt.from(b)
    assert(b.s > 0, "Divizè a dwe yon BigInt pozitif")
    if a.s >= 0 then
        return divmod_abs(a, b)
    end
    local qa, ra = divmod_abs(abs_value(a), b)
    if ra.s == 0 then
        return BigInt.neg(qa), ra
    end
    return BigInt.neg(BigInt.add(qa, 1)), BigInt.sub(b, ra)
end

function BigInt.floorDiv(a, b)
    local q = BigInt.divmodFloor(a, b)
    return q
end

function BigInt.mod(a, b)
    local _, r = BigInt.divmodFloor(a, b)
    return r
end

function BigInt.pow(a, e)
    a = BigInt.from(a)
    assert(type(e) == "number" and math.type(e) == "integer" and e >= 0, "Eksponan an dwe antye epi pa negatif")
    local result = BigInt.from(1)
    local base = a
    while e > 0 do
        if e % 2 == 1 then result = BigInt.mul(result, base) end
        e = e // 2
        if e > 0 then base = BigInt.mul(base, base) end
    end
    return result
end

function BigInt.abs(a)
    return abs_value(a)
end

function BigInt.toNumber(a)
    a = BigInt.from(a)
    local n = 0
    for i = #a.d, 1, -1 do
        if n > (math.maxinteger - a.d[i]) // BASE then
            return nil
        end
        n = n * BASE + a.d[i]
    end
    return a.s < 0 and -n or n
end

function BigInt.__tostring(a)
    if a.s == 0 then return "0" end
    local parts = {}
    parts[1] = tostring(a.d[#a.d])
    for i = #a.d - 1, 1, -1 do
        parts[#parts + 1] = string.format("%0" .. BASE_DIGITS .. "d", a.d[i])
    end
    local s = table.concat(parts)
    return a.s < 0 and ("-" .. s) or s
end

function BigInt.__eq(a, b) return BigInt.compare(a, b) == 0 end
function BigInt.__lt(a, b) return BigInt.compare(a, b) < 0 end
function BigInt.__le(a, b) return BigInt.compare(a, b) <= 0 end
function BigInt.__unm(a) return BigInt.neg(a) end
function BigInt.__add(a, b) return BigInt.add(a, b) end
function BigInt.__sub(a, b) return BigInt.sub(a, b) end
function BigInt.__mul(a, b) return BigInt.mul(a, b) end
function BigInt.__idiv(a, b) return BigInt.floorDiv(a, b) end
function BigInt.__mod(a, b) return BigInt.mod(a, b) end
function BigInt.__pow(a, b) return BigInt.pow(a, b) end

BigInt.BASE = BASE
BigInt.ZERO = BigInt.from(0)
BigInt.ONE = BigInt.from(1)

return BigInt
