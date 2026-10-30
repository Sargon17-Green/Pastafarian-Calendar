module MonsterBootstrap {
  use BigInteger;
  use List;
  use Map;
  use LegacyRemainder;

  enum MonsterPhase {
    boot,
    validateInput,
    dispatch,
    stoppedAtBootstrapBoundary,
    discovery01LegacyRemainder,
    stoppedAtDiscovery01Boundary
  }

  enum MonsterStatus {
    fresh,
    active,
    bootstrapOnly,
    failed,
    discoveryOnly
  }

  record MonsterContext {
    var calculationDay: bigint;
    var targetDay: bigint;
    var phase: MonsterPhase = MonsterPhase.boot;
    var status: MonsterStatus = MonsterStatus.fresh;
    var retryBudget: int = 0;
    var recoveryDepth: int = 0;
    var branchTrace: list(string);
    var diagnostics: list(string);
    var metrics: map(string, int);
    var lastError: string;
    var discovery01Input: bigint;
    var discovery01LegacyOutput: bigint;
  }

  record BaseValidationManager {
    proc validateInput(const ref ctx: MonsterContext): bool {
      return true;
    }
  }

  record BaseMetricsManager {
    proc ref bump(ref ctx: MonsterContext, key: string) {
      ctx.metrics.addOrReplace(key, ctx.metrics.get(key, 0) + 1);
    }
  }

  record BaseErrorWrapper {
    proc wrap(message: string): string {
      return "Помилка початкового каркаса: " + message;
    }
  }

  record BaseDispatcher {
    proc ref dispatch(ref ctx: MonsterContext) {
      ctx.phase = MonsterPhase.dispatch;
      ctx.branchTrace.pushBack("BOOTSTRAP_DISPATCH");
      ctx.status = MonsterStatus.bootstrapOnly;
      ctx.phase = MonsterPhase.stoppedAtBootstrapBoundary;
    }
  }

  proc makeBootstrapContext(const ref calculationDay: bigint,
                            const ref targetDay: bigint): MonsterContext {
    var ctx: MonsterContext;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = MonsterPhase.validateInput;
    ctx.status = MonsterStatus.active;

    var validator: BaseValidationManager;
    var metrics: BaseMetricsManager;
    var dispatcher: BaseDispatcher;

    if !validator.validateInput(ctx) {
      ctx.status = MonsterStatus.failed;
      ctx.lastError = "Початкова перевірка вхідних даних не пройдена.";
      return ctx;
    }

    metrics.bump(ctx, "bootstrap.calls");
    dispatcher.dispatch(ctx);
    return ctx;
  }
  // Stage 2, discovery 01: the historical defect is intentionally retained.
  // This path does not compute or substitute a canonical calendar result.
  record Discovery01Dispatcher {
    proc ref dispatch(ref ctx: MonsterContext, const ref candidateValue: bigint) {
      ctx.phase = MonsterPhase.discovery01LegacyRemainder;
      ctx.discovery01Input = candidateValue;
      ctx.discovery01LegacyOutput = oldRemainder(candidateValue);
      ctx.branchTrace.pushBack("DISCOVERY_01_OLD_REMAINDER");
      ctx.status = MonsterStatus.discoveryOnly;
      ctx.phase = MonsterPhase.stoppedAtDiscovery01Boundary;
    }
  }

  proc makeDiscovery01Context(const ref calculationDay: bigint,
                              const ref targetDay: bigint,
                              const ref candidateValue: bigint): MonsterContext {
    var ctx = makeBootstrapContext(calculationDay, targetDay);
    if ctx.status != MonsterStatus.bootstrapOnly then return ctx;

    var metrics: BaseMetricsManager;
    var dispatcher: Discovery01Dispatcher;
    metrics.bump(ctx, "discovery01.calls");
    dispatcher.dispatch(ctx, candidateValue);
    return ctx;
  }
}
