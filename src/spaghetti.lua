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
local PourPatch = require("pour_patch")
local LegacyAliasedStir = require("legacy_aliased_stir")
local StirPatch = require("stir_patch")
local LegacyResetChain = require("legacy_reset_chain")
local BowlChainPatch = require("bowl_chain_patch")
local LegacyFixedNeighbor = require("legacy_fixed_neighbor")
local NeighborPatch = require("neighbor_patch")
local LegacyBiasedChoice = require("legacy_biased_choice")
local ShortChoicePatch = require("short_choice_patch")
local LegacyShortOnlyChoice = require("legacy_short_only_choice")
local WideChoicePatch = require("wide_choice_patch")
local LegacyGateQuestionAdapter = require("legacy_gate_question_adapter")
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

-- PATCH 09: chemen piblik la li id bòl ki soti nan permutation PATCH 08.
function S.fixedBowlPoursSpaghetti(drop,index,oldBowls,stoneRow)
    local result=PourPatch.execute(drop,index,oldBowls,stoneRow)
    return result
end

function S.pourPatchProbe(drop,index,oldBowls,stoneRow)
    return PourPatch.execute(drop,index,oldBowls,stoneRow)
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
    context.initialBowls={}
    for id=1,6 do context.initialBowls[id]=BigInt.from(bowls[id]) end
    context.firstVisibleDrop=BigInt.from(drop)
    context.visibleContext=visibleContext
    context.metrics["discovery09.opening.probes"]=1
    return result,context
end

function S.openingPoursPatchProbe(calculationDay,targetDay)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stones=StonePatch.buildPatchedTable()[1]
    local drop,visibleContext=S.visibleDropSpaghetti(calculationDay,targetDay,1,{})
    local corrected,context=PourPatch.execute(drop,1,bowls,stones)
    context.initialBowls={}
    for id=1,6 do context.initialBowls[id]=BigInt.from(bowls[id]) end
    context.firstVisibleDrop=BigInt.from(drop)
    context.visibleContext=visibleContext
    context.metrics["patch09.opening.probes"]=1
    return corrected,context
end

function S.openingPoursSpaghetti(calculationDay,targetDay)
    local result=S.openingPoursPatchProbe(calculationDay,targetDay)
    return result
end

-- PATCH 10 separe snapshot old ak destinasyon sis bòl yo.
function S.aliasedStirSpaghetti(drop,index,bowls,stones)
    local result=StirPatch.execute(drop,index,bowls,stones)
    return result
end

function S.stirPatchProbe(drop,index,bowls,stones)
    return StirPatch.execute(drop,index,bowls,stones)
end

function S.legacyAliasedStirProbe(drop,index,bowls,stones)
    return LegacyAliasedStir.execute(drop,index,bowls,stones)
end

function S.openingStirProbe(calculationDay,targetDay)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stones=StonePatch.buildPatchedTable()[1]
    local drop,visibleContext=S.visibleDropSpaghetti(calculationDay,targetDay,1,{})
    local result,context=LegacyAliasedStir.execute(drop,1,bowls,stones)
    context.firstVisibleDrop=BigInt.from(drop)
    context.visibleContext=visibleContext
    context.metrics["discovery10.opening.probes"]=1
    return result,context
end

function S.openingStirPatchProbe(calculationDay,targetDay)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stones=StonePatch.buildPatchedTable()[1]
    local drop,visibleContext=S.visibleDropSpaghetti(calculationDay,targetDay,1,{})
    local result,context=StirPatch.execute(drop,1,bowls,stones)
    context.firstVisibleDrop=BigInt.from(drop)
    context.visibleContext=visibleContext
    context.metrics["patch10.opening.probes"]=1
    return result,context
end

function S.openingStirSpaghetti(calculationDay,targetDay)
    local result=S.openingStirPatchProbe(calculationDay,targetDay)
    return result
end

-- DISCOVERY 11: premye brase a kòrèk, men chak gout apre sa
-- rdemare sou sis bòl inisyal yo olye rezilta gout anvan an.
function S.resetBowlsSpaghetti(drops,stoneRows,initialBowls)
    local result=BowlChainPatch.execute(drops,stoneRows,initialBowls)
    return result
end

-- PATCH 11 kenbe tras DISCOVERY 11 an epi ajoute yon dezyèm commit.
function S.bowlChainPatchProbe(drops,stoneRows,initialBowls)
    return BowlChainPatch.execute(drops,stoneRows,initialBowls)
