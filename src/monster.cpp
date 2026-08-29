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

Integer savePatch(const Integer& x) {
    Integer r = oldRemainder(x);
    if (r == 0) {
        r = M_OLD;
    }
    return r;
}

Integer oldDayTag(const Integer& day) {
    Integer distantia = day - FOUNDATION_DAY_OLD;
    if (distantia < 0) {
        distantia = -distantia;
    }
    return 2 * distantia;
}

Integer dayTagWithFoundationScar(const Integer& day) {
    Integer n = oldDayTag(day);
    if (day >= FOUNDATION_DAY_OLD) {
        n += 1;
    }
    if (day == FOUNDATION_DAY_OLD && n != 1) {
        n = 1;
    }
    return n;
}

Integer oldDistance(const Integer& calculationDay, const Integer& targetDay) {
    Integer d = dayTagWithFoundationScar(calculationDay) - dayTagWithFoundationScar(targetDay);
    if (d < 0) {
        d = -d;
    }
    return d;
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

void BaseValidationManager::requirePatch01Ready(const BaseMonsterContext& ctx) const {
    requireLegacyArithmeticReady(ctx);
    if (!ctx.patch01Applied) {
        throw BaseValidationError("emendatio prima nondum applicata est");
    }
    if (ctx.legacyArithmeticOutput == 0) {
        if (ctx.patchedArithmeticOutput != M_OLD) {
            throw BaseValidationError("emendatio prima multiplum M non servavit");
        }
    } else if (ctx.patchedArithmeticOutput != ctx.legacyArithmeticOutput) {
        throw BaseValidationError("emendatio prima residuum non-nullum mutavit");
    }
}

void BaseValidationManager::requireLegacyDayTagReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyDayTagReady) {
        throw BaseValidationError("nota diei legacy nondum parata est");
    }
}

void BaseValidationManager::requirePatch02Ready(const BaseMonsterContext& ctx) const {
    requireLegacyDayTagReady(ctx);
    if (!ctx.patch02Applied) {
        throw BaseValidationError("emendatio secunda nondum applicata est");
    }

    Integer expectatus = ctx.legacyDayTagOutput;
    if (ctx.legacyDayTagInput >= FOUNDATION_DAY_OLD) {
        expectatus += 1;
    }
    if (ctx.legacyDayTagInput == FOUNDATION_DAY_OLD && expectatus != 1) {
        expectatus = 1;
    }

    if (ctx.patchedDayTagOutput != expectatus) {
        throw BaseValidationError("emendatio secunda cicatricem diei non servavit");
    }
}

void BaseValidationManager::requireLegacyDistanceReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyDistanceReady) {
        throw BaseValidationError("distantia legacy nondum parata est");
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

Integer LegacyDayTagAdapter::callOldDayTag(const Integer& day) const {
    return oldDayTag(day);
}

Integer LegacyDistanceAdapter::callOldDistance(const Integer& calculationDay, const Integer& targetDay) const {
    return oldDistance(calculationDay, targetDay);
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

Integer Patch01SaveWrapper::repair(const Integer& x) const {
    return savePatch(x);
}

void Patch01RemainderHandler::handle(BaseMonsterContext& ctx,
                                     const LegacyArithmeticAdapter& adapter,
                                     const Patch01SaveWrapper& wrapper,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch01RemainderHandler";
    ctx.phase = "PATCH_01_LEGACY_CALL";
    ctx.status = "LEGACY_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_01_LEGACY_CALL");
    metrics.bump(ctx, "patch01.legacy.calls");

    ctx.legacyArithmeticOutput = adapter.callOldRemainder(ctx.legacyArithmeticInput);
    ctx.legacyArithmeticReady = true;

    ctx.phase = "PATCH_01_SAVE_WRAPPER";
    ctx.branchTrace.push_back("PATCH_01_SAVE_WRAPPER");
    ctx.patchedArithmeticOutput = wrapper.repair(ctx.legacyArithmeticInput);
    ctx.patch01Applied = true;
    metrics.bump(ctx, "patch01.wrapper.calls");

    ctx.phase = "PATCH_01_VALIDATE";
    ctx.branchTrace.push_back("PATCH_01_VALIDATE");
    validator.requirePatch01Ready(ctx);

    ctx.phase = "PATCH_01_REMAINDER_READY";
    ctx.status = "PATCHED_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_01_REMAINDER_READY");
    metrics.bump(ctx, "patch01.remainder.ready");
}

void Discovery02DayTagHandler::handle(BaseMonsterContext& ctx,
                                      const LegacyDayTagAdapter& adapter,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery02DayTagHandler";
    ctx.phase = "DISCOVERY_02_DAY_TAG_CALL";
    ctx.status = "LEGACY_DAY_TAG_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_CALL");
    metrics.bump(ctx, "discovery02.dayTag.calls");

    ctx.legacyDayTagOutput = adapter.callOldDayTag(ctx.legacyDayTagInput);
    ctx.legacyDayTagReady = true;

    ctx.phase = "DISCOVERY_02_DAY_TAG_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_VALIDATE");
    validator.requireLegacyDayTagReady(ctx);

    ctx.phase = "DISCOVERY_02_DAY_TAG_EXPOSED";
    ctx.status = "LEGACY_DAY_TAG_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_EXPOSED");
    metrics.bump(ctx, "discovery02.dayTag.exposed");
}

Integer Patch02DayTagWrapper::repair(const Integer& day) const {
    return dayTagWithFoundationScar(day);
}

