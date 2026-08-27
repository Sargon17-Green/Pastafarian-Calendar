import 'dart:convert';
import 'dart:io';

import '../lib/src/monster_base.dart';
import '../test_support/normative_reference.dart';
import '../lib/src/source_language_catalog.dart';

Never _fail(String message) {
  stderr.writeln('כשל: $message');
  exit(1);
}

void _expectEqual(Object? actual, Object? expected, String name) {
  if (actual != expected) {
    _fail('$name — התקבל $actual במקום $expected');
  }
}

void _expectListEqual(List<Object?> actual, List<Object?> expected, String name) {
  if (actual.length != expected.length) {
    _fail('$name — אורך הרשימה שונה.');
  }
  for (var i = 0; i < actual.length; i++) {
    if (actual[i] != expected[i]) {
      _fail('$name — הבדל במקום ${i + 1}: ${actual[i]} במקום ${expected[i]}');
    }
  }
}

List<String> _countsAsStrings(WorkCounts counts) => <String>[
      counts.action.toString(),
      counts.target.toString(),
      counts.distance.toString(),
      counts.connection.toString(),
      counts.direction.toString(),
    ];

void main() {
  final raw = File('fixtures/stage1_expected.json').readAsStringSync();
  final fixture = jsonDecode(raw) as Map<String, dynamic>;
  final f = NormativeReference.foundationDay;
  final m = NormativeReference.m;

  _expectEqual(m.toString(), fixture['m'], 'המניין הגדול');
  _expectEqual(
    (NormativeReference.tabletsDay - f).toString(),
    fixture['tabletsMinusFoundation'],
    'מרחק לוחות־יסוד',
  );

  final dayCount = fixture['dayCount'] as Map<String, dynamic>;
  _expectEqual(
    NormativeReference.dayCount(f - BigInt.one).toString(),
    dayCount['foundationMinusOne'],
    'מניין יום לפני היסוד',
  );
  _expectEqual(
    NormativeReference.dayCount(f).toString(),
    dayCount['foundation'],
    'מניין יום היסוד',
  );
  _expectEqual(
    NormativeReference.dayCount(f + BigInt.one).toString(),
    dayCount['foundationPlusOne'],
    'מניין יום אחרי היסוד',
  );

  final save = fixture['save'] as Map<String, dynamic>;
  _expectEqual(NormativeReference.save(BigInt.zero).toString(), save['zero'], 'SAVE של אפס');
  _expectEqual(NormativeReference.save(BigInt.one).toString(), save['one'], 'SAVE של אחד');
  _expectEqual(NormativeReference.save(m - BigInt.one).toString(), save['mMinusOne'], 'SAVE של M פחות אחד');
  _expectEqual(NormativeReference.save(m).toString(), save['m'], 'SAVE של M');
  _expectEqual(NormativeReference.save(m + BigInt.one).toString(), save['mPlusOne'], 'SAVE של M ועוד אחד');
  _expectEqual(NormativeReference.save(BigInt.from(2) * m).toString(), save['twoM'], 'SAVE של פעמיים M');

  final work = fixture['workCounts'] as Map<String, dynamic>;
  _expectListEqual(
    _countsAsStrings(NormativeReference.workCounts(f, f)),
    (work['sameFoundation'] as List<dynamic>).cast<String>(),
    'מניינים ביום היסוד מול עצמו',
  );
  _expectListEqual(
    _countsAsStrings(NormativeReference.workCounts(f, f + BigInt.one)),
    (work['forwardOne'] as List<dynamic>).cast<String>(),
    'מניינים יום אחד קדימה',
  );
  _expectListEqual(
    _countsAsStrings(NormativeReference.workCounts(f + BigInt.one, f)),
    (work['backwardOne'] as List<dynamic>).cast<String>(),
    'מניינים יום אחד אחורה',
  );

  final stone2 = NormativeReference.stones[1];
  _expectListEqual(
    <Object?>[
      stone2.wheat.toString(),
      stone2.barley.toString(),
      stone2.salt.toString(),
      stone2.bitter.toString(),
      stone2.red.toString(),
    ],
    (fixture['stone2'] as List<dynamic>).cast<String>(),
    'האבן השנייה',
  );

  _expectListEqual(
    NormativeReference.permutationUnrank1(
      BigInt.one,
      const <int>[1, 2, 3, 4, 5, 6],
    ).cast<Object?>(),
    (fixture['permutation1'] as List<dynamic>).cast<Object?>(),
    'תמורה בדרגה 1',
  );
  _expectListEqual(
    NormativeReference.permutationUnrank1(
      BigInt.from(720),
      const <int>[1, 2, 3, 4, 5, 6],
    ).cast<Object?>(),
    (fixture['permutation720'] as List<dynamic>).cast<Object?>(),
    'תמורה בדרגה 720',
  );

  _expectEqual(SourceLanguageCatalog.cutletNames.length, fixture['cutletCount'], 'מספר שמות הקציצות');
  _expectEqual(SourceLanguageCatalog.monthNames.length, fixture['monthCount'], 'מספר שמות החודשים');

  for (var i = 0; i < SourceLanguageCatalog.cutletNames.length; i++) {
    _expectEqual(SourceLanguageCatalog.cutletNames[i].canonicalIndex, i + 1, 'אינדקס קציצה ${i + 1}');
  }
  for (var i = 0; i < SourceLanguageCatalog.monthNames.length; i++) {
    _expectEqual(SourceLanguageCatalog.monthNames[i].canonicalIndex, i + 1, 'אינדקס חודש ${i + 1}');
  }

  _expectEqual(
    NormativeReference.chooseRankShort(
      AnswerStream(m, 1),
      BigInt.from(2),
    ),
    BigInt.one,
    'דחיית bias קצרה קדימה',
  );
  _expectEqual(
    NormativeReference.chooseRankShort(
      AnswerStream(m, -1),
      BigInt.from(2),
    ),
    BigInt.from(2),
    'דחיית bias קצרה אחורה',
  );
  _expectEqual(
    NormativeReference.chooseRankWide(
      AnswerStream(BigInt.one, 1),
      m + BigInt.one,
    ),
    m + BigInt.one,
    'בחירה רחבה ראשונית',
  );

  final firstContext = MonsterContext(calculationDay: f, targetDay: f);
  final secondContext = MonsterContext(calculationDay: f, targetDay: f);
  firstContext.metrics['בדיקה'] = BigInt.one;
  if (secondContext.metrics.containsKey('בדיקה')) {
    _fail('MonsterContext דלף בין הפעלות.');
  }

  var productionRejected = false;
  try {
    calendarDateSpaghetti(f, f);
  } on StateError {
    productionRejected = true;
  }
  if (!productionRejected) {
    _fail('שלד production של שלב 1 לא עצר לפני מסלול עתידי.');
  }

  stdout.writeln('כל בדיקות שלב 1 עברו.');
}
