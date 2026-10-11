local Base = require("monster_base")
local LegacySave = require("legacy_save")
local SavePatch = require("save_patch")
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

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 3", 0)
end

return S
