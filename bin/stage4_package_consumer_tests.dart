import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

var checks = 0;

void check(bool condition, String description) {
  checks++;
  if (!condition) {
    throw StateError('STAGE4_PACKAGE_CONSUMER_FAILED: $description');
  }
}

void rejectRangeError(void Function() body, String description) {
  var rejected = false;
  try {
    body();
  } on RangeError {
    rejected = true;
  }
  check(rejected, description);
}

void main() {
  final foundation = BigInt.from(-15055671);
  const vectors = <List<int>>[
    <int>[-1, 10, 502, 32, 21],
    <int>[0, 10, 503, 20, 56],
    <int>[1, 14, 1, 29, 38],
  ];
  check(vectors.length == 3, 'Three normative AC.1 anchors');

  final calendar = MonsterFiveFieldCalendar();
  final clock = Stopwatch()..start();
  for (final vector in vectors) {
    final delta = vector[0];
    final cutlet = vector[1];
    final cutletDay = vector[2];
    final month = vector[3];
    final monthDay = vector[4];
    final MonsterFiveFieldDate date = calendar.calculate(
      foundation,
      foundation + BigInt.from(delta),
      maxTransitions: 0,
    );

    check(date.yearNumber == BigInt.from(5000), 'AC.1 year');
    check(date.cutletCanonicalIndex == cutlet, 'AC.1 cutlet index');
    check(date.dayInCutlet == cutletDay, 'AC.1 cutlet day');
    check(date.monthCanonicalIndex == month, 'AC.1 month index');
    check(date.dayInMonth == monthDay, 'AC.1 month day');
    check(
      date.cutletName == SourceLanguageCatalog.cutletText(cutlet),
      'Public Hebrew cutlet name',
    );
    check(
      date.monthName == SourceLanguageCatalog.monthText(month),
      'Public Hebrew month name',
    );

    final tuple = date.canonicalComponents;
    final expected = <Object>[
      BigInt.from(5000),
      cutlet,
      cutletDay,
      month,
      monthDay,
    ];
    check(tuple.length == 5, 'Exactly five public components');
    for (var i = 0; i < expected.length; i++) {
      check(tuple[i] == expected[i], 'Tuple value ' + i.toString());
      check(
        tuple[i].runtimeType == expected[i].runtimeType,
        'Tuple type ' + i.toString(),
      );
    }

    var immutable = false;
    try {
      tuple.add(BigInt.zero);
    } on UnsupportedError {
      immutable = true;
    }
    check(immutable, 'Public tuple is immutable');
  }
  clock.stop();

  rejectRangeError(
    () {
      calendar.calculate(foundation, foundation, maxTransitions: -1);
    },
    'Negative transition limit rejected',
  );
  rejectRangeError(
    () {
      calendar.calculate(foundation, foundation, maxTransitions: 65);
    },
    'Transition limit above 64 rejected',
  );

  check(clock.elapsedMilliseconds <= 120000, 'Three public calls <=120s');
  check(checks >= 60, 'At least sixty package-consumer checks');

  print(
    'STAGE4_PACKAGE_CONSUMER_TIME_MS=' + clock.elapsedMilliseconds.toString(),
  );
  print(
    'STAGE4_PACKAGE_CONSUMER_PASS; checks=' +
        checks.toString() +
        '; canonical_anchors=3; package_uri=true; zero_transition=true; ' +
        'immutable_tuple=true',
  );
}
