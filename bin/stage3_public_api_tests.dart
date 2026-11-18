import '../lib/pastafari_calendar.dart';

var checks = 0;

void check(bool condition, String description) {
  checks++;
  if (!condition) {
    throw StateError('STAGE3_PUBLIC_API_FAILED: $description');
  }
}

void main() {
  final foundation = BigInt.from(-15055671);
  final clock = Stopwatch()..start();
  final calendar = MonsterFiveFieldCalendar();
  final date = calendar.calculate(foundation, foundation);
  clock.stop();

  check(date.yearNumber == BigInt.from(5000), 'Normative year');
  check(date.cutletCanonicalIndex == 10, 'Normative cutlet index');
  check(date.dayInCutlet == 503, 'Normative cutlet ordinal');
  check(date.monthCanonicalIndex == 20, 'Normative month index');
  check(date.dayInMonth == 56, 'Normative month ordinal');
  check(date.cutletName == SourceLanguageCatalog.cutletText(10),
      'Hebrew canonical cutlet name');
  check(date.monthName == SourceLanguageCatalog.monthText(20),
      'Hebrew canonical month name');

  final tuple = date.canonicalComponents;
  check(tuple.length == 5, 'Exactly five public numeric components');
  check(tuple[0] == BigInt.from(5000), 'Public tuple year');
  check(tuple[1] == 10, 'Public tuple cutlet index');
  check(tuple[2] == 503, 'Public tuple cutlet day');
  check(tuple[3] == 20, 'Public tuple month index');
  check(tuple[4] == 56, 'Public tuple month day');

  var immutable = false;
  try {
    tuple.add(BigInt.zero);
  } on UnsupportedError {
    immutable = true;
  }
  check(immutable, 'Public tuple is immutable');
  check(clock.elapsedMilliseconds <= 120000, 'Public call time budget');
  check(checks >= 15, 'At least fifteen public API assertions');

  print('STAGE3_PUBLIC_API_CANONICAL_TIME_MS=${clock.elapsedMilliseconds}');
  print('STAGE3_PUBLIC_API_PASS; checks=$checks; '
      'canonical_anchors=1; public_calendar_ready=true');
}
