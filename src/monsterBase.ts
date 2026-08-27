export type MonsterPhase = "BOOTSTRAP" | "READY" | "FAILED";
export type MonsterStatus = "NEW" | "VALIDATED" | "NOT_INTEGRATED";

export type MonsterContext = {
  readonly calculationDay: bigint;
  readonly targetDay: bigint;
  phase: MonsterPhase;
  status: MonsterStatus;
  branchTrace: string[];
  metrics: Map<string, bigint>;
  logs: string[];
  diagnostics: string[];
  warnings: string[];
  lastError: Error | null;
};

export class MonsterValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MonsterValidationError";
  }
}

export class MonsterStageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MonsterStageError";
  }
}

export class BaseMetricsManager {
  bump(ctx: MonsterContext, key: string): void {
    ctx.metrics.set(key, (ctx.metrics.get(key) ?? 0n) + 1n);
  }
}

export class BaseValidationManager {
  validateInput(ctx: MonsterContext): void {
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक पूर्णांक असले पाहिजेत");
    }
  }
}

export class BaseDispatcher {
  dispatch(ctx: MonsterContext): MonsterContext {
    ctx.branchTrace.push("BOOTSTRAP_VALIDATE");
    new BaseValidationManager().validateInput(ctx);
    ctx.phase = "READY";
    ctx.status = "VALIDATED";
    return ctx;
  }
}

export function createMonsterContext(calculationDay: bigint, targetDay: bigint): MonsterContext {
  return {
    calculationDay,
    targetDay,
    phase: "BOOTSTRAP",
    status: "NEW",
    branchTrace: [],
    metrics: new Map<string, bigint>(),
    logs: [],
    diagnostics: [],
    warnings: [],
    lastError: null
  };
}

export function bootstrapMonster(calculationDay: bigint, targetDay: bigint): MonsterContext {
  const ctx = createMonsterContext(calculationDay, targetDay);
  const metrics = new BaseMetricsManager();
  metrics.bump(ctx, "bootstrap.calls");
  return new BaseDispatcher().dispatch(ctx);
}

export function calendarDateSpaghetti(calculationDay: bigint, targetDay: bigint): never {
  const ctx = bootstrapMonster(calculationDay, targetDay);
  ctx.status = "NOT_INTEGRATED";
  throw new MonsterStageError("पहिल्या टप्प्यात अंतिम स्पॅगेटी दिनांक मार्ग अद्याप जोडलेला नाही");
}
