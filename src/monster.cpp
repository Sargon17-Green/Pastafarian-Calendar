#include "pastafari/monster.hpp"

namespace pastafari {

Integer regularMod(const Integer& x, const Integer& d) {
    if (d <= 0) {
        throw BaseValidationError("divisor positivus requiritur");
    }
    Integer r = x % d;
    if (r < 0) {
        r += d;
    }
    return r;
}

Integer oldRemainder(const Integer& x) {
    return regularMod(x, M_OLD);
}

void BaseValidationManager::requireNeutralBootstrapState(const BaseMonsterContext& ctx) const {
    if (ctx.phase.empty() || ctx.status.empty()) {
        throw BaseValidationError("status initialis invalidus");
    }
}

void BaseValidationManager::requireLegacyArithmeticReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyArithmeticReady) {
        throw BaseValidationError("res arithmetica legacy nondum parata est");
    }
}

void BaseMetricsShell::bump(BaseMonsterContext& ctx, const std::string& key) const {
    auto it = ctx.metrics.find(key);
    if (it == ctx.metrics.end()) {
        ctx.metrics.emplace(key, Integer{1});
    } else {
        it->second += 1;
    }
}

Integer LegacyArithmeticAdapter::callOldRemainder(const Integer& x) const {
    return oldRemainder(x);
}

void Discovery01RemainderHandler::handle(BaseMonsterContext& ctx,
                                         const LegacyArithmeticAdapter& adapter,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery01RemainderHandler";
    ctx.phase = "DISCOVERY_01_REMAINDER_CALL";
    ctx.status = "LEGACY_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_CALL");
    metrics.bump(ctx, "discovery01.remainder.calls");

    ctx.legacyArithmeticOutput = adapter.callOldRemainder(ctx.legacyArithmeticInput);
    ctx.legacyArithmeticReady = true;

    ctx.phase = "DISCOVERY_01_REMAINDER_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_VALIDATE");
    validator.requireLegacyArithmeticReady(ctx);

    ctx.phase = "DISCOVERY_01_REMAINDER_EXPOSED";
    ctx.status = "LEGACY_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_EXPOSED");
    metrics.bump(ctx, "discovery01.remainder.exposed");
}

void BaseDispatcher::dispatch(BaseMonsterContext& ctx,
                              const BaseValidationManager& validator,
                              const BaseMetricsShell& metrics) const {
    ctx.phase = "BOOTSTRAP_ENTRY";
    ctx.status = "ENTERED";
    ctx.branchTrace.push_back("BOOTSTRAP_ENTRY");
    metrics.bump(ctx, "bootstrap.calls");
    validator.requireNeutralBootstrapState(ctx);

    ctx.phase = "BOOTSTRAP_VALIDATE";
    ctx.branchTrace.push_back("BOOTSTRAP_VALIDATE");
    validator.requireNeutralBootstrapState(ctx);

    ctx.phase = "BOOTSTRAP_DONE";
    ctx.status = "OK";
    ctx.branchTrace.push_back("BOOTSTRAP_DONE");
    metrics.bump(ctx, "bootstrap.success");
}

void BaseDispatcher::dispatchLegacyRemainder(BaseMonsterContext& ctx,
                                             const Discovery01RemainderHandler& handler,
                                             const LegacyArithmeticAdapter& adapter,
                                             const BaseValidationManager& validator,
                                             const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_01_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_01_DISPATCH");
    metrics.bump(ctx, "discovery01.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

BaseRunReport BaseMonsterManager::execute(const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "BOOTSTRAP_NEW";
    ctx.status = "NEW";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const BaseDispatcher dispatcher;
    dispatcher.dispatch(ctx, validator, metrics);

    return BaseRunReport{ctx.phase, ctx.status, ctx.branchTrace.size()};
}

LegacyRemainderReport BaseMonsterManager::executeLegacyRemainder(const Integer& x) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_01_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyArithmeticInput = x;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyArithmeticAdapter adapter;
    const Discovery01RemainderHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyRemainder(ctx, handler, adapter, validator, metrics);

    return LegacyRemainderReport{
        ctx.legacyArithmeticInput,
        ctx.legacyArithmeticOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

} // namespace pastafari
