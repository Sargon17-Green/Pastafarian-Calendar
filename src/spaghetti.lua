local Base = require("monster_base")
local LegacySave = require("legacy_save")
local SavePatch = require("save_patch")
local LegacyDayTag = require("legacy_day_tag")
local DayTagPatch = require("day_tag_patch")
local LegacyDistance = require("legacy_distance")
local DistancePatch = require("distance_patch")
local S = {}

function S.bootstrapProbe(calculationDay, targetDay)
    local context = Base.MonsterContext.new(calculationDay, targetDay)
    local manager = Base.MonsterManager.new(context)
    return manager:runBootstrapProbe()
end

-- PATCH 01 repare wout pwodiksyon an; li pa efase ansyen wout la.
function S.saveSpaghetti(value)
    local corrected = SavePatch.execute(value)
    return corrected
end

-- Wout sa a bay rezilta patch la ak de tras yo pou verifikasyon.
function S.savePatchProbe(value)
    return SavePatch.execute(value)
end

-- Chemen dyagnostik istorik la toujou retounen rès òdinè a.
function S.legacySaveProbe(value)
    return LegacySave.execute(value)
end

-- Wout otoritè a aplike PATCH 02 san chanje chemen istorik la.
function S.dayTagSpaghetti(day)
    local corrected = DayTagPatch.execute(day)
    return corrected
end

-- Dyagnostik PATCH 02 a konsève tras legacy ak tras koreksyon an.
function S.dayTagPatchProbe(day)
    return DayTagPatch.execute(day)
end

-- Antre istorik la kontinye montre ansyen parite ki mal la.
function S.legacyDayTagProbe(day)
    return LegacyDayTag.execute(day)
end

-- PATCH 03 korije distans ki soti nan legacy a san efase chemen sa a.
function S.distanceSpaghetti(calculationDay, targetDay)
    local corrected = DistancePatch.execute(calculationDay, targetDay)
    return corrected
end

-- Dyagnostik la ekspoze de handler ak de tranzaksyon distans yo.
function S.distancePatchProbe(calculationDay, targetDay)
    return DistancePatch.execute(calculationDay, targetDay)
end

-- Dyagnostik istorik la toujou bay diferans ant tag jou yo.
function S.legacyDistanceProbe(calculationDay, targetDay)
    return LegacyDistance.execute(calculationDay, targetDay)
end

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 7", 0)
end

return S
