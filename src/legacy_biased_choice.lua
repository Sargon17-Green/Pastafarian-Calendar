-- DISCOVERY 13: repons SAVE ki valab, men chwa legacy a pran mod dirèk.
-- Pa gen okenn tès akseptasyon, rejè oswa koreksyon PATCH 13 isit la.
-- Limit Stage 26: kantite opsyon 1..M, kouch seleksyon izole.
local B=require("bigint")
local Base=require("monster_base")
local Save=require("save_patch")
local Legacy={}
local ONE=B.from(1)
local ZERO=B.from(0)
local M=B.from("170141183460469231731687303715884105727")

local function streamInput(first,direction)
    local seed=B.from(first)
    assert(B.compare(seed,ONE)>=0 and B.compare(seed,M)<=0,
           "Premye repons la dwe 1..M")
    assert(type(direction)=="number" and math.type(direction)=="integer"
        and (direction==1 or direction==-1),
        "Direksyon an dwe +1 oswa -1")
    return seed,direction
end

local function shortSize(n)
    local count=B.from(n)
    assert(B.compare(count,ONE)>=0 and B.compare(count,M)<=0,
        "DISCOVERY 13 mande 1 <= N <= M; detou laj poko antre")
    return count
end

-- Sous kòrèk pou nenpòt k >= 0: A_k=SAVE(A_0 + direction*k).
-- Li pa janm fè seleksyon, kidonk li pa gen bias pou kont li.
function Legacy.answerAt(first,direction,k)
    local seed,step=streamInput(first,direction)
    local offset=B.from(k)
    assert(B.compare(offset,ZERO)>=0,"Endis repons lan dwe k>=0")
    return Save.savePatch(B.add(seed,B.mulSmall(offset,step)))
end

-- Erè istorik la: legim mod dirèk sou A_0; li pa konsome A_1...
-- PATCH 13 dwe konsève fonksyon sa a e aplike rejection sampling apa.
function Legacy.oldBiasedModuloPick(first,direction,n)
    local firstAnswer=Legacy.answerAt(first,direction,0)
    local size=shortSize(n)
    return B.add(ONE,B.mod(B.sub(firstAnswer,ONE),size))
end

function Legacy.execute(first,direction,n)
    -- Echèk validation anvan kreye semantic state ak commitment.
    local seed,step=streamInput(first,direction)
    local size=shortSize(n)
    local context=Base.MonsterContext.new(1,1)
    context.mode="STAGE_26_DISCOVERY_13"
    context.phase="LEGACY_ANSWER_STREAM"
    context.status="LEGACY_BIASED_PICK_PENDING"
    local manager=Base.MonsterManager.new(context)
    manager.dispatcher:register("LEGACY_REPLY_STREAM",function(active,owner)
        local a0=Legacy.answerAt(seed,step,0)
        local a1=Legacy.answerAt(seed,step,1)
        local am=B.compare(a0,ONE)>0 and
            Legacy.answerAt(seed,step,B.sub(M,ONE)) or nil
        assert(B.compare(a0,seed)==0,"Sous A0 la pa matche")
        active:beginSemanticUpdate({
            source="VALID_SAVE_ANSWER_STREAM",
            firstDecimal=tostring(a0),
            directionStep=step,
            modulusDecimal=tostring(M),
            nextDecimal=tostring(a1),
            optionalNearWrapDecimal=am and tostring(am) or nil,
            sampleCount=0
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.replyStream.calls")
        owner.metricsManager:observe("legacy.replyStream.first",tostring(a0))
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_13_VALID_SAVE_REPLY_STREAM",
            first=tostring(a0),direction=step,next=tostring(a1)
        }
        active.status="REPLY_STREAM_READY"
        return B.from(a0)
    end)
    local firstReply=manager.dispatcher:dispatch(context,"LEGACY_REPLY_STREAM",manager)
    context.phase="LEGACY_DIRECT_MODULO_SELECTION"
    manager.dispatcher:register("LEGACY_BIASED_MODULO_PICK",function(active,owner)
        local rank=Legacy.oldBiasedModuloPick(firstReply,step,size)
        assert(B.compare(rank,ONE)>=0 and B.compare(rank,size)<=0,
            "Legacy chwa a depase kantite opsyon")
        local state={
            source="LEGACY_DIRECT_MODULO_WITHOUT_REJECTION",
            firstDecimal=tostring(firstReply),
            nextDecimal=tostring(Legacy.answerAt(firstReply,step,1)),
            directionStep=step,
            optionCountDecimal=tostring(size),
            resultRankDecimal=tostring(rank),
            sampleIndex=0,
            consumedAnswerCount=1,
            ignoredFurtherAnswers=true,
            didApplyAcceptanceThreshold=false,
            legacyModuloBiasPreserved=true,
            shortPathOnly=true
        }
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.biasedModulo.calls")
        owner.metricsManager:observe("legacy.biasedModulo.rank",tostring(rank))
        owner.metricsManager:observe("legacy.biasedModulo.answerCount",1)
        active.diagnostics[#active.diagnostics+1]={
            code="DISCOVERY_13_SKIPS_ACCEPTANCE_LIMIT",
            rank=tostring(rank),first=tostring(firstReply),
            optionCount=tostring(size),consumed=1,thresholdChecked=false
        }
        active.status="LEGACY_BIASED_PICK_COMPLETE"
        return B.from(rank)
    end)
    local wrong=manager.dispatcher:dispatch(context,"LEGACY_BIASED_MODULO_PICK",manager)
    return B.from(wrong),context
end

return Legacy
