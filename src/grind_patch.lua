local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyGrinds = require("legacy_grinds")
local GrindPatch = {}

local function cloneRow(row)
    if row == nil then return nil end
    return {a=row.a,b=row.b,c=row.c,d=row.d,kind=row.kind}
end

local function requireGrind(g)
    assert(type(g)=="number" and math.type(g)=="integer" and g>=1 and g<=11,
           "Endis tounaj la dwe yon antye ant 1 ak 11")
end

-- Sentinel fizik la rete nan index 0; onz ranje reyèl yo nan 1..11.
-- Kontni yo sòti nan tab legacy istorik la, san modifier tab sa a.
function GrindPatch.buildWithSentinel()
    local rows={[0]={a=0,b=0,c=0,d=0,kind="NONE"}}
    for g=1,11 do
        rows[g]=LegacyGrinds.originalPhysicalRow(g-1)
    end
    return rows
end

function GrindPatch.grindRowPatch(g)
    requireGrind(g)
    -- Egzèsis indexing legacy sa a dwe reyèl, pa retire l.
    LegacyGrinds.oldGrindRow(g)
    local storage=GrindPatch.buildWithSentinel()
    return cloneRow(storage[g])
end

function GrindPatch.execute(g)
    requireGrind(g)
    local wrong, context=LegacyGrinds.execute(g)
    local before=cloneRow(wrong)
    local manager=Base.MonsterManager.new(context)
    context.phase="PATCH_GRIND_INDEX"
    context.mode="STAGE_15_PATCH_07"
    context.status="PATCH_GRIND_PENDING"
    manager.dispatcher:register("GRIND_PATCH",function(active,owner)
        local storage=GrindPatch.buildWithSentinel()
        local fixed=cloneRow(storage[g])
        local sentinel=storage[0]
        local state={
            grind=g,physicalIndex=g,origin=1,source="SENTINEL_ROW_ZERO_REAL_ROWS_ONE_TO_ELEVEN",
            legacyCallPreserved=true,legacyMissing=before==nil,
            legacyA=before and before.a or "MISSING",
            legacyB=before and before.b or "MISSING",
            legacyC=before and before.c or "MISSING",
            legacyD=before and before.d or "MISSING",
            legacyKind=before and before.kind or "MISSING",
            sentinelA=sentinel.a,sentinelB=sentinel.b,sentinelC=sentinel.c,
            sentinelD=sentinel.d,sentinelKind=sentinel.kind,
            a=fixed.a,b=fixed.b,c=fixed.c,d=fixed.d,kind=fixed.kind
        }
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("grind.patch.calls")
        owner.metricsManager:bump("grind.patch.sentinelReads")
        owner.metricsManager:observe("grind.patch.realIndex",tostring(g))
        active.diagnostics[#active.diagnostics+1]={
            code="PATCH_07_SENTINEL_PRESERVES_LEGACY",
            grind=g,legacyMissing=before==nil,
            sentinelKind=sentinel.kind,correctKind=fixed.kind
        }
        active.status="PATCH_GRIND_RETURNED"
        return cloneRow(fixed)
    end)
    local result=manager.dispatcher:dispatch(context,"GRIND_PATCH",manager)
    return result,context
end

-- Wout pwodiksyon yon gout vizib itilize fèmti PATCH 06 la ak 11 grind PATCH 07.
-- Nou pa kouri algoritm pwochen etap la: rank/bowls rete pou Stage 16+.
function GrindPatch.visibleDropPatched(c,t,i,dropStore)
    assert(type(i)=="number" and math.type(i)=="integer" and i>=1 and i<=46,
           "Endis gout vizib la dwe yon antye ant 1 ak 46")
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
    local trace={}
    for g=1,11 do
        local row,ctx=GrindPatch.execute(g)
        trace[#trace+1]={grind=g,legacyMissing=ctx.semanticState.legacyMissing,
                         phase=ctx.phase,commits=ctx.commitToken}
        local old=x
        local term=BigInt.add(BigInt.mul(old,old),BigInt.mulSmall(old,row.a))
        term=BigInt.add(term,BigInt.mulSmall(p1,row.b))
        term=BigInt.add(term,BigInt.mulSmall(p3,row.c))
        term=BigInt.add(term,BigInt.mulSmall(p7,row.d))
        x=SavePatch.savePatch(BigInt.add(term,stones[row.kind]))
    end
    return x,{status="PATCH_VISIBLE_COMPLETE",completedGrinds=11,
              visibleIndex=i,trace=trace,legacyCallsPreserved=11}
end

return GrindPatch