void Patch02DayTagHandler::handle(BaseMonsterContext& ctx,
                                  const LegacyDayTagAdapter& adapter,
                                  const Patch02DayTagWrapper& wrapper,
                                  const BaseValidationManager& validator,
                                  const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch02DayTagHandler";
    ctx.phase = "PATCH_02_LEGACY_DAY_TAG_CALL";
    ctx.status = "LEGACY_DAY_TAG_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_02_LEGACY_DAY_TAG_CALL");
    metrics.bump(ctx, "patch02.legacyDayTag.calls");

    ctx.legacyDayTagOutput = adapter.callOldDayTag(ctx.legacyDayTagInput);
    ctx.legacyDayTagReady = true;

    ctx.phase = "PATCH_02_FOUNDATION_SCAR";
    ctx.branchTrace.push_back("PATCH_02_FOUNDATION_SCAR");
    ctx.patchedDayTagOutput = wrapper.repair(ctx.legacyDayTagInput);
    ctx.patch02Applied = true;
    metrics.bump(ctx, "patch02.wrapper.calls");

    ctx.phase = "PATCH_02_VALIDATE";
    ctx.branchTrace.push_back("PATCH_02_VALIDATE");
    validator.requirePatch02Ready(ctx);

    ctx.phase = "PATCH_02_DAY_TAG_READY";
    ctx.status = "PATCHED_DAY_TAG_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_02_DAY_TAG_READY");
    metrics.bump(ctx, "patch02.dayTag.ready");
}

void Discovery03DistanceHandler::handle(BaseMonsterContext& ctx,
                                        const LegacyDistanceAdapter& adapter,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery03DistanceHandler";
    ctx.phase = "DISCOVERY_03_DISTANCE_CALL";
    ctx.status = "LEGACY_DISTANCE_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_CALL");
    metrics.bump(ctx, "discovery03.distance.calls");

    ctx.legacyDistanceOutput = adapter.callOldDistance(
        ctx.legacyDistanceCalculationDay, ctx.legacyDistanceTargetDay);
    ctx.legacyDistanceReady = true;

    ctx.phase = "DISCOVERY_03_DISTANCE_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_VALIDATE");
    validator.requireLegacyDistanceReady(ctx);

    ctx.phase = "DISCOVERY_03_DISTANCE_EXPOSED";
    ctx.status = "LEGACY_DISTANCE_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_EXPOSED");
    metrics.bump(ctx, "discovery03.distance.exposed");
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

void BaseDispatcher::dispatchPatchedRemainder(BaseMonsterContext& ctx,
                                              const Patch01RemainderHandler& handler,
                                              const LegacyArithmeticAdapter& adapter,
                                              const Patch01SaveWrapper& wrapper,
                                              const BaseValidationManager& validator,
                                              const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_01_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_01_DISPATCH");
    metrics.bump(ctx, "patch01.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyDayTag(BaseMonsterContext& ctx,
                                          const Discovery02DayTagHandler& handler,
                                          const LegacyDayTagAdapter& adapter,
                                          const BaseValidationManager& validator,
                                          const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_02_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_02_DISPATCH");
    metrics.bump(ctx, "discovery02.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedDayTag(BaseMonsterContext& ctx,
                                           const Patch02DayTagHandler& handler,
                                           const LegacyDayTagAdapter& adapter,
                                           const Patch02DayTagWrapper& wrapper,
                                           const BaseValidationManager& validator,
                                           const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_02_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_02_DISPATCH");
    metrics.bump(ctx, "patch02.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyDistance(BaseMonsterContext& ctx,
                                            const Discovery03DistanceHandler& handler,
                                            const LegacyDistanceAdapter& adapter,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_03_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_03_DISPATCH");
    metrics.bump(ctx, "discovery03.dispatch.calls");

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
    ctx.phase = "PATCH_01_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyArithmeticInput = x;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyArithmeticAdapter adapter;
    const Patch01SaveWrapper wrapper;
    const Patch01RemainderHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedRemainder(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyRemainderReport{
        ctx.legacyArithmeticInput,
        ctx.patchedArithmeticOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyArithmeticOutput,
        ctx.patch01Applied
    };
}

LegacyRemainderReport BaseMonsterManager::executeUnpatchedRemainderDiagnostic(const Integer& x) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_01_DIAGNOSTIC_NEW";
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
        ctx.branchTrace.size(),
        ctx.legacyArithmeticOutput,
        false
    };
}

LegacyDayTagReport BaseMonsterManager::executeLegacyDayTag(const Integer& day) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = day;
    ctx.targetDay = day;
    ctx.phase = "PATCH_02_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDayTagInput = day;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDayTagAdapter adapter;
    const Patch02DayTagWrapper wrapper;
    const Patch02DayTagHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedDayTag(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyDayTagReport{
        ctx.legacyDayTagInput,
        ctx.patchedDayTagOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDayTagOutput,
        ctx.patch02Applied
    };
}

LegacyDayTagReport BaseMonsterManager::executeUnpatchedDayTagDiagnostic(const Integer& day) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = day;
    ctx.targetDay = day;
    ctx.phase = "DISCOVERY_02_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDayTagInput = day;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDayTagAdapter adapter;
    const Discovery02DayTagHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyDayTag(ctx, handler, adapter, validator, metrics);

    return LegacyDayTagReport{
        ctx.legacyDayTagInput,
        ctx.legacyDayTagOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDayTagOutput,
        false
    };
}

LegacyDistanceReport BaseMonsterManager::executeDistance(const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_03_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDistanceCalculationDay = calculationDay;
    ctx.legacyDistanceTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDistanceAdapter adapter;
    const Discovery03DistanceHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyDistance(ctx, handler, adapter, validator, metrics);

    return LegacyDistanceReport{
        ctx.legacyDistanceCalculationDay,
        ctx.legacyDistanceTargetDay,
        ctx.legacyDistanceOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDistanceOutput,
    };
}

} // namespace pastafari
