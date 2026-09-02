local Base = require("monster_base")
local S = {}

function S.bootstrapProbe(calculationDay, targetDay)
    local context = Base.MonsterContext.new(calculationDay, targetDay)
    local manager = Base.MonsterManager.new(context)
    return manager:runBootstrapProbe()
end

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 1", 0)
end

return S
