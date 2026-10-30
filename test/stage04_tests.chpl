use BigInteger;
use ExactMath;
use LegacyDayTag;
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

// Тестовий еталон; виробничі модулі його ніколи не імпортують.
proc expectedDayTag(const ref day: bigint): bigint {
  const distance = absBig(day - FOUNDATION_DAY);
  if day < FOUNDATION_DAY then return 2 * distance;
  return 2 * distance + 1;
}

proc testHistoricalScar() {
  var divergent = 0;
  for delta in -2..2 {
    const day = FOUNDATION_DAY + delta;
    const legacy = oldDayTag(day);
    const expected = expectedDayTag(day);
    const caseDescription = "F" + (if delta < 0 then "" else "+") + delta:string;
    check(legacy == 2 * absBig(day - FOUNDATION_DAY),
          "старий парний тег: " + caseDescription);
    check(expected == (if delta < 0 then new bigint(-2 * delta) else new bigint(2 * delta + 1)),
          "тестовий оракул: " + caseDescription);
    check((legacy != expected) == (delta >= 0),
          "відхилення лише F, F+1, F+2: " + caseDescription);
    if legacy != expected then divergent += 1;
  }
  check(divergent == 3, "рівно три відхилення в локальному вікні");

  const huge = new bigint(1) << 300;
  const before = FOUNDATION_DAY - huge;
  const after = FOUNDATION_DAY + huge;
  check(oldDayTag(before) == 2 * huge &&
        expectedDayTag(before) == oldDayTag(before),
        "довільна точність до дня заснування, понад 256 біт");
  check(oldDayTag(after) == 2 * huge &&
        expectedDayTag(after) == 2 * huge + 1,
        "історична втрата непарності після заснування, понад 256 біт");
}

proc testProductionRoute() {
  const foundation = FOUNDATION_DAY;
  const bootstrap = makeBootstrapContext(foundation, foundation);
  check(bootstrap.status == MonsterStatus.bootstrapOnly &&
        !bootstrap.metrics.contains("discovery02.calls") &&
        bootstrap.branchTrace.size == 1,
        "етап 1 ізольований від відкриття 02");

  const discovery01 = makeDiscovery01Context(foundation, foundation, M);
  check(discovery01.status == MonsterStatus.discoveryOnly &&
        discovery01.discovery01LegacyOutput == 0 &&
        !discovery01.metrics.contains("discovery02.calls") &&
        discovery01.branchTrace.size == 2,
        "історичне відкриття 01 ізольовано");

  const patch01 = makePatch01Context(foundation, foundation, M);
  check(patch01.status == MonsterStatus.patch01Only &&
        patch01.discovery01LegacyOutput == 0 &&
        patch01.patch01CorrectedOutput == M &&
        !patch01.metrics.contains("discovery02.calls") &&
        patch01.branchTrace.size == 3,
        "латка 01 діє тільки у власному маршруті");

  for delta in -2..2 {
    const day = foundation + delta;
    const ctx = makeDiscovery02Context(foundation, foundation, day);
    const caseDescription = "delta=" + delta:string;
    check(ctx.discovery02Input == day &&
          ctx.discovery02LegacyOutput == oldDayTag(day),
          "реальний виклик старого day-tag: " + caseDescription);
    check(ctx.status == MonsterStatus.discovery02Only &&
          ctx.phase == MonsterPhase.stoppedAtDiscovery02Boundary,
          "зупинка рівно на межі Discovery 02: " + caseDescription);
    check(ctx.discovery01LegacyOutput == regularMod(day, M) &&
          ctx.patch01CorrectedOutput == save(day),
          "історичний залишок та Patch 01 збережено: " + caseDescription);
    check(ctx.metrics.get("bootstrap.calls", 0) == 1 &&
          ctx.metrics.get("discovery01.calls", 0) == 1 &&
          ctx.metrics.get("patch01.calls", 0) == 1 &&
          ctx.metrics.get("discovery02.calls", 0) == 1,
          "облік одного виклику на шар: " + caseDescription);
    check(ctx.branchTrace.size == 4 &&
          ctx.branchTrace[0] == "BOOTSTRAP_DISPATCH" &&
          ctx.branchTrace[1] == "DISCOVERY_01_OLD_REMAINDER" &&
          ctx.branchTrace[2] == "PATCH_01_LIFT_ZERO" &&
          ctx.branchTrace[3] == "DISCOVERY_02_OLD_DAY_TAG",
          "простежувана ізоляція всіх чотирьох етапів: " + caseDescription);
  }

  const huge = new bigint(1) << 300;
  const ctxHuge = makeDiscovery02Context(foundation, foundation, foundation + huge);
  check(ctxHuge.discovery02LegacyOutput == 2 * huge &&
        ctxHuge.status == MonsterStatus.discovery02Only,
        "виробничий маршрут з числом понад 256 біт");
  check(!bootstrap.metrics.contains("discovery02.calls") &&
        !patch01.metrics.contains("discovery02.calls"),
        "виклики не забруднюють попередні контексти");
}

proc main() {
  writeln("Початок перевірки історичного відкриття 02 етапу 4.");
  testHistoricalScar();
  testProductionRoute();
  writeln("Перевірок: ", checks, "; помилок: ", failures, ".");
  if failures != 0 then halt("Discovery 02 має помилки.");
  writeln("STAGE_04_DISCOVERY_02_RESULT=PASS");
}
