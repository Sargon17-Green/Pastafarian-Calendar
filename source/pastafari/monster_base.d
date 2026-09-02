module pastafari.monster_base;

import std.exception : enforce;

struct MetricBook
{
    ulong[string] counters;

    void bump(string key)
    {
        counters[key] = counters.get(key, 0UL) + 1UL;
    }
}

struct MonsterContext
{
    long calculationDay;
    long targetDay;
    string phase;
    string status;
    string[] branchTrace;
    MetricBook metrics;
}

class BaseValidationManager
{
    void validateInput(const MonsterContext ctx)
    {
        enforce(ctx.phase.length != 0, "E_PHASE_EMPTY");
    }

    void validateNeutralState(const MonsterContext ctx)
    {
        enforce(ctx.status == "READY" || ctx.status == "NEW", "E_STATUS");
    }
}

class BaseErrorWrapper
{
    Exception wrap(Exception source, string code)
    {
        return new Exception(code, source.file, source.line, source);
    }
}

class BaseDispatcher
{
    BaseValidationManager validator;

    this(BaseValidationManager validator)
    {
        this.validator = validator;
    }

    MonsterContext dispatch(MonsterContext ctx)
    {
        ctx.branchTrace ~= "BOOTSTRAP_DISPATCH";
        ctx.metrics.bump("bootstrap.dispatch");
        validator.validateInput(ctx);
        ctx.status = "READY";
        validator.validateNeutralState(ctx);
        return ctx;
    }
}

class MonsterManager
{
    BaseValidationManager validator;
    BaseDispatcher dispatcher;
    BaseErrorWrapper errorWrapper;

    this()
    {
        validator = new BaseValidationManager();
        dispatcher = new BaseDispatcher(validator);
        errorWrapper = new BaseErrorWrapper();
    }

    MonsterContext bootstrap(long calculationDay, long targetDay)
    {
        MonsterContext ctx;
        ctx.calculationDay = calculationDay;
        ctx.targetDay = targetDay;
        ctx.phase = "BOOTSTRAP";
        ctx.status = "NEW";
        try
        {
            return dispatcher.dispatch(ctx);
        }
        catch (Exception e)
        {
            throw errorWrapper.wrap(e, "E_BOOTSTRAP");
        }
    }
}
