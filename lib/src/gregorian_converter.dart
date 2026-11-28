import 'monster_five_field_calendar.dart';
import 'monster_year_traversal.dart';

/// תאריך גרגוריאני פרולפטי, במספור שנים אסטרונומי (0 = 1 לפנה"ס).
/// ללא אזור זמן, ללא DateTime וללא תלות חיצונית.
final class GregorianCivilDate {
  final BigInt year;
  final int month;
  final int day;

  GregorianCivilDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    final limit = _monthLength(year, month);
    if (day < 1 || day > limit) {
      throw RangeError.range(day, 1, limit, 'day');
    }
  }

  static final _four = BigInt.from(4);
  static final _hundred = BigInt.from(100);
  static final _fourHundred = BigInt.from(400);
  static final _cycleDays = BigInt.from(146097);
  static const _monthLengths = <int>[
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];

  static BigInt _floorDiv(BigInt n, BigInt d) => (n - n % d) ~/ d;

  static bool isLeapYear(BigInt year) =>
      year % _four == BigInt.zero &&
      (year % _hundred != BigInt.zero || year % _fourHundred == BigInt.zero);

  static int _monthLength(BigInt year, int month) =>
      _monthLengths[month - 1] + (month == 2 && isLeapYear(year) ? 1 : 0);

  static BigInt _daysBeforeYear(BigInt year) {
    final n = year - BigInt.one;
    return n * BigInt.from(365) +
        _floorDiv(n, _four) -
        _floorDiv(n, _hundred) +
        _floorDiv(n, _fourHundred);
  }

  /// סעיף B: 1 בינואר שנה 1 הוא יום 1.
  BigInt toSerialDay() {
    var offset = day;
    for (var m = 1; m < month; m++) {
      offset += _monthLength(year, m);
    }
    return _daysBeforeYear(year) + BigInt.from(offset);
  }

  factory GregorianCivilDate.fromSerialDay(BigInt serialDay) {
    final cycle = _floorDiv(serialDay - BigInt.one, _cycleDays);
    final firstYear = cycle * _fourHundred + BigInt.one;
    var lo = 0;
    var hi = 400;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (_daysBeforeYear(firstYear + BigInt.from(mid)) < serialDay) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final year = firstYear + BigInt.from(lo);
    var remaining = (serialDay - _daysBeforeYear(year)).toInt();
    var month = 1;
    while (remaining > _monthLength(year, month)) {
      remaining -= _monthLength(year, month);
      month++;
    }
    return GregorianCivilDate(year, month, remaining);
  }
}

/// ממשק תאריכים אזרחיים למנוע הקיים, ללא שינוי בסמנטיקה או בתקציבו.
final class PastafariGregorianConverter {
  final MonsterFiveFieldCalendar _calendar;

  PastafariGregorianConverter() : _calendar = MonsterFiveFieldCalendar();

  MonsterFiveFieldDate calculate(
    GregorianCivilDate calculationDate,
    GregorianCivilDate requestedDate, {
    int maxTransitions = MonsterYearTraversal.maximumTransitions,
  }) =>
      _calendar.calculate(
        calculationDate.toSerialDay(),
        requestedDate.toSerialDay(),
        maxTransitions: maxTransitions,
      );

  /// Invert a Pastafarian date while keeping calculationDate fixed.
  BigInt toSerialDay(
    GregorianCivilDate calculationDate,
    MonsterFiveFieldDate date, {
    int maxTransitions = MonsterYearTraversal.maximumTransitions,
  }) =>
      _calendar.toSerialDay(
        calculationDate.toSerialDay(),
        date,
        maxTransitions: maxTransitions,
      );

  /// Invert a Pastafarian date to its proleptic Gregorian civil date.
  GregorianCivilDate toGregorian(
    GregorianCivilDate calculationDate,
    MonsterFiveFieldDate date, {
    int maxTransitions = MonsterYearTraversal.maximumTransitions,
  }) =>
      GregorianCivilDate.fromSerialDay(
        toSerialDay(
          calculationDate,
          date,
          maxTransitions: maxTransitions,
        ),
      );
}
