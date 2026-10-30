use BigInteger;
use ExactMath;
use LegacyRemainder;
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

proc testHistoricalRemainder() {
  check(oldRemainder(new bigint(1)) == 1,
        "старий залишок для одиниці збігається з SAVE");
  check(oldRemainder(M + 1) == 1,
        "старий залишок після M знову одиниця");
  check(oldRemainder(new bigint(-1)) == M - 1,
        "від'ємне число нормалізується до звичайної невід'ємної остачі");
  check(oldRemainder(new bigint(0)) == 0 && save(new bigint(0)) == M,
        "історичний дефект існує також на нулі");

  for k in 1..3 {
    const x = M * k;
    check(oldRemainder(x) == 0,
          "DISCOVERY 01: oldRemainder(" + k:string + "M)=0");
    check(save(x) == M,
          "нормативна SAVE(" + k:string + "M)=M");
    check(oldRemainder(x) != save(x),
          "відхилення на " + k:string + "M відтворено, але не виправлено");
  }
}

proc testDiscoveryRoute() {
  const bootstrap = makeBootstrapContext(FOUNDATION_DAY, FOUNDATION_DAY);
  check(bootstrap.status == MonsterStatus.bootstrapOnly &&
        bootstrap.phase == MonsterPhase.stoppedAtBootstrapBoundary,
        "маршрут етапу 1 не змінено");
  check(bootstrap.branchTrace.size == 1 &&
        !bootstrap.metrics.contains("discovery01.calls"),
        "етап 1 не запускає історичний маршрут");

  for k in 1..3 {
    const ctx = makeDiscovery01Context(FOUNDATION_DAY, FOUNDATION_DAY, M * k);
    check(ctx.discovery01LegacyOutput == 0 &&
          ctx.discovery01Input == M * k,
          "виробничий маршрут викликав стару остачу для " + k:string + "M");
    check(ctx.status == MonsterStatus.discoveryOnly &&
          ctx.phase == MonsterPhase.stoppedAtDiscovery01Boundary,
          "маршрут зупинився на межі Discovery 01");
    check(ctx.branchTrace.size == 2 &&
          ctx.branchTrace[0] == "BOOTSTRAP_DISPATCH" &&
          ctx.branchTrace[1] == "DISCOVERY_01_OLD_REMAINDER",
          "слід містить історичний виклик без майбутнього патча");
    check(ctx.metrics.get("bootstrap.calls", 0) == 1 &&
          ctx.metrics.get("discovery01.calls", 0) == 1,
          "метрики лише фіксують по одному виклику");
  }
}

proc main() {
  writeln("Початок перевірки історичного відкриття 01.");
  testHistoricalRemainder();
  testDiscoveryRoute();
  writeln("Перевірок: ", checks, "; помилок: ", failures, ".");
  if failures != 0 then halt("Discovery 01 має помилки.");
  writeln("STAGE_02_DISCOVERY_01_RESULT=PASS");
}
