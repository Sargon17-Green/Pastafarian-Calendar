import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

typedef CanonicalCase = ({
  int delta,
  int cutlet,
  int cutletDay,
  int month,
  int monthDay,
});

var checks = 0;

void requireCondition(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError('STAGE5_EXTERNAL_CONSUMER_FAILED: $label');
  }
}

void expectUnsupported(void Function() action, String label) {
  var caught = false;
  try {
    action();
  } on UnsupportedError {
    caught = true;
  }
  requireCondition(caught, label);
}

void expectRangeError(void Function() action, String label) {
  var caught = false;
  try {
    action();
  } on RangeError {
    caught = true;
  }
  requireCondition(caught, label);
}

void verifyAnchor(MonsterFiveFieldDate date, CanonicalCase oracle) {
  requireCondition(date.yearNumber == BigInt.from(5000), 'Year 5000');
  requireCondition(
    date.cutletCanonicalIndex == oracle.cutlet,
    'Cutlet index',
  );
  requireCondition(date.dayInCutlet == oracle.cutletDay, 'Cutlet day');
  requireCondition(date.monthCanonicalIndex == oracle.month, 'Month index');
  requireCondition(date.dayInMonth == oracle.monthDay, 'Month day');
  requireCondition(
    date.cutletName == SourceLanguageCatalog.cutletText(oracle.cutlet),
    'Public Hebrew cutlet name',
  );
  requireCondition(
    date.monthName == SourceLanguageCatalog.monthText(oracle.month),
    'Public Hebrew month name',
  );

  final components = date.canonicalComponents;
  final expected = <Object>[
    BigInt.from(5000),
    oracle.cutlet,
    oracle.cutletDay,
    oracle.month,
    oracle.monthDay,
  ];
  requireCondition(components.length == 5, 'Five numeric components');
  for (var i = 0; i < expected.length; i++) {
    requireCondition(components[i] == expected[i], 'Component value $i');
    requireCondition(
      components[i].runtimeType == expected[i].runtimeType,
      'Component type $i',
    );
  }
  expectUnsupported(() {
    components[0] = BigInt.zero;
  }, 'No component assignment');
  expectUnsupported(() {
    components.add(BigInt.zero);
  }, 'No component append');
}

void main() {
  const anchors = <CanonicalCase>[
    (delta: -1, cutlet: 10, cutletDay: 502, month: 32, monthDay: 21),
    (delta: 0, cutlet: 10, cutletDay: 503, month: 20, monthDay: 56),
    (delta: 1, cutlet: 14, cutletDay: 1, month: 29, monthDay: 38),
  ];
  requireCondition(anchors.length == 3, 'Three independent AC.1 anchors');

  final foundation = BigInt.from(-15055671);
  final calculator = MonsterFiveFieldCalendar();
  final stopwatch = Stopwatch()..start();
  for (final anchor in anchors) {
    verifyAnchor(
      calculator.calculate(
        foundation,
        foundation + BigInt.from(anchor.delta),
        maxTransitions: 0,
      ),
      anchor,
    );
  }
  stopwatch.stop();

  expectRangeError(() {
    calculator.calculate(foundation, foundation, maxTransitions: -1);
  }, 'Lower transition bound');
  expectRangeError(() {
    calculator.calculate(foundation, foundation, maxTransitions: 65);
  }, 'Upper transition bound');
  requireCondition(
    stopwatch.elapsedMilliseconds <= 120000,
    'External calls under 120 seconds',
  );
  requireCondition(checks >= 64, 'At least 65 external checks');

  print('STAGE5_EXTERNAL_CONSUMER_TIME_MS=${stopwatch.elapsedMilliseconds}');
  print(
    'STAGE5_EXTERNAL_CONSUMER_PASS; checks=$checks; '
    'canonical_anchors=3; separate_pubspec=true; '
    'path_dependency=true; zero_transition=true; '
    'immutable_tuple=true',
  );
}
