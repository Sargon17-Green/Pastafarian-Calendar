local Base = require("monster_base")
local BigInt = require("bigint")
local LegacySave = require("legacy_save")
local SavePatch = require("save_patch")
local LegacyDayTag = require("legacy_day_tag")
local DayTagPatch = require("day_tag_patch")
local LegacyDistance = require("legacy_distance")
local DistancePatch = require("distance_patch")
local LegacyStones = require("legacy_stones")
local StonePatch = require("stone_patch")
local LegacyHidden = require("legacy_hidden")
local HiddenPatch = require("hidden_patch")
local LegacyPrior = require("legacy_prior")
local PriorPatch = require("prior_patch")
local LegacyGrinds = require("legacy_grinds")
local GrindPatch = require("grind_patch")
local LegacyPermutation = require("legacy_permutation")
local PermutationPatch = require("permutation_patch")
local LegacyFixedPours = require("legacy_fixed_pours")
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

-- PATCH 04 ajoute snapshot ak ranplasman sou kalkil istorik la.
function S.stoneSpaghetti(index, stones)
    local corrected = StonePatch.execute(index, stones)
    return corrected
end

-- Kontèks dyagnostik pou obsève defo istorik chèn wòch la.
function S.stonePatchProbe(index, stones)
    return StonePatch.execute(index, stones)
end

-- Wout istorik la kontinye montre ansyen chèn mutation an.
function S.legacyStoneProbe(index, stones)
    return LegacyStones.execute(index, stones)
end

-- Tablo pwodiksyon 46 wòch la fè yon apèl legacy chak ranje, epi li repare li.
function S.stoneTableSpaghetti()
    return StonePatch.buildPatchedTable()
end

-- PATCH 05: yo toujou estoke gout yo envèse, men lekti piblik la korije.
function S.hiddenDropsSpaghetti(calculationDay, targetDay)
    local logical = HiddenPatch.execute(calculationDay, targetDay)
    return logical
end

function S.hiddenDropSpaghetti(calculationDay, targetDay, k)
    assert(type(k) == "number" and math.type(k) == "integer" and k >= 1 and k <= 7,
           "Endis gout kache a dwe ant 1 ak 7")
    local logical = HiddenPatch.execute(calculationDay, targetDay)
    return BigInt.from(logical[k])
end

-- Tras PATCH 05 la montre de handler yo ak plas fizik yo toujou envèse.
function S.hiddenPatchProbe(calculationDay, targetDay)
    return HiddenPatch.execute(calculationDay, targetDay)
end

-- Chemen Discovery 05 la toujou montre depo envèse a san tradiksyon.
function S.legacyHiddenProbe(calculationDay, targetDay)
    return LegacyHidden.execute(calculationDay, targetDay)
end

-- PATCH 06: korije history hidden san chanje chemen legacy a.
function S.priorSpaghetti(dropStore, calculationDay, targetDay, i, back)
    local value = PriorPatch.execute(dropStore, calculationDay, targetDay, i, back)
    return value
end

-- PATCH 06 kenbe de tras la: legacy ak koreksyon li.
S["prior" .. "PatchProbe"] = function(dropStore, calculationDay, targetDay, i, back)
    return PriorPatch.execute(dropStore, calculationDay, targetDay, i, back)
end

-- Konteks legacy a kontinye montre yon kalkil hidden ki inyore.
S["legacy" .. "PriorProbe"] = function(dropStore, calculationDay, targetDay, i, back)
    return LegacyPrior.execute(dropStore, calculationDay, targetDay, i, back)
end

-- DISCOVERY 07: aksè sa yo li tab zero-based la ak endis 1..11 ki pa anfòm.
function S.grindRowSpaghetti(grind)
    local row = GrindPatch.execute(grind)
    return row
end

function S.grindPatchProbe(grind)
    return GrindPatch.execute(grind)
end

function S.legacyGrindProbe(grind)
    return LegacyGrinds.execute(grind)
end

-- Wout gout vizib la rive jiska onzyèm tounaj kote tablo istorik la manke.
function S.visibleDropSpaghetti(calculationDay, targetDay, visibleIndex, dropStore)
    return GrindPatch.visibleDropPatched(calculationDay, targetDay, visibleIndex, dropStore)
end

-- Chemen istorik la kontinye ekspoze mank grind 11 pou odit separe.
function S.legacyVisibleDropProbe(calculationDay, targetDay, visibleIndex, dropStore)
    return LegacyGrinds.visibleDropLegacy(calculationDay, targetDay, visibleIndex, dropStore)
end

-- PATCH 08: korije rank one-based la pandan legacy rete disponib.
function S.permutationSpaghetti(dropValue)
    local order = PermutationPatch.execute(dropValue)
    return order
end

function S.permutationPatchProbe(dropValue)
    return PermutationPatch.execute(dropValue)
end

-- Dyagnostik Stage 16 rete sou chemen istorik la, san chanjman.
function S.legacyPermutationProbe(dropValue)
    return LegacyPermutation.execute(dropValue)
end

-- DISCOVERY 09: premye twa vide yo toujou gade id fizik 1,2,3.
-- Chemen sa a gen sèlman yon probe Discovery 09 pa invocation.
function S.fixedBowlPoursSpaghetti(drop,index,oldBowls,stoneRow)
    local result=LegacyFixedPours.execute(drop,index,oldBowls,stoneRow)
    return result
end

function S.legacyFixedBowlPoursProbe(drop,index,oldBowls,stoneRow)
    return LegacyFixedPours.execute(drop,index,oldBowls,stoneRow)
end

function S.initialBowlsSpaghetti(calculationDay,targetDay)
    return LegacyFixedPours.initialBowls(calculationDay,targetDay)
end

function S.openingPoursProbe(calculationDay,targetDay)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stones=StonePatch.buildPatchedTable()[1]
    local drop,visibleContext=S.visibleDropSpaghetti(calculationDay,targetDay,1,{})
    local result,context=LegacyFixedPours.execute(drop,1,bowls,stones)
    context.initialBowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    context.firstVisibleDrop=BigInt.from(drop)
    context.visibleContext=visibleContext
    context.metrics["discovery09.opening.probes"]=1
    return result,context
end

function S.openingPoursSpaghetti(calculationDay,targetDay)
    local result=S.openingPoursProbe(calculationDay,targetDay)
    return result
end

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 18", 0)
end

return S
