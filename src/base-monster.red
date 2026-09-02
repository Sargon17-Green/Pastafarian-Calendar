Red [
    Title: "Неутрална основа будућег спагети чудовишта"
]

base-owned-copy: func [value] [
    case [
        object? value [copy/deep value]
        block? value [copy/deep value]
        map? value [copy/deep value]
        string? value [copy value]
        binary? value [copy value]
        true [value]
    ]
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
    append/only logs reduce [code base-owned-copy payload]
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
        rollbackSnapshot: none
        retryCount: 0
        metrics: none
        logs: none
        diagnostics: copy []
        lastError: none
    ]
    ctx/calculationDay: base-owned-copy calculation-day
    ctx/targetDay: base-owned-copy target-day
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
    e/detail: base-owned-copy detail
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

base-semantic-seed: func [ctx state] [
    ctx/semanticCommitted: base-owned-copy state
    ctx/semanticPending: none
    ctx/rollbackSnapshot: none
    base-owned-copy ctx/semanticCommitted
]

base-semantic-begin: func [ctx candidate-state] [
    ctx/rollbackSnapshot: base-owned-copy ctx/semanticCommitted
    ctx/semanticPending: base-owned-copy candidate-state
    base-owned-copy ctx/semanticPending
]

base-semantic-commit: func [ctx] [
    if none? ctx/semanticPending [return none]
    ctx/semanticCommitted: base-owned-copy ctx/semanticPending
    ctx/semanticPending: none
    ctx/rollbackSnapshot: none
    base-owned-copy ctx/semanticCommitted
]

base-semantic-rollback: func [ctx] [
    if not none? ctx/rollbackSnapshot [
        ctx/semanticCommitted: base-owned-copy ctx/rollbackSnapshot
    ]
    ctx/semanticPending: none
    ctx/rollbackSnapshot: none
    ctx/retryCount: ctx/retryCount + 1
    base-owned-copy ctx/semanticCommitted
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
