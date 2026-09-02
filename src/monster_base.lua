local Base = {}

local function cloneFlat(source)
    local out = {}
    if source then for k,v in pairs(source) do out[k] = v end end
    return out
end

local MonsterContext = {}
MonsterContext.__index = MonsterContext

function MonsterContext.new(calculationDay, targetDay)
    return setmetatable({
        calculationDay = calculationDay,
        targetDay = targetDay,
        phase = "BOOTSTRAP",
        subPhase = 0,
        mode = "STAGE_01_BASE",
        status = "NEW",
        retryBudget = 0,
        recoveryDepth = 0,
        currentHandler = nil,
        previousHandler = nil,
        branchTrace = {},
        semanticState = {},
        pendingSemanticState = nil,
        rollbackSnapshot = nil,
        commitToken = 0,
        metrics = {},
        logs = {},
        diagnostics = {},
        warnings = {},
        recoveryEvents = {},
        validationFailures = {},
        wrappedErrors = {},
        lastError = nil
    }, MonsterContext)
end

function MonsterContext:beginSemanticUpdate(candidate)
    assert(self.pendingSemanticState == nil, "Gen yon eta semantik annatant deja")
    self.rollbackSnapshot = cloneFlat(self.semanticState)
    self.pendingSemanticState = cloneFlat(candidate)
end

function MonsterContext:commitSemanticUpdate()
    assert(self.pendingSemanticState ~= nil, "Pa gen eta semantik pou valide epi komèt")
    self.semanticState = self.pendingSemanticState
    self.pendingSemanticState = nil
    self.rollbackSnapshot = nil
    self.commitToken = self.commitToken + 1
end

function MonsterContext:rollbackSemanticUpdate()
    if self.rollbackSnapshot ~= nil then
        self.semanticState = self.rollbackSnapshot
    end
    self.pendingSemanticState = nil
    self.rollbackSnapshot = nil
end

local MetricsShell = {}
MetricsShell.__index = MetricsShell
function MetricsShell.new(target)
    return setmetatable({target = target}, MetricsShell)
end
function MetricsShell:bump(name)
    self.target[name] = (self.target[name] or 0) + 1
end
function MetricsShell:observe(name, value)
    local bucket = self.target[name]
    if type(bucket) ~= "table" then bucket = {}; self.target[name] = bucket end
    bucket[#bucket + 1] = value
end

local ValidationManager = {}
ValidationManager.__index = ValidationManager
function ValidationManager.new() return setmetatable({}, ValidationManager) end
function ValidationManager:requireIntegerDay(value, label)
    if type(value) ~= "number" or math.type(value) ~= "integer" then
        error((label or "Jou") .. " dwe yon nonb antye Lua", 0)
    end
end
function ValidationManager:requirePendingState(context)
    if context.pendingSemanticState == nil then error("Validasyon an mande yon eta annatant", 0) end
end
function ValidationManager:requireNoPendingState(context)
    if context.pendingSemanticState ~= nil then error("Yon eta semantik annatant te koule deyò tranzaksyon an", 0) end
end

local ErrorWrapper = {}
ErrorWrapper.__index = ErrorWrapper
function ErrorWrapper.new() return setmetatable({}, ErrorWrapper) end
function ErrorWrapper:wrap(code, message)
    return {code = code, message = message}
end

local Dispatcher = {}
Dispatcher.__index = Dispatcher
function Dispatcher.new()
    return setmetatable({handlers = {}}, Dispatcher)
end
function Dispatcher:register(phase, handler)
    assert(self.handlers[phase] == nil, "Faz dispatcher sa a gen yon handler deja")
    self.handlers[phase] = handler
end
function Dispatcher:dispatch(context, phase, manager)
    local handler = self.handlers[phase]
    assert(handler ~= nil, "Pa gen handler pou faz sa a")
    context.previousHandler = context.currentHandler
    context.currentHandler = phase
    context.branchTrace[#context.branchTrace + 1] = phase
    return handler(context, manager)
end

local MonsterManager = {}
MonsterManager.__index = MonsterManager
function MonsterManager.new(context)
    local manager = setmetatable({}, MonsterManager)
    manager.context = context
    manager.dispatcher = Dispatcher.new()
    manager.validationManager = ValidationManager.new()
    manager.errorWrapper = ErrorWrapper.new()
    manager.metricsManager = MetricsShell.new(context.metrics)
    return manager
end

function MonsterManager:runBootstrapProbe()
    local ctx = self.context
    self.validationManager:requireIntegerDay(ctx.calculationDay, "Jou kalkil la")
    self.validationManager:requireIntegerDay(ctx.targetDay, "Jou sib la")
    self.metricsManager:bump("bootstrap.probe.calls")
    ctx.status = "VALIDATED"
    self.validationManager:requireNoPendingState(ctx)
    return ctx
end

Base.MonsterContext = MonsterContext
Base.MonsterManager = MonsterManager
Base.Dispatcher = Dispatcher
Base.ValidationManager = ValidationManager
Base.ErrorWrapper = ErrorWrapper
Base.MetricsShell = MetricsShell

return Base
