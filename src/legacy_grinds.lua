local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyGrinds = {}

-- Fòm istwa a te yon tablo nimewote 0..10. Men bouk la mande 1..11.
-- Pa mete ranje sentinel a ni deplase ranje yo: sa se travay PATCH 07.
local ORIGINAL_ROWS = {
    [0]={3,5,7,11,"w"}, [1]={5,7,11,13,"b"},
    [2]={7,11,13,17,"s"}, [3]={11,13,17,19,"m"},
    [4]={13,17,19,23,"r"}, [5]={17,19,23,29,"w"},
    [6]={19,23,29,31,"b"}, [7]={23,29,31,37,"s"},
    [8]={29,31,37,41,"m"}, [9]={31,37,41,43,"r"},
    [10]={37,41,43,47,"w"}
}
local function cloneRow(row)
    if row == nil then return nil end
    return {a=row[1], b=row[2], c=row[3], d=row[4], kind=row[5]}
end
function LegacyGrinds.originalPhysicalRow(slot)
    assert(type(slot)=="number" and math.type(slot)=="integer" and slot>=0 and slot<=10,
           "Endis fizik tounaj la dwe ant 0 ak 10")
    return cloneRow(ORIGINAL_ROWS[slot])
end
function LegacyGrinds.oldGrindRow(g)
    assert(type(g)=="number" and math.type(g)=="integer" and g>=1 and g<=11,
           "Endis tounaj la dwe ant 1 ak 11")
    -- Erè istorik la: premye tounaj g=1 li dezyèm ranje fizik la.
    -- Dènye tounaj g=11 pa jwenn okenn ranje.
    return cloneRow(ORIGINAL_ROWS[g])
end
function LegacyGrinds.execute(g)
    local selected = LegacyGrinds.oldGrindRow(g)
    local context=Base.MonsterContext.new(g,g)
    context.mode="STAGE_14_DISCOVERY_07"
    context.phase="LEGACY_GRIND_INDEX"
    context.status="LEGACY_GRIND_PENDING"
    local manager=Base.MonsterManager.new(context)
    manager.dispatcher:register("LEGACY_GRIND_INDEX",function(active,owner)
        local missing=selected==nil
        local candidate={grind=g,physicalIndex=g,tableOrigin=0,expectedOrigin=1,
                         missing=missing, source="ZERO_BASED_ROWS_READ_AS_ONE_BASED",
                         a=missing and "MISSING" or selected.a,
                         b=missing and "MISSING" or selected.b,
                         c=missing and "MISSING" or selected.c,
                         d=missing and "MISSING" or selected.d,
                         kind=missing and "MISSING" or selected.kind}
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.grind.reads")
        if missing then owner.metricsManager:bump("legacy.grind.missingTail") end
        owner.metricsManager:observe("legacy.grind.index",tostring(g))
        active.diagnostics[#active.diagnostics+1]={
            code=missing and "GRIND_11_ROW_MISSING" or "GRIND_ROW_SHIFTED_BY_ONE",
            grind=g,physicalIndex=g}
        active.status=missing and "LEGACY_GRIND_MISSING" or "LEGACY_GRIND_RETURNED"
        return {found=not missing,row=cloneRow(ORIGINAL_ROWS[g])}
    end)
    local envelope=manager.dispatcher:dispatch(context,"LEGACY_GRIND_INDEX",manager)
    return envelope.row,context
end

-- Premye wout pwodiksyon gout vizib la itilize vre PATCH 06 ak wòch yo.
-- Li pa gen okenn remap/sentinel pou tablo grind la nan DISCOVERY 07.
function LegacyGrinds.visibleDropLegacy(c,t,i,dropStore)
    assert(type(i)=="number" and math.type(i)=="integer" and i>=1 and i<=46,
           "Endis gout vizib la dwe ant 1 ak 46")
    local DayTagPatch=require("day_tag_patch")
    local DistancePatch=require("distance_patch")
    local StonePatch=require("stone_patch")
    local PriorPatch=require("prior_patch")
    local SavePatch=require("save_patch")
    local action=DayTagPatch.execute(c)
    local target=DayTagPatch.execute(t)
    local distance=DistancePatch.execute(c,t)
    local connection=BigInt.add(action,target)
    local direction=BigInt.from(t<c and 1 or (t>c and 3 or 2))
    local stones=StonePatch.buildPatchedTable()[i]
    local p1=assert(PriorPatch.execute(dropStore,c,t,i,1),"Gout prior 1 manke")
    local p3=assert(PriorPatch.execute(dropStore,c,t,i,3),"Gout prior 3 manke")
    local p7=assert(PriorPatch.execute(dropStore,c,t,i,7),"Gout prior 7 manke")
    local x=BigInt.add(BigInt.mul(stones.w,action),BigInt.mul(stones.b,target))
    x=BigInt.add(x,BigInt.mul(stones.s,distance))
    x=BigInt.add(x,BigInt.mul(stones.m,connection))
    x=BigInt.add(x,BigInt.mul(stones.r,direction))
    x=BigInt.add(x,BigInt.add(p1,BigInt.mulSmall(p3,3)))
    x=SavePatch.savePatch(BigInt.add(x,BigInt.add(BigInt.mulSmall(p7,5),i)))
    local audit={}
    for g=1,11 do
        local row,context=LegacyGrinds.execute(g)
        audit[#audit+1]={grind=g,missing=row==nil,status=context.status}
        if row==nil then
            return nil,{status="LEGACY_VISIBLE_INCOMPLETE",missingGrind=g,
                        completedGrinds=g-1,trace=audit,visibleIndex=i}
        end
        local old=x
        local term=BigInt.add(BigInt.mul(old,old),BigInt.mulSmall(old,row.a))
        term=BigInt.add(term,BigInt.mulSmall(p1,row.b))
        term=BigInt.add(term,BigInt.mulSmall(p3,row.c))
        term=BigInt.add(term,BigInt.mulSmall(p7,row.d))
        x=SavePatch.savePatch(BigInt.add(term,stones[row.kind]))
    end
    return x,{status="LEGACY_VISIBLE_COMPLETE",trace=audit}
end
return LegacyGrinds