end

function S.legacyResetBowlsProbe(drops,stoneRows,initialBowls)
    return LegacyResetChain.execute(drops,stoneRows,initialBowls)
end

function S.visibleResetChainProbe(calculationDay,targetDay,count)
    assert(type(count)=="number" and math.type(count)=="integer"
        and count>=1 and count<=46,"Kantite gout vizib dwe 1..46")
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stoneTable=StonePatch.buildPatchedTable()
    local drops,stones,dropStore,visibleContexts={},{},{},{}
    for i=1,count do
        local drop,ctx=S.visibleDropSpaghetti(calculationDay,targetDay,i,dropStore)
        assert(ctx.status=="PATCH_VISIBLE_COMPLETE"
           and ctx.completedGrinds==11,
           "Gout vizib PATCH 07 pa konplè")
        drops[i]=BigInt.from(drop)
        dropStore[i]=BigInt.from(drop)
        stones[i]=stoneTable[i]
        visibleContexts[i]=ctx
    end
    local result,context=LegacyResetChain.execute(drops,stones,bowls)
    context.visibleContexts=visibleContexts
    context.visibleDropCount=count
    context.metrics["discovery11.visible.calls"]=1
    return result,context
end

function S.visibleBowlChainPatchProbe(calculationDay,targetDay,count)
    assert(type(count)=="number" and math.type(count)=="integer"
        and count>=1 and count<=46,"Kantite gout vizib dwe 1..46")
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local stoneTable=StonePatch.buildPatchedTable()
    local drops,stones,store,visibleContexts={},{},{},{}
    for i=1,count do
        local drop,child=S.visibleDropSpaghetti(calculationDay,targetDay,i,store)
        assert(child.status=="PATCH_VISIBLE_COMPLETE"
            and child.completedGrinds==11,"Gout vizib PATCH 07 pa konplè")
        drops[i]=BigInt.from(drop)
        store[i]=BigInt.from(drop)
        stones[i]=stoneTable[i]
        visibleContexts[i]=child
    end
    local corrected,context=BowlChainPatch.execute(drops,stones,bowls)
    context.visibleContexts=visibleContexts
    context.visibleDropCount=count
    context.metrics["patch11.visible.calls"]=1
    return corrected,context
end

function S.visibleResetChainSpaghetti(calculationDay,targetDay,count)
    local result=S.visibleBowlChainPatchProbe(calculationDay,targetDay,count)
    return result
end

-- DISCOVERY 12: li lòd 46 gout korije yo, men chwazi vwazen pa id fiks.
function S.nextBowlSpaghetti(drops,stoneRows,initialBowls,queriedId)
    local corrected=NeighborPatch.execute(drops,stoneRows,initialBowls,queriedId)
    return corrected
end

function S.legacyFixedNeighborProbe(drops,stoneRows,initialBowls,queriedId)
    return LegacyFixedNeighbor.execute(drops,stoneRows,initialBowls,queriedId)
end

-- Non siklik sa a toujou mal pou pifò permutation, san efè sou state.
function S.oldNextBowlFixedNameProbe(queriedId)
    return LegacyFixedNeighbor.oldNextBowlFixedName(queriedId)
end

-- Sa se chemen 46 gout otantik: PATCH 01–11, apre sa legacy vwazen.
function S.visibleFixedNeighborProbe(calculationDay,targetDay,queriedId)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local rocks=StonePatch.buildPatchedTable()
    local drops,stones,store,contexts={},{},{},{}
    for i=1,46 do
        local drop,child=S.visibleDropSpaghetti(calculationDay,targetDay,i,store)
        assert(child.status=="PATCH_VISIBLE_COMPLETE" and child.completedGrinds==11,
            "Gout vizib PATCH 07 pa konplè")
        drops[i]=BigInt.from(drop)
        store[i]=BigInt.from(drop)
        stones[i]=rocks[i]
        contexts[i]=child
    end
    local fixed,context=LegacyFixedNeighbor.execute(drops,stones,bowls,queriedId)
    context.visibleDropContexts=contexts
    context.metrics["discovery12.visible.calls"]=1
    context.visibleDropCount=46
    return fixed,context
end

