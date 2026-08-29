mutable struct MonsterContext
    calculationDay::BigInt
    targetDay::BigInt
    phase::Symbol
    subPhase::Int
    mode::Symbol
    status::Symbol
    retryBudget::Int
    recoveryDepth::Int
    currentHandler::Symbol
    previousHandler::Symbol
    branchTrace::Vector{Symbol}
    metrics::Dict{Symbol, BigInt}
    logs::Vector{Symbol}
    diagnostics::Vector{Symbol}
    warnings::Vector{Symbol}
    lastError::Union{Nothing, Exception}
    validationFailures::Vector{Symbol}
end

function MonsterContext(calculationDay::Integer, targetDay::Integer)
    return MonsterContext(
        BigInt(calculationDay), BigInt(targetDay), :BOOTSTRAP, 0, :AUTHORITATIVE,
        :NEW, 0, 0, :NONE, :NONE, Symbol[], Dict{Symbol, BigInt}(), Symbol[],
        Symbol[], Symbol[], nothing, Symbol[]
    )
end

struct StageIncompleteError <: Exception
    code::Symbol
end

function Base.showerror(io::IO, error::StageIncompleteError)
    print(io, "STAGE_01_ONLY:", error.code)
end

mutable struct BaseMetricsManager
    counters::Dict{Symbol, BigInt}
end

BaseMetricsManager() = BaseMetricsManager(Dict{Symbol, BigInt}())

function bump!(manager::BaseMetricsManager, key::Symbol)
    manager.counters[key] = get(manager.counters, key, BigInt(0)) + 1
    return nothing
end

struct BaseValidationManager end

function requireIntegerDays(context::MonsterContext)
    context.phase = :VALIDATION
    push!(context.branchTrace, :VALIDATION)
    return true
end

mutable struct BaseDispatcher
    phase::Symbol
end

mutable struct MonsterManager
    dispatcher::BaseDispatcher
    validationManager::BaseValidationManager
    metricsManager::BaseMetricsManager
end

MonsterManager() = MonsterManager(BaseDispatcher(:BOOTSTRAP), BaseValidationManager(), BaseMetricsManager())

function calendarDateSpaghetti(calculationDay::Integer, targetDay::Integer)
    context = MonsterContext(calculationDay, targetDay)
    manager = MonsterManager()
    bump!(manager.metricsManager, :calendar_calls)
    requireIntegerDays(context)
    context.phase = :BOOTSTRAP_STOP
    context.status = :INCOMPLETE_BY_STAGE_DESIGN
    throw(StageIncompleteError(:STAGE_01_ONLY))
end
