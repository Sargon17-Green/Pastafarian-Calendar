module MonsterBootstrap {
  use BigInteger;
  use List;
  use Map;

  enum MonsterPhase {
    boot,
    validateInput,
    dispatch,
    stoppedAtBootstrapBoundary
  }

  enum MonsterStatus {
    fresh,
    active,
    bootstrapOnly,
    failed
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
  }

  record BaseValidationManager {
    proc validateInput(const ref ctx: MonsterContext): bool {
      return true;
    }
  }

  record BaseMetricsManager {
    proc ref bump(ref ctx: MonsterContext, key: string) {
      if ctx.metrics.contains(key) then
        ctx.metrics[key] += 1;
      else
        ctx.metrics.add(key, 1);
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
}