function S.visibleFixedNeighborSpaghetti(calculationDay,targetDay,queriedId)
    local fixed=S.visibleFixedNeighborProbe(calculationDay,targetDay,queriedId)
    return fixed
end

-- PATCH 12 ekspoze nwayo, legacy ak lòd gout 46 san chanje istorik la.
function S.neighborPatchProbe(drops,stoneRows,initialBowls,queriedId)
    return NeighborPatch.execute(drops,stoneRows,initialBowls,queriedId)
end

function S.nextInDrop46OrderProbe(order,queriedId)
    return NeighborPatch.nextInOrder(order,queriedId)
end

function S.visibleNeighborPatchProbe(calculationDay,targetDay,queriedId)
    local bowls=LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local rocks=StonePatch.buildPatchedTable()
    local drops,stones,store,contexts={},{},{},{}
    for i=1,46 do
        local drop,child=S.visibleDropSpaghetti(calculationDay,targetDay,i,store)
        assert(child.status=="PATCH_VISIBLE_COMPLETE" and child.completedGrinds==11,
            "PATCH 12: gout vizib PATCH 07 pa konplè")
        drops[i]=BigInt.from(drop)
        store[i]=BigInt.from(drop)
        stones[i]=rocks[i]
        contexts[i]=child
    end
    local corrected,context=NeighborPatch.execute(drops,stones,bowls,queriedId)
    context.visibleDropContexts=contexts
    context.visibleDropCount=46
    context.metrics["patch12.visible.calls"]=1
    return corrected,context
end

function S.visibleNeighborSpaghetti(calculationDay,targetDay,queriedId)
    local nextId=S.visibleNeighborPatchProbe(calculationDay,targetDay,queriedId)
    return nextId
end

-- DISCOVERY 13: sous repons lan kòrèk; modulo san rejection se defo istorik.
function S.answerAtSpaghetti(first,direction,k)
    return LegacyBiasedChoice.answerAt(first,direction,k)
end

function S.legacyBiasedChoiceProbe(first,direction,optionCount)
    return LegacyBiasedChoice.execute(first,direction,optionCount)
end

function S.oldBiasedModuloPickProbe(first,direction,optionCount)
    return LegacyBiasedChoice.oldBiasedModuloPick(first,direction,optionCount)
end

-- Stage 28: short rete PATCH 13, men wide route toujou eseye short la.
function S.choiceSpaghetti(first,direction,optionCount)
    local size=BigInt.from(optionCount)
    if BigInt.compare(size,BigInt.from("170141183460469231731687303715884105727"))>0 then
        local corrected=WideChoicePatch.execute(first,direction,optionCount)
        return corrected
    end
    local corrected=ShortChoicePatch.execute(first,direction,optionCount)
    return corrected
end

-- PATCH 13 rejte repons ki pi gran pase limit, san efase modulo legacy.
function S.shortChoicePatchProbe(first,direction,optionCount)
    return ShortChoicePatch.execute(first,direction,optionCount)
end

function S.shortChoiceCoreProbe(first,direction,optionCount)
    return ShortChoicePatch.chooseShort(first,direction,optionCount)
end

-- DISCOVERY 14: mòd legacy short-only ak tras blokaj N>M.
function S.legacyShortOnlyChoiceProbe(first,direction,optionCount)
    return LegacyShortOnlyChoice.execute(first,direction,optionCount)
end

-- PATCH 14: tras legacy laj, apre sa dezyèm commit ki bay rank laj.
function S.wideChoicePatchProbe(first,direction,optionCount)
    return WideChoicePatch.execute(first,direction,optionCount)
end

function S.wideChoiceCoreProbe(first,direction,optionCount)
    return WideChoicePatch.chooseWide(first,direction,optionCount)
end

-- DISCOVERY 15: adaptè istorik la pèdi siy etap negatif pòtay yo.
function S.legacyGateQuestionProbe(signedStep)
    return LegacyGateQuestionAdapter.execute(signedStep)
end

function S.oldGateQuestionDayProbe(distance)
    return LegacyGateQuestionAdapter.oldGateQuestionDay(distance)
end

function S.gateQuestionDaySpaghetti(signedStep)
    local wrong=LegacyGateQuestionAdapter.execute(signedStep)
    return wrong
end

function S.calendarDateSpaghetti()
    error("calendarDateSpaghetti poko entegre nan Stage 30", 0)
end

return S
