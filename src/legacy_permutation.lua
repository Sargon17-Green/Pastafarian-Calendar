-- DISCOVERY 08: legacy a atann yon rang zero-based; li resevwa yon rang one-based.
-- Ansyen unrank0 a dwe rete egzak epi disponib pou PATCH 08 pita.
local LegacyPermutation = {}

local BLOCK = {120, 24, 6, 2, 1, 1}

-- Token prive a se sèl fason pou rekonèt yon refi RAN 720 otantik.
-- Yon lòt erè ki kopye menm mesaj la pa gen menm idantite.
local INVALID_ZERO_RANK = setmetatable({}, {
    __tostring = function() return "Rang legacy a dwe yon antye 0..719" end,
    __metatable = "locked"
})

local function requireRank0(rank0)
    if not (type(rank0) == "number" and math.type(rank0) == "integer"
        and rank0 >= 0 and rank0 <= 719) then
        error(INVALID_ZERO_RANK, 0)
    end
end

local function ownedCopy(permutation)
    if permutation == nil then return nil end
    local copy = {}
    for i = 1, 6 do copy[i] = permutation[i] end
    return copy
end

-- Fonksyon istorik la se yon vre factoradic lexicographic unrank0.
-- Li kòrèk POU ANTRE 0..719; se moun ki rele li ki konfonn 1..720.
function LegacyPermutation.oldPermutationUnrank0(rank0)
    requireRank0(rank0)
    local available = {1, 2, 3, 4, 5, 6}
    local permutation = {}
    local remainder = rank0
    for position = 1, 6 do
        local index0 = remainder // BLOCK[position]
        remainder = remainder % BLOCK[position]
        assert(index0 < #available, "Index factoradic depase longè eleman yo")
        permutation[position] = table.remove(available, index0 + 1)
    end
    assert(#available == 0 and remainder == 0)
    return permutation
end

-- Idantite kòd legacy a: menm token erè a ka rekòmanse pa yon wrapper.
-- Se sèlman VALIDATÈ ORIJINAL la ki ka bay refi rank 720 nou aksepte.
local TRUSTED_UNRANK0 = LegacyPermutation.oldPermutationUnrank0

-- Kalkile nimewo ranje one-based nan valè gout la san pèdi gwo BigInt.
-- Erè a se PAS ONE-BASED la dirèk nan oldPermutationUnrank0, san -1.
local function oldOneBasedRank(dropValue)
    local B = require("bigint")
    local delta = B.sub(B.from(dropValue), B.from(1))
    local remainder = B.mod(delta, B.from(720))
    if B.compare(remainder, B.from(0)) < 0 then
        remainder = B.add(remainder, B.from(720))
    end
    local oneBased = B.toNumber(B.add(remainder, B.from(1)))
    assert(oneBased ~= nil and oneBased >= 1 and oneBased <= 720)
    return oneBased
end

function LegacyPermutation.oldOneBasedRank(dropValue)
    return oldOneBasedRank(dropValue)
end

function LegacyPermutation.oldOrderFromDropWrong(dropValue)
    local oneBased = oldOneBasedRank(dropValue)
    -- Pa ranje sa: sa dwe rete ERÈ istorik Stage 16.
    return LegacyPermutation.oldPermutationUnrank0(oneBased)
end

function LegacyPermutation.execute(dropValue)
    local B = require("bigint")
    local Base = require("monster_base")
    local decimal = tostring(B.from(dropValue))
    local context = Base.MonsterContext.new(1, 1)
    context.phase = "LEGACY_PERM_RANK"
    context.mode = "STAGE_16_DISCOVERY_08"
    context.status = "LEGACY_RANK_PENDING"
    local manager = Base.MonsterManager.new(context)

    manager.dispatcher:register("LEGACY_ONE_BASED_RANK", function(active, owner)
        local oneBased = oldOneBasedRank(dropValue)
        active:beginSemanticUpdate({
            dropDecimal = decimal,
            rankOneBased = oneBased,
            requiredUnrankBase = 0,
            source = "ONE_BASED_RANK_SENT_DIRECTLY_TO_UNRANK0"
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.permutation.oneBasedRanks")
        owner.metricsManager:observe("legacy.permutation.rank", tostring(oneBased))
        active.status = "LEGACY_ONE_BASED_RANK_READY"
        return oneBased
    end)

    manager.dispatcher:register("LEGACY_PERM_UNRANK0", function(active, owner)
        local oneBased = active.semanticState.rankOneBased
        -- Sonje fonksyon yo te rele anvan li egzekite: yon wrapper
        -- kapab retabli chan tab la anvan li voye token erè a.
        local invokedUnrank = LegacyPermutation.oldPermutationUnrank0
        local ok, order = pcall(invokedUnrank, oneBased)
        -- Se SÈLMAN refi istorik rang 720 ki se EXPECTED_RED.
        -- Pa kache yon panik factoradic, yon erè nan depandans, oubyen
        -- yon echèk sou rang valab tankou si se te erè indexing istorik la.
        if not ok then
            -- Idantite token PRIVATE, pa yon konparezon tèks, bay prèv
            -- ke echèk la soti nan validasyon rank0 reyèl la sèlman.
            if oneBased ~= 720 or not rawequal(order, INVALID_ZERO_RANK)
                or not rawequal(invokedUnrank, TRUSTED_UNRANK0) then
                error(order, 0)
            end
        end
        local missing = not ok
        active.phase = "LEGACY_PERM_UNRANK"
        active:beginSemanticUpdate({
            dropDecimal = decimal,
            rankOneBased = oneBased,
            rankActuallyPassed = oneBased,
            requiredUnrankBase = 0,
            source = "WRONG_ONE_BASED_TO_ZERO_BASED_CALL",
            missing = missing,
            permutation = missing and "MISSING" or table.concat(order, ",")
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.permutation.unrankCalls")
        if missing then owner.metricsManager:bump("legacy.permutation.rank720Rejected") end
        owner.metricsManager:observe("legacy.permutation.lastRank", tostring(oneBased))
        active.diagnostics[#active.diagnostics + 1] = {
            code = missing and "ONE_BASED_720_INVALID_FOR_UNRANK0"
                   or "ONE_BASED_OFF_BY_ONE_RANK",
            rankActuallyPassed = oneBased,
            rankBaseMismatch = true
        }
        active.status = missing and "LEGACY_PERM_RANK_OUT_OF_RANGE"
                        or "LEGACY_PERM_SHIFTED"
        return {found = not missing, order = ownedCopy(ok and order or nil)}
    end)

    manager.dispatcher:dispatch(context, "LEGACY_ONE_BASED_RANK", manager)
    local envelope = manager.dispatcher:dispatch(context, "LEGACY_PERM_UNRANK0", manager)
    return ownedCopy(envelope.order), context
end

return LegacyPermutation
