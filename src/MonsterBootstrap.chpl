module MonsterBootstrap {
  use BigInteger;
  use List;
  use Map;
  use LegacyRemainder;
  use Patch01Adapter;
  use LegacyDayTag;

  enum MonsterPhase {
    boot,
    validateInput,
    dispatch,
    stoppedAtBootstrapBoundary,
    discovery01LegacyRemainder,
    stoppedAtDiscovery01Boundary,
    patch01CorrectLegacyRemainder,
    stoppedAtPatch01Boundary,
    discovery02LegacyDayTag,
    stoppedAtDiscovery02Boundary
  }

  enum MonsterStatus {
    fresh,
    active,
    bootstrapOnly,
    failed,
    discoveryOnly,
    patch01Only,
    discovery02Only
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
    var patch01CorrectedOutput: bigint;
    var discovery02Input: bigint;
    var discovery02LegacyOutput: bigint;
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
  // Етап 2, відкриття 01: історичний дефект навмисно збережено.
  // Цей маршрут не обчислює й не підміняє канонічну календарну дату.
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

  // Етап 3, латка 01: історичний результат збережено.
  // Цей маршрут ще не обчислює п'ять нормативних компонентів дати.
  record Patch01Dispatcher {
    proc ref dispatch(ref ctx: MonsterContext) {
      ctx.phase = MonsterPhase.patch01CorrectLegacyRemainder;
      ctx.patch01CorrectedOutput = applyPatch01(ctx.discovery01LegacyOutput);
      ctx.branchTrace.pushBack("PATCH_01_LIFT_ZERO");
      ctx.status = MonsterStatus.patch01Only;
      ctx.phase = MonsterPhase.stoppedAtPatch01Boundary;
    }
  }

  proc makePatch01Context(const ref calculationDay: bigint,
                          const ref targetDay: bigint,
                          const ref candidateValue: bigint): MonsterContext {
    var ctx = makeDiscovery01Context(calculationDay, targetDay, candidateValue);
    if ctx.status != MonsterStatus.discoveryOnly then return ctx;

    var metrics: BaseMetricsManager;
    var dispatcher: Patch01Dispatcher;
    metrics.bump(ctx, "patch01.calls");
    dispatcher.dispatch(ctx);
    return ctx;
  }

  // Етап 4, відкриття 02: історична парність дня відносно дня заснування.
  // Помилка залишається відкритою; нормативний результат тут не обчислюється.
  record Discovery02Dispatcher {
    proc ref dispatch(ref ctx: MonsterContext, const ref candidateDay: bigint) {
      ctx.phase = MonsterPhase.discovery02LegacyDayTag;
      ctx.discovery02Input = candidateDay;
      ctx.discovery02LegacyOutput = oldDayTag(candidateDay);
      ctx.branchTrace.pushBack("DISCOVERY_02_OLD_DAY_TAG");
      ctx.status = MonsterStatus.discovery02Only;
      ctx.phase = MonsterPhase.stoppedAtDiscovery02Boundary;
    }
  }

  proc makeDiscovery02Context(const ref calculationDay: bigint,
                              const ref targetDay: bigint,
                              const ref candidateDay: bigint): MonsterContext {
    var ctx = makePatch01Context(calculationDay, targetDay, candidateDay);
    if ctx.status != MonsterStatus.patch01Only then return ctx;

    var metrics: BaseMetricsManager;
    var dispatcher: Discovery02Dispatcher;
    metrics.bump(ctx, "discovery02.calls");
    dispatcher.dispatch(ctx, candidateDay);
    return ctx;
  }
}
