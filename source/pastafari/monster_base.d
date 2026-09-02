module pastafari.monster_base;

import std.bigint : BigInt;
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
    BigInt calculationDay;
    BigInt targetDay;
    string phase;
    string status;
    string[] branchTrace;
    MetricBook metrics;
}

final class BaseValidationManager
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

final class BaseErrorWrapper
{
    Exception wrap(Exception source, string code)
    {
        return new Exception(code, source.file, source.line, source);
    }
}

final class BaseDispatcher
{
    MonsterContext dispatch(MonsterContext ctx, BaseValidationManager validator)
    {
        enforce(validator !is null, "E_VALIDATOR_NULL");
        ctx.branchTrace ~= "BOOTSTRAP_DISPATCH";
        ctx.metrics.bump("bootstrap.dispatch");
        validator.validateInput(ctx);
        ctx.status = "READY";
        validator.validateNeutralState(ctx);
        return ctx;
    }
}

final class MonsterManager
{
    MonsterContext bootstrap(BigInt calculationDay, BigInt targetDay)
    {
        auto validator = new BaseValidationManager();
        auto dispatcher = new BaseDispatcher();
        auto errorWrapper = new BaseErrorWrapper();

        MonsterContext ctx;
        ctx.calculationDay = calculationDay;
        ctx.targetDay = targetDay;
        ctx.phase = "BOOTSTRAP";
        ctx.status = "NEW";
        try
        {
            return dispatcher.dispatch(ctx, validator);
        }
        catch (Exception e)
        {
            throw errorWrapper.wrap(e, "E_BOOTSTRAP");
        }
    }

    MonsterContext bootstrap(long calculationDay, long targetDay)
    {
        return bootstrap(BigInt(calculationDay), BigInt(targetDay));
    }
}
