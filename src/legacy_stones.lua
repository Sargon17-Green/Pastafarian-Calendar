local BigInt = require("bigint")
local Base = require("monster_base")
local SavePatch = require("save_patch")
local LegacyStones = {}

local names = {"w", "b", "s", "m", "r"}

local function requireIndex(i)
    assert(type(i) == "number" and math.type(i) == "integer" and i >= 2 and i <= 46,
           "Endis wòch yo dwe yon antye ant 2 ak 46")
end

-- Fè yon nouvo kopi posede anvan ekzekisyon pou pa pataje referans ant apèl.
function LegacyStones.copy(stones)
    assert(type(stones) == "table", "Senk wòch yo dwe nan yon tablo")
    local owned = {}
    for _, name in ipairs(names) do
        owned[name] = BigInt.from(stones[name])
    end
    return owned
end

-- Erè istorik la: chak wòch ekri sou menm tablo S a, imedyatman.
-- w nouvo a antre nan b ak r; b nouvo a antre nan s; s nouvo a antre nan m;
-- m nouvo a antre nan r. PATCH 04 poko egziste.
function LegacyStones.mutateStonesWrong(i, S)
    requireIndex(i)
    LegacyStones.copy(S) -- Valide tout antre yo anvan premye chanjman an.
    -- Chak affectation sèvi ak eta S aktyèl la, pa yon foto ansyen eta a.
    S.w = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(BigInt.from(S.w), BigInt.from(S.w)),
                                       BigInt.mulSmall(BigInt.from(S.b), 3)), i))
    S.b = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(BigInt.from(S.b), BigInt.from(S.b)),
                                       BigInt.mulSmall(BigInt.from(S.s), 5)), S.w))
    S.s = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(BigInt.from(S.s), BigInt.from(S.s)),
                                       BigInt.mulSmall(BigInt.from(S.m), 7)), S.b))
    S.m = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(BigInt.from(S.m), BigInt.from(S.m)),
                                       BigInt.mulSmall(BigInt.from(S.r), 11)), S.s))
    S.r = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(BigInt.from(S.r), BigInt.from(S.r)),
                                       BigInt.mulSmall(S.w, 13)), S.m))
    return S
end

function LegacyStones.seed()
    return LegacyStones.copy({w=17, b=29, s=43, m=71, r=101})
end

function LegacyStones.execute(i, stones)
    requireIndex(i)
    local original = LegacyStones.copy(stones)
    local context = Base.MonsterContext.new(i, i)
    context.phase = "LEGACY_STONES"
    context.mode = "STAGE_08_DISCOVERY_04"
    context.status = "PREPARING_LEGACY_STONES"
    local manager = Base.MonsterManager.new(context)
    manager.dispatcher:register("LEGACY_STONES", function(active, owner)
        local wrong = LegacyStones.copy(original)
        LegacyStones.mutateStonesWrong(i, wrong)
        local candidate = {
            index = i, source = "SEQUENTIAL_MUTATION",
            oldW = tostring(original.w), oldB = tostring(original.b),
            oldS = tostring(original.s), oldM = tostring(original.m), oldR = tostring(original.r),
            w = tostring(wrong.w), b = tostring(wrong.b), s = tostring(wrong.s),
            m = tostring(wrong.m), r = tostring(wrong.r)
        }
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.stones.calls")
        owner.metricsManager:observe("legacy.stones.lastBarley", candidate.b)
        active.diagnostics[#active.diagnostics + 1] = {
            code = "SEQUENTIAL_REUSE_OF_NEW_STONES", phase = active.phase,
            originalBarley = candidate.oldB, producedBarley = candidate.b
        }
        active.status = "LEGACY_STONES_RETURNED"
        return LegacyStones.copy(wrong)
    end)
    local result = manager.dispatcher:dispatch(context, "LEGACY_STONES", manager)
    return result, context
end

-- Chemen reyèl pou 46 ranje yo pase nan dispatcher legacy chak fwa.
function LegacyStones.buildLegacyTable()
    local tableStones = {}
    local current = LegacyStones.seed()
    tableStones[1] = LegacyStones.copy(current)
    for i = 2, 46 do
        current = LegacyStones.execute(i, current)
        tableStones[i] = LegacyStones.copy(current)
    end
    return tableStones
end

return LegacyStones
