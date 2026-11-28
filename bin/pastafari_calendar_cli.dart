import 'dart:convert';
import 'dart:io';

import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

const List<String> _usage = <String>[
  'forward --calculation-date=YYYY-MM-DD --requested-date=YYYY-MM-DD [--max-transitions=0..64]',
  'inverse --calculation-date=YYYY-MM-DD --year-number=N --cutlet-index=N --day-in-cutlet=N --month-index=N --day-in-month=N [--max-transitions=0..64]',
  'Gregorian years may be signed; dates use the proleptic Gregorian calendar.',
];

Map<String, Object?> runCalendarCli(List<String> args) {
  if (args.isEmpty ||
      (args.length == 1 &&
          (args.single == '--help' || args.single == 'help'))) {
    return <String, Object?>{'usage': _usage};
  }
  final command = args.first;
  if (command != 'forward' && command != 'inverse') {
    throw FormatException('Command must be forward or inverse.');
  }
  final options = _parseOptions(args.skip(1));
  final allowed = command == 'forward'
      ? const <String>{'calculation-date', 'requested-date', 'max-transitions'}
      : const <String>{
          'calculation-date',
          'year-number',
          'cutlet-index',
          'day-in-cutlet',
          'month-index',
          'day-in-month',
          'max-transitions',
        };
  for (final key in options.keys) {
    if (!allowed.contains(key)) {
      throw FormatException('Unknown option --' + key + '.');
    }
  }

  final calculationDate =
      _parseCivilDate(_required(options, 'calculation-date'));
  final maxTransitions = int.parse(options['max-transitions'] ?? '64');
  final converter = PastafariGregorianConverter();
  if (command == 'forward') {
    final requestedDate = _parseCivilDate(_required(options, 'requested-date'));
    final date = converter.calculate(
      calculationDate,
      requestedDate,
      maxTransitions: maxTransitions,
    );
    return <String, Object?>{
      'operation': 'forward',
      'calculation_date': _civilJson(calculationDate),
      'requested_date': _civilJson(requestedDate),
      'requested_serial_day': requestedDate.toSerialDay().toString(),
      'pastafarian_date': _pastafarianJson(date),
      'max_transitions': maxTransitions,
    };
  }

  final date = MonsterFiveFieldDate.fromComponents(
    yearNumber: BigInt.parse(_required(options, 'year-number')),
    cutletCanonicalIndex: int.parse(_required(options, 'cutlet-index')),
    dayInCutlet: int.parse(_required(options, 'day-in-cutlet')),
    monthCanonicalIndex: int.parse(_required(options, 'month-index')),
    dayInMonth: int.parse(_required(options, 'day-in-month')),
  );
  final requestedDate = converter.toGregorian(
    calculationDate,
    date,
    maxTransitions: maxTransitions,
  );
  return <String, Object?>{
    'operation': 'inverse',
    'calculation_date': _civilJson(calculationDate),
    'pastafarian_date': _pastafarianJson(date),
    'serial_day': requestedDate.toSerialDay().toString(),
    'gregorian_date': _civilJson(requestedDate),
    'max_transitions': maxTransitions,
  };
}

Map<String, String> _parseOptions(Iterable<String> arguments) {
  final options = <String, String>{};
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (!argument.startsWith('--') ||
        separator <= 2 ||
        separator == argument.length - 1) {
      throw FormatException('Options must use --name=value syntax.');
    }
    final key = argument.substring(2, separator);
    final value = argument.substring(separator + 1);
    if (options.containsKey(key)) {
      throw FormatException('Duplicate option --' + key + '.');
    }
    options[key] = value;
  }
  return options;
}

String _required(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw FormatException('Missing required option --' + key + '.');
  }
  return value;
}

GregorianCivilDate _parseCivilDate(String value) {
  final match = RegExp(r'^([+-]?\d+)-(\d{1,2})-(\d{1,2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Date must use signed-year YYYY-MM-DD syntax.');
  }
  return GregorianCivilDate(
    BigInt.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

Map<String, Object?> _civilJson(GregorianCivilDate date) => <String, Object?>{
      'year': date.year.toString(),
      'month': date.month,
      'day': date.day,
    };

Map<String, Object?> _pastafarianJson(MonsterFiveFieldDate date) =>
    <String, Object?>{
      'year_number': date.yearNumber.toString(),
      'cutlet': <String, Object?>{
        'canonical_index': date.cutletCanonicalIndex,
        'name': date.cutletName,
        'day': date.dayInCutlet,
      },
      'month': <String, Object?>{
        'canonical_index': date.monthCanonicalIndex,
        'name': date.monthName,
        'day': date.dayInMonth,
      },
      'canonical_components': date.canonicalComponents
          .map<Object>(
            (value) => value is BigInt ? value.toString() : value,
          )
          .toList(growable: false),
    };

void main(List<String> args) {
  try {
    stdout.writeln(jsonEncode(runCalendarCli(args)));
  } on FormatException catch (error) {
    _writeError('usage', error.message, 2);
  } on IncompleteMonsterYearTraversal catch (error) {
    _writeError('incomplete_year_traversal', error.toString(), 3);
  } on IncompleteMonsterYearNumberTraversal catch (error) {
    _writeError('incomplete_year_number_traversal', error.toString(), 3);
  } on ArgumentError catch (error) {
    _writeError('invalid_date_or_components', error.toString(), 2);
  } catch (error) {
    _writeError('runtime_error', error.toString(), 1);
  }
}

void _writeError(String code, String message, int status) {
  stderr.writeln(jsonEncode(<String, Object?>{
    'error': code,
    'message': message,
  }));
  exitCode = status;
}
