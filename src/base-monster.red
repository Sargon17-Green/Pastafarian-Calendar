Red [
    Title: "Неутрална основа будућег спагети чудовишта"
]

make-base-metrics: func [] [
    make object! [
        counters: make map! []
        events: copy []
    ]
]

metrics-bump: func [metrics key [string!] /local old] [
    old: select metrics/counters key
    if none? old [old: 0]
    put metrics/counters key old + 1
    old + 1
]

make-base-logs: func [] [copy []]

log-observation: func [logs code payload] [
    append/only logs reduce [code payload]
    logs
]

make-base-context: func [calculation-day target-day /local ctx] [
    ctx: make object! [
        calculationDay: none
        targetDay: none
        phase: 'bootstrap
        subPhase: 0
        status: 'new
        currentHandler: none
        previousHandler: none
        branchTrace: copy []
        semanticCommitted: none
        semanticPending: none
        metrics: none
        logs: none
        diagnostics: copy []
        lastError: none
    ]
    ctx/calculationDay: calculation-day
    ctx/targetDay: target-day
    ctx/metrics: make-base-metrics
    ctx/logs: make-base-logs
    ctx
]

base-validate-input: func [ctx] [
    all [not none? ctx/calculationDay not none? ctx/targetDay]
]

base-error-wrap: func [code detail /local e] [
    e: make object! [code: none detail: none]
    e/code: code
    e/detail: detail
    e
]

base-dispatch: func [ctx handler [function!] /local previous result] [
    previous: ctx/currentHandler
    ctx/previousHandler: previous
    ctx/currentHandler: 'base-handler
    append/only ctx/branchTrace 'base-dispatch
    result: handler ctx
    ctx/previousHandler: ctx/currentHandler
    ctx/currentHandler: previous
    result
]

bootstrap-production-handler: func [ctx] [
    either base-validate-input ctx [
        ctx/status: 'bootstrap-only
        metrics-bump ctx/metrics "bootstrap.production.entry"
        none
    ][
        ctx/status: 'invalid-input
        ctx/lastError: base-error-wrap 'invalid-input "Улаз за основни контекст није потпун."
        none
    ]
]

calendarDateSpaghetti: func [calculationDay targetDay /local ctx] [
    ctx: make-base-context calculationDay targetDay
    base-dispatch ctx :bootstrap-production-handler
]
