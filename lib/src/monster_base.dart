final class MonsterContext {
  final BigInt calculationDay;
  final BigInt targetDay;
  String phase;
  String status;
  final List<String> branchTrace;
  final Map<String, BigInt> metrics;
  final List<String> logs;
  final List<String> diagnostics;

  MonsterContext({required this.calculationDay, required this.targetDay})
      : phase = 'BOOTSTRAP',
        status = 'NEW',
        branchTrace = <String>[],
        metrics = <String, BigInt>{},
        logs = <String>[],
        diagnostics = <String>[];
}

final class MonsterValidationError implements Exception {
  final String message;
  const MonsterValidationError(this.message);

  @override
  String toString() => 'שגיאת אימות: $message';
}

final class MonsterValidationManager {
  const MonsterValidationManager();

  void requireIntegerDay(BigInt day) {
    if (day.toString().isEmpty) {
      throw const MonsterValidationError('יום בדיד חייב להיות מספר שלם מדויק.');
    }
  }
}

final class MonsterMetricsManager {
  const MonsterMetricsManager();

  void bump(MonsterContext context, String key) {
    context.metrics[key] = (context.metrics[key] ?? BigInt.zero) + BigInt.one;
  }
}

final class MonsterDispatcher {
  const MonsterDispatcher();

  Never dispatchUnbuiltStage(MonsterContext context) {
    context.branchTrace.add('STAGE_NOT_BUILT');
    throw StateError('המסלול הספגטי טרם נבנה בשלב האתחול.');
  }
}

final class MonsterManager {
  final MonsterDispatcher dispatcher;
  final MonsterValidationManager validationManager;
  final MonsterMetricsManager metricsManager;

  const MonsterManager({
    this.dispatcher = const MonsterDispatcher(),
    this.validationManager = const MonsterValidationManager(),
    this.metricsManager = const MonsterMetricsManager(),
  });

  Never executeUnbuilt(MonsterContext context) {
    validationManager.requireIntegerDay(context.calculationDay);
    validationManager.requireIntegerDay(context.targetDay);
    metricsManager.bump(context, 'bootstrap.calls');
    return dispatcher.dispatchUnbuiltStage(context);
  }
}

Never calendarDateSpaghetti(BigInt calculationDay, BigInt targetDay) {
  final context = MonsterContext(
    calculationDay: calculationDay,
    targetDay: targetDay,
  );
  return const MonsterManager().executeUnbuilt(context);
}
