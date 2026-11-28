import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';

var checks = 0;

void require(bool condition, String label) {
  checks++;
  if (!condition) {
    throw StateError(label);
  }
}

void checkDate(BigInt year, int month, int day, BigInt serial) {
  final date = GregorianCivilDate(year, month, day);
  require(date.toSerialDay() == serial, 'Forward serial: $year/$month/$day');
  final result = GregorianCivilDate.fromSerialDay(serial);
  require(
    result.year == year && result.month == month && result.day == day,
    'Inverse serial: $serial',
  );
}

void reject(int year, int month, int day) {
  try {
    GregorianCivilDate(BigInt.from(year), month, day);
  } on RangeError {
    checks++;
    return;
  }
  throw StateError('Invalid civil date accepted: $year/$month/$day');
}

void main() {
  checkDate(BigInt.one, 1, 1, BigInt.one);
  checkDate(BigInt.zero, 12, 31, BigInt.zero);
  checkDate(BigInt.from(-41221), 12, 22, BigInt.from(-15055671));
  checkDate(BigInt.from(-762), 6, 7, BigInt.from(-278522));
  checkDate(BigInt.from(1970), 1, 1, BigInt.from(719163));
  checkDate(BigInt.from(2000), 2, 29, BigInt.from(730179));

  // Independent civil-day oracle: SDK UTC calendar, not production formula.
  final epoch = DateTime.utc(1, 1, 1);
  final first = DateTime.utc(1600, 1, 1);
  for (var i = 0; i < 146097; i++) {
    final utc = first.add(Duration(days: i));
    final serial = BigInt.from(utc.difference(epoch).inDays + 1);
    final year = BigInt.from(utc.year);
    final date = GregorianCivilDate(year, utc.month, utc.day);
    require(date.toSerialDay() == serial, 'UTC oracle: $utc');
    if (i % 31 == 0 || utc.day == 1) {
      checkDate(year, utc.month, utc.day, serial);
    }
  }

  // Arbitrary-size negative/positive years: a 400-year period is exact.
  final cycle = BigInt.parse('1000000000000000000000000000000');
  for (final sign in <int>[-1, 1]) {
    final offset = cycle * BigInt.from(sign);
    final year = BigInt.from(2000) + offset * BigInt.from(400);
    final serial = BigInt.from(730179) + offset * BigInt.from(146097);
    checkDate(year, 2, 29, serial);
  }

  reject(1900, 2, 29);
  reject(2100, 2, 29);
  reject(2000, 0, 1);
  reject(2000, 13, 1);
  reject(2000, 4, 31);
  reject(2000, 1, 0);

  final foundation = GregorianCivilDate(BigInt.from(-41221), 12, 22);
  final actual = PastafariGregorianConverter().calculate(
    foundation,
    foundation,
    maxTransitions: 0,
  );
  final expected = <Object>[BigInt.from(5000), 10, 503, 20, 56];
  for (var i = 0; i < expected.length; i++) {
    require(actual.canonicalComponents[i] == expected[i], 'AC.1 item $i');
  }
  print('PRODUCTION_GREGORIAN_BOUNDARY_PASS checks=$checks');
}
