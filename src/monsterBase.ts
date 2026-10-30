export type MonsterPhase = "BOOTSTRAP" | "READY" | "FAILED";
export type MonsterStatus = "NEW" | "VALIDATED" | "NOT_INTEGRATED" | "DISCOVERY_01_RECORDED" | "PATCH_01_APPLIED" | "DISCOVERY_02_RECORDED" | "PATCH_02_APPLIED" | "PATCH_03_APPLIED" | "DISCOVERY_03_RECORDED" | "DISCOVERY_04_RECORDED" | "PATCH_04_APPLIED" | "DISCOVERY_05_RECORDED" | "PATCH_05_APPLIED" | "DISCOVERY_06_RECORDED" | "PATCH_06_APPLIED" | "DISCOVERY_07_RECORDED" | "PATCH_07_APPLIED" | "DISCOVERY_08_RECORDED" | "PATCH_08_APPLIED" | "DISCOVERY_09_RECORDED" | "PATCH_09_APPLIED" | "DISCOVERY_10_RECORDED" | "PATCH_10_APPLIED" | "DISCOVERY_11_RECORDED" | "PATCH_11_APPLIED" | "DISCOVERY_12_RECORDED" | "PATCH_12_APPLIED" | "DISCOVERY_13_RECORDED" | "PATCH_13_APPLIED" | "DISCOVERY_14_RECORDED" | "PATCH_14_APPLIED" | "DISCOVERY_15_RECORDED" | "PATCH_15_APPLIED" | "DISCOVERY_16_RECORDED" | "PATCH_16_APPLIED" | "DISCOVERY_17_RECORDED" | "PATCH_17_APPLIED" | "DISCOVERY_18_RECORDED" | "PATCH_18_APPLIED" | "DISCOVERY_19_RECORDED" | "PATCH_19_APPLIED" | "DISCOVERY_20_RECORDED" | "PATCH_20_APPLIED" | "DISCOVERY_21_RECORDED" | "PATCH_21_APPLIED" | "DISCOVERY_22_RECORDED" | "PATCH_22_APPLIED" | "DISCOVERY_23_RECORDED" | "PATCH_23_APPLIED" | "DISCOVERY_24_RECORDED" | "PATCH_24_APPLIED" | "DISCOVERY_25_RECORDED" | "PATCH_25_APPLIED" | "DISCOVERY_26_RECORDED";

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
  throw new MonsterStageError("अंतिम स्पॅगेटी दिनांक मार्ग अद्याप जोडलेला नाही");
}
