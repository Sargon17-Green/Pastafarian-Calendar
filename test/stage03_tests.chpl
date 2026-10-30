use BigInteger;
use ExactMath;
use LegacyRemainder;
use Patch01Adapter;
use MonsterBootstrap;

var checks = 0;
var failures = 0;

proc check(condition: bool, description: string) {
  checks += 1;
  if condition then
    writeln("ГАРАЗД: ", description);
  else {
    failures += 1;
    writeln("ПОМИЛКА: ", description);
  }
}

proc testAdapter() {
  check(applyPatch01(new bigint(0)) == M,
        "латка підіймає нульовий залишок до M");
  check(applyPatch01(new bigint(1)) == 1,
        "латка не змінює одиницю");
  check(applyPatch01(M - 1) == M - 1,
        "латка не змінює верхню звичайну остачу");
  check(oldRemainder(M) == 0 && save(M) == M,
        "історичний дефект збережено поза латкою");
}

proc testProductionRoute() {
  const bootstrap = makeBootstrapContext(FOUNDATION_DAY, FOUNDATION_DAY);
  check(bootstrap.status == MonsterStatus.bootstrapOnly &&
        bootstrap.phase == MonsterPhase.stoppedAtBootstrapBoundary,
        "маршрут Bootstrap ізольований");
  check(!bootstrap.metrics.contains("patch01.calls") &&
        bootstrap.branchTrace.size == 1,
        "Bootstrap не бачить латки");

  const discovery = makeDiscovery01Context(FOUNDATION_DAY, FOUNDATION_DAY, M);
  check(discovery.status == MonsterStatus.discoveryOnly &&
        discovery.discovery01LegacyOutput == 0,
        "маршрут Discovery 01 не змінено");
  check(!discovery.metrics.contains("patch01.calls") &&
        discovery.branchTrace.size == 2,
        "Discovery 01 не застосовує латки");

  for k in -3..3 {
    for delta in -1..1 {
      const candidate = M * k + delta;
      const ctx = makePatch01Context(FOUNDATION_DAY, FOUNDATION_DAY, candidate);
      const caseDescription = "k=" + k:string + ", delta=" + delta:string;
      check(ctx.discovery01Input == candidate &&
            ctx.discovery01LegacyOutput == regularMod(candidate, M),
            "історичний результат: " + caseDescription);
      check(ctx.patch01CorrectedOutput == save(candidate),
            "виправлена остача відповідає SAVE: " + caseDescription);
      check(ctx.status == MonsterStatus.patch01Only &&
            ctx.phase == MonsterPhase.stoppedAtPatch01Boundary,
            "зупинка на межі латки: " + caseDescription);
      check(ctx.metrics.get("bootstrap.calls", 0) == 1 &&
            ctx.metrics.get("discovery01.calls", 0) == 1 &&
            ctx.metrics.get("patch01.calls", 0) == 1,
            "метрики обмежені спостереженням: " + caseDescription);
      check(ctx.branchTrace.size == 3 &&
            ctx.branchTrace[0] == "BOOTSTRAP_DISPATCH" &&
            ctx.branchTrace[1] == "DISCOVERY_01_OLD_REMAINDER" &&
            ctx.branchTrace[2] == "PATCH_01_LIFT_ZERO",
            "окремий історичний виклик і латка: " + caseDescription);
    }
  }

  const huge = factorialBig(47) * M;
  const positive = makePatch01Context(FOUNDATION_DAY, FOUNDATION_DAY, huge);
  check(positive.discovery01LegacyOutput == 0 &&
        positive.patch01CorrectedOutput == M,
        "довільно великий кратний M");
  const negative = makePatch01Context(FOUNDATION_DAY, FOUNDATION_DAY, -huge);
  check(negative.discovery01LegacyOutput == 0 &&
        negative.patch01CorrectedOutput == M,
        "від'ємний довільно великий кратний M");
}

proc main() {
  writeln("Початок перевірки латки 01 етапу 3.");
  testAdapter();
  testProductionRoute();
  writeln("Перевірок: ", checks, "; помилок: ", failures, ".");
  if failures != 0 then halt("Латка 01 етапу 3 має помилки.");
  writeln("STAGE_03_PATCH_01_RESULT=PASS");
}
