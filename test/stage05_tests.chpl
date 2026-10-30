use BigInteger;
use ExactMath;
use LegacyDayTag;
use Patch02Adapter;
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

// Незалежний тестовий еталон; виробничі маршрути його не імпортують.
proc expectedDayTag(const ref day: bigint): bigint {
  const distance = absBig(day - FOUNDATION_DAY);
  if day < FOUNDATION_DAY then return 2 * distance;
  return 2 * distance + 1;
}

proc testBoundaryAndHistoricalScar() {
  var divergences = 0;
  for delta in -2..2 {
    const day = FOUNDATION_DAY + delta;
    const legacy = oldDayTag(day);
    const corrected = applyPatch02(legacy, day);
    const normative = expectedDayTag(day);
    const caseDescription = "F" + (if delta < 0 then "" else "+") + delta:string;
    check(legacy == 2 * absBig(day - FOUNDATION_DAY),
          "старий тег збережений: " + caseDescription);
    check(corrected == normative,
          "латка дорівнює незалежному еталону: " + caseDescription);
    check(corrected - legacy == (if delta >= 0 then new bigint(1) else new bigint(0)),
          "лише дозволена парність: " + caseDescription);
    check((legacy != normative) == (delta >= 0),
          "історичний дефект відтворюється: " + caseDescription);
    if legacy != normative then divergences += 1;
  }
  check(divergences == 3, "історичних розбіжностей рівно три");
}

proc testArbitraryPrecision() {
  for exponent in [257, 300, 521] {
    const enormous = new bigint(1) << exponent;
    const before = FOUNDATION_DAY - enormous;
    const after = FOUNDATION_DAY + enormous;
    const legacyBefore = oldDayTag(before);
    const legacyAfter = oldDayTag(after);
    check(legacyBefore == 2 * enormous &&
          applyPatch02(legacyBefore, before) == 2 * enormous,
          "понад 256 біт до заснування: " + exponent:string);
    check(legacyAfter == 2 * enormous &&
          applyPatch02(legacyAfter, after) == 2 * enormous + 1,
          "понад 256 біт після заснування: " + exponent:string);
    check(applyPatch02(legacyBefore, before) == expectedDayTag(before) &&
          applyPatch02(legacyAfter, after) == expectedDayTag(after),
          "двосторонній незалежний еталон: " + exponent:string);
  }

  const enormous = new bigint(1) << 600;
  const rawNegative = -enormous;
  const rawPositive = enormous;
  check(applyPatch02(oldDayTag(rawNegative), rawNegative) == expectedDayTag(rawNegative),
        "великий від'ємний абсолютний день");
  check(applyPatch02(oldDayTag(rawPositive), rawPositive) == expectedDayTag(rawPositive),
        "великий додатний абсолютний день");
}

proc testRouteAndIsolation() {
  const foundation = FOUNDATION_DAY;
  const bootstrap = makeBootstrapContext(foundation, foundation);
  check(bootstrap.status == MonsterStatus.bootstrapOnly &&
        bootstrap.branchTrace.size == 1,
        "Bootstrap ізольований");
  check(!bootstrap.metrics.contains("patch02.calls"),
        "Bootstrap не викликає Patch 02");

  const discovery01 = makeDiscovery01Context(foundation, foundation, M);
  check(discovery01.status == MonsterStatus.discoveryOnly &&
        discovery01.branchTrace.size == 2,
        "Discovery 01 ізольований");
  check(!discovery01.metrics.contains("patch02.calls"),
        "Discovery 01 не викликає Patch 02");

  const patch01 = makePatch01Context(foundation, foundation, M);
  check(patch01.status == MonsterStatus.patch01Only &&
        patch01.patch01CorrectedOutput == M,
        "Patch 01 збережено");
  check(!patch01.metrics.contains("patch02.calls") &&
        patch01.branchTrace.size == 3,
        "Patch 01 не викликає Patch 02");

  const discovery02 = makeDiscovery02Context(foundation, foundation, foundation);
  check(discovery02.status == MonsterStatus.discovery02Only &&
        discovery02.discovery02LegacyOutput == 0,
        "Discovery 02 зберігає дефект на F");
  check(!discovery02.metrics.contains("patch02.calls") &&
        discovery02.branchTrace.size == 4,
        "Discovery 02 не викликає Patch 02");

  for delta in -2..2 {
    const day = foundation + delta;
    const ctx = makePatch02Context(foundation, foundation, day);
    const caseDescription = "delta=" + delta:string;
    check(ctx.discovery02Input == day &&
          ctx.discovery02LegacyOutput == oldDayTag(day),
          "реальний старий виклик: " + caseDescription);
    check(ctx.patch02CorrectedOutput == expectedDayTag(day),
          "вихід Patch 02: " + caseDescription);
    check(ctx.status == MonsterStatus.patch02Only &&
          ctx.phase == MonsterPhase.stoppedAtPatch02Boundary,
          "зупинка на межі латки: " + caseDescription);
    check(ctx.discovery01LegacyOutput == regularMod(day, M) &&
          ctx.patch01CorrectedOutput == save(day),
          "попередній Patch 01 та Discovery 01: " + caseDescription);
    check(ctx.metrics.get("bootstrap.calls", 0) == 1 &&
          ctx.metrics.get("discovery01.calls", 0) == 1 &&
          ctx.metrics.get("patch01.calls", 0) == 1 &&
          ctx.metrics.get("discovery02.calls", 0) == 1 &&
          ctx.metrics.get("patch02.calls", 0) == 1,
          "по одному виклику на шар: " + caseDescription);
    check(ctx.branchTrace.size == 5 &&
          ctx.branchTrace[0] == "BOOTSTRAP_DISPATCH" &&
          ctx.branchTrace[1] == "DISCOVERY_01_OLD_REMAINDER" &&
          ctx.branchTrace[2] == "PATCH_01_LIFT_ZERO" &&
          ctx.branchTrace[3] == "DISCOVERY_02_OLD_DAY_TAG" &&
          ctx.branchTrace[4] == "PATCH_02_RESTORE_ODD_DAY_TAG",
          "незалежний слід п'яти етапів: " + caseDescription);
    check(!bootstrap.metrics.contains("patch02.calls") &&
          !discovery02.metrics.contains("patch02.calls"),
          "новий виклик не забруднює старі контексти: " + caseDescription);
  }

  const huge = new bigint(1) << 300;
  const hugeBefore = makePatch02Context(foundation, foundation, foundation - huge);
  const hugeAfter = makePatch02Context(foundation, foundation, foundation + huge);
  check(hugeBefore.patch02CorrectedOutput == 2 * huge &&
        hugeBefore.discovery02LegacyOutput == 2 * huge,
        "виробничий маршрут до F з 300-бітним зміщенням");
  check(hugeAfter.patch02CorrectedOutput == 2 * huge + 1 &&
        hugeAfter.discovery02LegacyOutput == 2 * huge,
        "виробничий маршрут після F з 300-бітним зміщенням");
}

proc main() {
  writeln("Початок перевірки латки 02 етапу 5.");
  testBoundaryAndHistoricalScar();
  testArbitraryPrecision();
  testRouteAndIsolation();
  writeln("Перевірок: ", checks, "; помилок: ", failures, ".");
  if failures != 0 then halt("Латка 02 етапу 5 має помилки.");
  writeln("STAGE_05_PATCH_02_RESULT=PASS");
}
