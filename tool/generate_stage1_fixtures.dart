import 'dart:convert';
import 'dart:io';

import '../test_support/normative_reference.dart';
import '../lib/src/source_language_catalog.dart';

void main() {
  final f = NormativeReference.foundationDay;
  final m = NormativeReference.m;
  final same = NormativeReference.workCounts(f, f);
  final forward = NormativeReference.workCounts(f, f + BigInt.one);
  final backward = NormativeReference.workCounts(f + BigInt.one, f);
  final stone2 = NormativeReference.stones[1];

  final data = <String, Object>{
    'm': m.toString(),
    'tabletsMinusFoundation':
        (NormativeReference.tabletsDay - NormativeReference.foundationDay).toString(),
    'dayCount': <String, String>{
      'foundationMinusOne': NormativeReference.dayCount(f - BigInt.one).toString(),
      'foundation': NormativeReference.dayCount(f).toString(),
      'foundationPlusOne': NormativeReference.dayCount(f + BigInt.one).toString(),
    },
    'save': <String, String>{
      'zero': NormativeReference.save(BigInt.zero).toString(),
      'one': NormativeReference.save(BigInt.one).toString(),
      'mMinusOne': NormativeReference.save(m - BigInt.one).toString(),
      'm': NormativeReference.save(m).toString(),
      'mPlusOne': NormativeReference.save(m + BigInt.one).toString(),
      'twoM': NormativeReference.save(BigInt.from(2) * m).toString(),
    },
    'workCounts': <String, List<String>>{
      'sameFoundation': <String>[
        same.action.toString(),
        same.target.toString(),
        same.distance.toString(),
        same.connection.toString(),
        same.direction.toString(),
      ],
      'forwardOne': <String>[
        forward.action.toString(),
        forward.target.toString(),
        forward.distance.toString(),
        forward.connection.toString(),
        forward.direction.toString(),
      ],
      'backwardOne': <String>[
        backward.action.toString(),
        backward.target.toString(),
        backward.distance.toString(),
        backward.connection.toString(),
        backward.direction.toString(),
      ],
    },
    'stone2': <String>[
      stone2.wheat.toString(),
      stone2.barley.toString(),
      stone2.salt.toString(),
      stone2.bitter.toString(),
      stone2.red.toString(),
    ],
    'permutation1': NormativeReference.permutationUnrank1(
      BigInt.one,
      const <int>[1, 2, 3, 4, 5, 6],
    ),
    'permutation720': NormativeReference.permutationUnrank1(
      BigInt.from(720),
      const <int>[1, 2, 3, 4, 5, 6],
    ),
    'cutletCount': SourceLanguageCatalog.cutletNames.length,
    'monthCount': SourceLanguageCatalog.monthNames.length,
  };

  final encoder = const JsonEncoder.withIndent('  ');
  File('fixtures/stage1_expected.json').writeAsStringSync('${encoder.convert(data)}\n');
  stdout.writeln('נוצר קובץ fixtures של שלב 1 מתוך ה־oracle המקומי בלבד.');
}
