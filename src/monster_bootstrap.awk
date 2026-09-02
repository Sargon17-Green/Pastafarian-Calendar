# Nøytral grunnmur for monsteret. Ingen historiske feil eller framtidige lappingar finst i Stage 1.

function monster_metrics_reset() { delete MONSTER_METRICS }
function monster_logs_reset() { delete MONSTER_LOGS; MONSTER_LOG_COUNT=0 }

function monster_context_reset(cday,tday) {
    delete MONSTER_CTX
    MONSTER_CTX["calculationDay"]=cday
    MONSTER_CTX["targetDay"]=tday
    MONSTER_CTX["phase"]="BOOTSTRAP"
    MONSTER_CTX["subPhase"]=0
    MONSTER_CTX["mode"]="BASE"
    MONSTER_CTX["status"]="NEW"
    MONSTER_CTX["retryBudget"]=0
    MONSTER_CTX["recoveryDepth"]=0
    MONSTER_CTX["currentHandler"]="BaseDispatcher"
    MONSTER_CTX["previousHandler"]="NONE"
    MONSTER_CTX["lastError"]="NONE"
    MONSTER_CTX["semanticOwner"]="INVOCATION"
    MONSTER_CTX["pendingSemanticState"]="NONE"
    MONSTER_CTX["commitToken"]="UNSET"
}

function monster_metric_bump(key) { MONSTER_METRICS[key]++ }
function monster_log(code,value) { MONSTER_LOGS[++MONSTER_LOG_COUNT]=code SUBSEP value }

function monster_validate_base_context(    ok) {
    ok=1
    if (!("calculationDay" in MONSTER_CTX)) ok=0
    if (!("targetDay" in MONSTER_CTX)) ok=0
    if (MONSTER_CTX["semanticOwner"]!="INVOCATION") ok=0
    if (!ok) MONSTER_CTX["lastError"]="ugyldig grunnkontekst"
    return ok
}

function monster_base_dispatch(cday,tday) {
    monster_context_reset(cday,tday)
    monster_metric_bump("bootstrap.dispatch")
    monster_log("bootstrap-enter",cday ":" tday)
    if (!monster_validate_base_context()) {
        MONSTER_CTX["status"]="FAILED_VALIDATION"
        return 0
    }
    MONSTER_CTX["phase"]="BOOTSTRAP_READY"
    MONSTER_CTX["status"]="READY"
    return 1
}

function calendarDateSpaghetti(cday,tday) {
    monster_base_dispatch(cday,tday)
    MONSTER_CTX["status"]="NOT_IMPLEMENTED_BEFORE_INTEGRATION"
    MONSTER_CTX["lastError"]="produksjonsbanen er med vilje ikkje bygd i bootstrap-steget"
    return 0
}
