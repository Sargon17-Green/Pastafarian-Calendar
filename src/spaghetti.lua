local Base = require("monster_base")
local LegacySave = require("legacy_save")
local S = {}

function S.bootstrapProbe(calculationDay, targetDay)
    local context = Base.MonsterContext.new(calculationDay, targetDay)
    local manager = Base.MonsterManager.new(context)
    return manager:runBootstrapProbe()
end

-- Chemen otoritè pwovizwa a konekte ak legacy depi Discovery 01.
-- PATCH 01 pral kapab mete yon kouch sou wout sa a san efase legacy a.
function S.saveSpaghetti(value)
    local wrong = LegacySave.execute(value)
    return wrong
end

-- Antre dyagnostik la toujou bay rezilta legacy orijinal la.
function S.legacySaveProbe(value)
    return LegacySave.execute(value)
end

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 2", 0)
end

return S
