#include "pastafari/monster.hpp"

namespace pastafari {

void BaseValidationManager::requireNeutralBootstrapState(const BaseMonsterContext& ctx) const {
    if (ctx.phase.empty() || ctx.status.empty()) {
        throw BaseValidationError("status initialis invalidus");
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

} // namespace pastafari
