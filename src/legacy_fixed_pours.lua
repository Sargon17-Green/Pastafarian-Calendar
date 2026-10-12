-- DISCOVERY 09: lòd permutation la kòrèk, men twa vide yo li bòl 1, 2, 3.
-- Pa fè koreksyon alias bòl ni melanj bòl (Stage 19+).
local B = require("bigint")
local Base = require("monster_base")
local Save = require("save_patch")
local DayTag = require("day_tag_patch")
local Distance = require("distance_patch")
local Permutation = require("permutation_patch")

local LegacyFixedPours = {}
local PRIMES = {17,19,23,29,31,37}
local NAMES = {"w","b","s"}
local FACTORS = {3,5,7}

local function copyBigints(values,limit)
    local result={}
    for j=1,limit do result[j]=B.from(values[j]) end
    return result
end

local function copyOrder(order)
    local out={}
    for i=1,6 do out[i]=order[i] end
    return out
end

local function validate(index,oldBowls,stoneRow)
    assert(type(index)=="number" and math.type(index)=="integer" and
           index>=1 and index<=46, "Endis gout vizib la dwe 1..46")
    assert(type(oldBowls)=="table" and type(stoneRow)=="table",
           "Bòl ak wòch yo dwe tablo")
    for j=1,6 do B.from(assert(oldBowls[j],"Bòl istorik manke")) end
    assert(oldBowls[7]==nil,"Gen plis pase sis bòl")
    for _,name in ipairs({"w","b","s","m","r"}) do
        B.from(assert(stoneRow[name],"Wòch istorik manke"))
    end
end

-- Premye eta sis bòl yo: menm kontè patch 01/02/03 ak wout pwodiksyon.
-- Nou pa manyen bòl sa yo pandan okenn vide.
function LegacyFixedPours.initialBowls(calculationDay,targetDay)
    local BaseDay=Base.MonsterManager.new(Base.MonsterContext.new(calculationDay,targetDay))
    BaseDay.validationManager:requireIntegerDay(calculationDay,"Jou kalkil")
    BaseDay.validationManager:requireIntegerDay(targetDay,"Jou sib")
    local action=DayTag.execute(calculationDay)
    local target=DayTag.execute(targetDay)
    local distance=Distance.execute(calculationDay,targetDay)
    local connection=B.add(action,target)
    local direction=B.from(targetDay<calculationDay and 1 or
                           (targetDay>calculationDay and 3 or 2))
    local bowls={}
    for id=1,6 do
        local s=B.add(B.mulSmall(target,id),action)
        s=B.add(s,distance)
        s=B.add(s,connection)
        s=B.add(s,direction)
        s=B.add(s,PRIMES[id]*PRIMES[id])
        bowls[id]=Save.savePatch(B.add(B.mul(s,s),id))
    end
    return copyBigints(bowls,6)
end

local function verifyCorrectedOrder(order,context)
    assert(type(order)=="table" and #order==6,
           "Lòd PATCH 08 la pa yon permutation sis bòl")
    assert(type(context)=="table" and context.mode=="STAGE_17_PATCH_08"
           and context.status=="PATCH_PERM_RETURNED" and context.commitToken==3,
           "Tras PATCH 08 la pa konplè")
    local unique={}
    for position=1,6 do
        local id=order[position]
        assert(type(id)=="number" and math.type(id)=="integer"
               and id>=1 and id<=6 and not unique[id],
               "Bòl permutation la repete oubyen pa valab")
        unique[id]=true
    end
    assert(context.semanticState.permutation==table.concat(order,","),
           "Lòd PATCH 08 la pa dakò ak tras otoritè li")
end

-- Pa chanje erè istorik la: oldBowls[position] olye oldBowls[order[position]].
-- Permutation.execute se PATCH 08 reyèl la, pa yon oracle test.
function LegacyFixedPours.legacyPoursToFixedBowlIds(drop,index,oldBowls,stoneRow)
    validate(index,oldBowls,stoneRow)
    local value=B.from(drop)
    local order,permutationContext=Permutation.execute(value)
    verifyCorrectedOrder(order,permutationContext)
    local square=B.mul(value,value)
    local pours={}
    for position=1,3 do
        local fromFixedBowl=B.from(oldBowls[position])
        local stone=B.from(stoneRow[NAMES[position]])
        local amount=B.add(square,B.mul(stone,fromFixedBowl))
        amount=B.add(amount,FACTORS[position]*index)
        pours[position]=Save.savePatch(amount)
    end
    return copyBigints(pours,3),copyOrder(order),permutationContext
end

function LegacyFixedPours.execute(drop,index,oldBowls,stoneRow)
    validate(index,oldBowls,stoneRow)
    local pours,order,permutationContext=
        LegacyFixedPours.legacyPoursToFixedBowlIds(drop,index,oldBowls,stoneRow)
    local context=Base.MonsterContext.new(index,index)
    context.phase="LEGACY_FIXED_BOWL_POURS"
    context.mode="STAGE_18_DISCOVERY_09"
    context.status="LEGACY_POURS_PENDING"
    context.permutationContext=permutationContext
    local manager=Base.MonsterManager.new(context)
    manager.dispatcher:register("LEGACY_FIXED_BOWL_POURS",function(active,owner)
        local before=copyBigints(oldBowls,6)
        local state={
            source="FIXED_BOWL_IDS_IGNORE_PERMUTATION",
            dropDecimal=tostring(B.from(drop)),
            visibleIndex=index,
            correctedOrder=copyOrder(order),
            fixedBowlIds={1,2,3},
            usedBowlIds={1,2,3},
            historicalWrongPours={},
            initialBowlDecimals={},
            stones={}
        }
        for j=1,6 do state.initialBowlDecimals[j]=tostring(before[j]) end
        for j=1,3 do state.historicalWrongPours[j]=tostring(pours[j]) end
        for _,name in ipairs({"w","b","s","m","r"}) do
            state.stones[name]=tostring(B.from(stoneRow[name]))
        end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.fixedPour.calls")
        owner.metricsManager:observe("legacy.fixedPour.lastIndex",tostring(index))
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_09_POURS_TO_FIXED_IDS",
            correctedOrder=copyOrder(order),
            fixedBowlIds={1,2,3},
            ignoredPermutation=true
        }
        active.status="LEGACY_FIXED_BOWL_POURS_RETURNED"
        return copyBigints(pours,3)
    end)
    return copyBigints(manager.dispatcher:dispatch(
        context,"LEGACY_FIXED_BOWL_POURS",manager),3),context
end

return LegacyFixedPours
